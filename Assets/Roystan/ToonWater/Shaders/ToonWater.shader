//https://roystan.net/articles/toon-water.html
Shader "RoadOfShader/roystan/Toon Water"
{
    Properties
    {
        _DepthGradientShallow ("Depth Gradient Shallow", Color) = (0.325, 0.807, 0.971, 0.725)
        _DepthGradientDeep ("Depth Gradient Deep", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance ("Depth Maximum Distance", Float) = 1

        _SurfaceNoise ("Surface Noise", 2D) = "white" { }
        _SurfaceNoiseCutoff ("Surface Noise Cutoff", Range(0, 1)) = 0.777
        _FoamDistance ("Foam Distance", Float) = 0.4
        _SurfaceNoiseScroll ("Surface Noise Scroll Amount", Vector) = (0.03, 0.03, 0, 0)
        _SurfaceDistortion ("Surface Distortion", 2D) = "white" { }
        _SurfaceDistortionAmount ("Surface Distortion Amount", Range(0, 1)) = 0.27
        _FoamColor ("Foam Color", Color) = (1, 1, 1, 1)
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            
            HLSLPROGRAM

            #define SMOOTHSTEP_AA 0.01
            
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float2 noiseUV: TEXCOORD0;
                float2 distortUV: TEXCOORD1;
                float4 screenPosition: TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _DepthGradientShallow;
            float4 _DepthGradientDeep;
            float _DepthMaxDistance;
            float4 _SurfaceNoise_ST;
            float _SurfaceNoiseCutoff;
            float _FoamDistance;
            float4 _SurfaceNoiseScroll;
            float _SurfaceDistortionAmount;
            float4 _SurfaceDistortion_ST;
            float4 _FoamColor;
            CBUFFER_END

            TEXTURE2D(_SurfaceNoise); SAMPLER(sampler_SurfaceNoise);
            TEXTURE2D(_SurfaceDistortion); SAMPLER(sampler_SurfaceDistortion);

            float4 alphaBlend(float4 top, float4 bottom)
            {
                float3 color = (top.rgb * top.a) + (bottom.rgb * (1 - top.a));
                float alpha = top.a + bottom.a * (1 - top.a);

                return float4(color, alpha);
            }

            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.noiseUV = TRANSFORM_TEX(input.uv, _SurfaceNoise);
                output.distortUV = TRANSFORM_TEX(input.uv, _SurfaceDistortion);

                output.screenPosition = ComputeScreenPos(output.positionCS);
                
                return output;
            }

            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float existingDepth01 = SampleSceneDepth(input.screenPosition.xy / input.screenPosition.w);
                float existingDepthLinear = LinearEyeDepth(existingDepth01, _ZBufferParams);

                float depthDifference = existingDepthLinear - input.screenPosition.w;

                float waterDepthDifference01 = saturate(depthDifference / _DepthMaxDistance);
                float4 waterColor = lerp(_DepthGradientShallow, _DepthGradientDeep, waterDepthDifference01);

                float2 distortSample = (SAMPLE_TEXTURE2D(_SurfaceDistortion, sampler_SurfaceDistortion, input.distortUV).xy * 2 - 1) * _SurfaceDistortionAmount;

                float2 noiseUV = input.noiseUV + _SurfaceNoiseScroll.xy * _Time.y + distortSample;
                float surfaceNoiseSample = SAMPLE_TEXTURE2D(_SurfaceNoise, sampler_SurfaceNoise, noiseUV).r;
                float foamDepthDifference01 = saturate(depthDifference / _FoamDistance);
                float surfaceNoiseCutoff = foamDepthDifference01 * _SurfaceNoiseCutoff;

                float surfaceNoise = smoothstep(surfaceNoiseCutoff - SMOOTHSTEP_AA, surfaceNoiseCutoff + SMOOTHSTEP_AA, surfaceNoiseSample);
                float4 surfaceNoiseColor = _FoamColor;
                surfaceNoiseColor.a *= surfaceNoise;

                return alphaBlend(surfaceNoiseColor, waterColor);
            }
            
            ENDHLSL
            
        }
    }
}
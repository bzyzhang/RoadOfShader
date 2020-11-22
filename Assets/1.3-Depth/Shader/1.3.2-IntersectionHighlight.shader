//https://www.jianshu.com/p/80a932d1f11e

Shader "RoadOfShader/1.3-Depth/Intersection Highlight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _IntersectionColor ("Intersection Color", Color) = (1, 1, 0, 0)
        _IntersectionWidth ("Intersection Width", Range(0, 1)) = 0.1
    }
    
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            
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
                float2 uv: TEXCOORD0;
                float eyeZ: TEXCOORD1;
                float4 positionScreen: TEXCOORD2;
                float4 vertex: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _IntersectionColor;
            float _IntersectionWidth;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertexInput.positionCS;
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                
                output.positionScreen = vertexInput.positionNDC;
                output.eyeZ = -vertexInput.positionVS.z;
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                half4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                float screenZ = LinearEyeDepth(SampleSceneDepth(input.positionScreen.xy / input.positionScreen.w), _ZBufferParams);
                
                float halfWidth = _IntersectionWidth / 2;
                float diff = saturate(abs(input.eyeZ - screenZ) / halfWidth);
                
                half4 finalColor = lerp(_IntersectionColor, color, diff);
                
                return finalColor;
            }
            ENDHLSL
            
        }
    }
}

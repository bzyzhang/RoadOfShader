//https://www.jianshu.com/p/d8b535efa9db

Shader "RoadOfShader/1.1-Dissolve/Trifox"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        [NoScaleOffset]_NoiseTex ("Noise Tex", 2D) = "white" { }
        [NoScaleOffset]_ScreenSpaceMaskTex ("Screen Space Mask", 2D) = "white" { }
        _WorkDistance ("Work Distance", Float) = 0
        _PlayerPos ("Player Pos", Vector) = (0, 0, 0, 0)
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Cull Off
            
            HLSLPROGRAM
            
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
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
                float3 positionWS: TEXCOORD1;
                float4 positionNDC: TEXCOORD2;
                float4 vertex: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _WorkDistance;
            float4 _PlayerPos;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);   SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_ScreenSpaceMaskTex);   SAMPLER(sampler_ScreenSpaceMaskTex);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertexInput.positionCS;
                output.positionWS = vertexInput.positionWS;
                output.positionNDC = vertexInput.positionNDC;
                
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                float toCamera = distance(input.positionWS, _WorldSpaceCameraPos);
                float playerToCamera = distance(_PlayerPos.xyz, _WorldSpaceCameraPos);
                
                float2 wcoord = input.positionNDC.xy / input.positionNDC.w;
                float mask = SAMPLE_TEXTURE2D(_ScreenSpaceMaskTex, sampler_ScreenSpaceMaskTex, wcoord).r;
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                float gradient = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, input.uv).r;
                
                if (toCamera < playerToCamera)
                    clip(gradient - mask + (toCamera - _WorkDistance) / _WorkDistance);
                
                return col;
            }
            ENDHLSL
            
        }
    }
}

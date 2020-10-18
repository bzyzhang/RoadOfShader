//https://www.jianshu.com/p/7cbae91e88d1

Shader "RoadOfShader/1.0-VertexAnimation/Squash"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _TopY ("Top Y", Float) = 1
        _BottomY ("Bottom Y", Float) = 0
        _Control ("Control", Range(0, 1)) = 0
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
                float4 vertex: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _TopY;
            half _BottomY;
            half _Control;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            
            float GetNormalizeDist(float worldY)
            {
                float range = _TopY - _BottomY;
                float distance = _TopY - worldY;
                
                return saturate(distance / range);
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float normalizeDist = GetNormalizeDist(positionWS.y);

                float3 localNegativeY = TransformWorldToObjectDir(float3(0,-1,0));
                float value = saturate(_Control - normalizeDist);
                input.positionOS.xyz += localNegativeY * value;
                
                output.vertex = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                return col;
            }
            ENDHLSL
            
        }
    }
}

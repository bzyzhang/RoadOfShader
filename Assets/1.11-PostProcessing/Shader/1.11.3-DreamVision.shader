Shader "RoadOfShader/1.11-PostProcessing/Dream Vision"
{
    Properties
    {
        _BlurLevel ("Blur Level", Float) = 1
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Cull Off
            ZWrite Off
            ZTest Always
            
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
                float4 vertex: SV_POSITION;
                float2 uv[9]: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_TexelSize;
            half _BlurLevel;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                output.vertex = TransformObjectToHClip(input.positionOS.xyz);
                float2 uv = input.uv;
                
                //当有多个RenderTarget时，需要自己处理UV翻转问题
                #if UNITY_UV_STARTS_AT_TOP //DirectX之类的
                    if (_MainTex_TexelSize.y < 0) //开启了抗锯齿
                    uv.y = 1 - uv.y; //满足上面两个条件时uv会翻转，因此需要转回来
                #endif
                
                output.uv[0] = uv + _MainTex_TexelSize.xy * float2(-1, -1) * _BlurLevel;
                output.uv[1] = uv + _MainTex_TexelSize.xy * float2(-1, 0) * _BlurLevel;
                output.uv[2] = uv + _MainTex_TexelSize.xy * float2(-1, 1) * _BlurLevel;
                output.uv[3] = uv + _MainTex_TexelSize.xy * float2(0, -1) * _BlurLevel;
                output.uv[4] = uv + _MainTex_TexelSize.xy * float2(0, 0) * _BlurLevel;
                output.uv[5] = uv + _MainTex_TexelSize.xy * float2(0, 1) * _BlurLevel;
                output.uv[6] = uv + _MainTex_TexelSize.xy * float2(1, -1) * _BlurLevel;
                output.uv[7] = uv + _MainTex_TexelSize.xy * float2(1, 0) * _BlurLevel;
                output.uv[8] = uv + _MainTex_TexelSize.xy * float2(1, 1) * _BlurLevel;
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[0]);
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[1]);
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[2]);
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[3]);
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[4]);
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[5]);
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[6]);
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[7]);
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[8]);

                col /= 9;

                col.rgb = (col.r + col.g + col.b) / 3.0; //黑白化
                
                return col;
            }
            ENDHLSL
            
        }
    }
}

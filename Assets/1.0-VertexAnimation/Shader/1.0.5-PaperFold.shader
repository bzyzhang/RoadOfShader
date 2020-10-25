//https://www.jianshu.com/p/7cbae91e88d1

Shader "RoadOfShader/1.0-VertexAnimation/PaperFold"
{
    Properties
    {
        _FrontTex ("Front Tex", 2D) = "white" { }
        _BackTex("Back Tex",2D) = "white" {}
        _FoldPos("Fold Pos",Float) = 0.0
        _FoldAngle("Fold Angle",Range(1,180)) = 90
        [Toggle(ENABLE_DOUBLE)]_DoubleFold("Double Fold",Float) = 0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        
        Pass
        {
            Tags { "LightMode" = "SRPDefaultUnlit" }

            ZWrite On
            Cull Back
            Blend SrcAlpha OneMinusSrcAlpha
            
            HLSLPROGRAM
            
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma shader_feature ENABLE_DOUBLE
            
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
            float4 _FrontTex_ST;
            float _FoldPos;
            float _FoldAngle;
            CBUFFER_END
            
            TEXTURE2D(_FrontTex);    SAMPLER(sampler_FrontTex);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                float angle = _FoldAngle;
                float r = _FoldPos - input.positionOS.x;

                #if ENABLE_DOUBLE
                    if (r < 0) {
                        angle = 360 - _FoldAngle;
                    }
                #else
                    if (r < 0) {
                        angle = 180;
                    }
                #endif

                input.positionOS.x = _FoldPos + r * cos(angle * PI / 180);
                input.positionOS.y  = r * sin(angle * PI / 180);

                output.vertex = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv,_FrontTex);
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                half4 col = SAMPLE_TEXTURE2D(_FrontTex, sampler_FrontTex, input.uv);
                return col;
            }
            ENDHLSL
            
        }

        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            ZWrite On
            Cull Front
            Blend SrcAlpha OneMinusSrcAlpha
            
            HLSLPROGRAM
            
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma shader_feature ENABLE_DOUBLE
            
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
            float4 _BackTex_ST;
            float _FoldPos;
            float _FoldAngle;
            CBUFFER_END
            
            TEXTURE2D(_BackTex);    SAMPLER(sampler_BackTex);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                float angle = _FoldAngle;
                float r = _FoldPos - input.positionOS.x;

                #if ENABLE_DOUBLE
                    if (r < 0) {
                        angle = 360 - _FoldAngle;
                    }
                #else
                    if (r < 0) {
                        angle = 180;
                    }
                #endif

                input.positionOS.x = _FoldPos + r * cos(angle * PI / 180);
                input.positionOS.y  = r * sin(angle * PI / 180);

                output.vertex = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv,_BackTex);
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                half4 col = SAMPLE_TEXTURE2D(_BackTex, sampler_BackTex, input.uv);
                return col;
            }
            ENDHLSL
            
        }
    }
}

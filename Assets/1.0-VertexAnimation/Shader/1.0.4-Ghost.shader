//https://www.jianshu.com/p/7cbae91e88d1

Shader "RoadOfShader/1.0-VertexAnimation/Ghost"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _GhostColor ("Ghost Color", Color) = (1, 1, 1, 1) //残影颜色
        _Offset ("Offset", Range(0, 2)) = 0 //残影偏离本位的距离
        _GhostAlpha ("Ghost Alpha", Range(0, 1)) = 1 //残影的透明度
        _ShakeLevel ("Shake Level", Range(0, 2)) = 0 //残影抖动的程度
        _ShakeSpeed ("Shake Speed", Range(0, 50)) = 1 //残影的移动速度
        _ShakeDir ("Shake Direction", Vector) = (0, 0, 1, 0) //残影移动的方向
        _Control ("Control", Range(0, 0.54)) = 0 //整体控制残影
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }

        //渲染残影
        Pass
        {
            Tags { "LightMode" = "SRPDefaultUnlit" }
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            
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
            half4 _GhostColor;
            half _Offset;
            half _GhostAlpha;
            half _ShakeLevel;
            float _ShakeSpeed;
            float4 _ShakeDir;
            half _Control;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                float yOffset = 0.5 * (floor(input.positionOS.x * 10) % 2);
                
                input.positionOS += _Offset * cos(_Time.y * _ShakeSpeed) * _ShakeDir * _Control;
                input.positionOS += _ShakeLevel * yOffset * sin(_Time.y * _ShakeSpeed) * _ShakeDir * _Control;
                
                output.vertex = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                half3 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).rgb * _GhostColor.rgb;
                
                return half4(col, _GhostAlpha);
            }
            ENDHLSL
            
        }

        //渲染本体
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
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
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

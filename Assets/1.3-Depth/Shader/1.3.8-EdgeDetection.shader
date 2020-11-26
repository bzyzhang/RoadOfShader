//https://www.jianshu.com/p/80a932d1f11e

Shader "RoadOfShader/1.3-Depth/Edge Detection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _EdgeThreshold ("Edge Threshold", Range(0.001, 1)) = 0.001
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Cull Off
            ZTest Always
            ZWrite Off
            
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
                float2 uv[5]: TEXCOORD0;
                float4 vertex: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_TexelSize;
            float _EdgeThreshold;
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
                
                output.uv[0] = uv;
                //Robers算子
                output.uv[1] = uv + _MainTex_TexelSize.xy * float2(-1, -1);
                output.uv[2] = uv + _MainTex_TexelSize.xy * float2(-1, 1);
                output.uv[3] = uv + _MainTex_TexelSize.xy * float2(1, -1);
                output.uv[4] = uv + _MainTex_TexelSize.xy * float2(1, 1);
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[0]);
                
                float sample1 = Linear01Depth(SampleSceneDepth(input.uv[1]), _ZBufferParams);
                float sample2 = Linear01Depth(SampleSceneDepth(input.uv[2]), _ZBufferParams);
                float sample3 = Linear01Depth(SampleSceneDepth(input.uv[3]), _ZBufferParams);
                float sample4 = Linear01Depth(SampleSceneDepth(input.uv[4]), _ZBufferParams);
                
                float edge = 1.0;
                //对角线的差异相乘
                edge *= abs(sample1 - sample4) < _EdgeThreshold ? 1.0: 0.0;
                edge *= abs(sample2 - sample3) < _EdgeThreshold ? 1.0: 0.0;
                
                return edge;
                // return lerp(0, col, edge);  //描边
            }
            ENDHLSL
            
        }
    }
}

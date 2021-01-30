//利用Sobel来根据颜色值进行边缘检测
//https://www.wikiwand.com/en/Sobel_operator
//https://www.tutorialspoint.com/dip/sobel_operator.htm
Shader "RoadOfShader/1.11-PostProcessing/Edge Detection By Sobel"
{
    Properties
    {
        _Hardness ("Hardness", Range(0, 5)) = 1
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
            #include "Assets/_Libs/Tools.hlsl"
            
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
            half _Hardness;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            
            half Sobel(float2 uv[9])
            {
                const half verticalMask[9] = {
                    - 1, 0, 1,
                    - 2, 0, 2,
                    - 1, 0, 1
                };
                const half horizontalMask[9] = {
                    - 1, -2, -1,
                    0, 0, 0,
                    1, 2, 1
                };
                
                half edgeVertical = 0;
                half edgeHorizontal = 0;
                for (int i = 0; i < 9; i ++)
                {
                    half lum = CustomLuminance(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv[i]));
                    edgeVertical += verticalMask[i] * lum * _Hardness;
                    edgeHorizontal += horizontalMask[i] * lum * _Hardness;
                }
                
                return abs(edgeVertical) + abs(edgeHorizontal);
            }
            
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
                
                output.uv[0] = uv + _MainTex_TexelSize.xy * float2(-1, -1) ;
                output.uv[1] = uv + _MainTex_TexelSize.xy * float2(-1, 0) ;
                output.uv[2] = uv + _MainTex_TexelSize.xy * float2(-1, 1) ;
                output.uv[3] = uv + _MainTex_TexelSize.xy * float2(0, -1) ;
                output.uv[4] = uv + _MainTex_TexelSize.xy * float2(0, 0) ;
                output.uv[5] = uv + _MainTex_TexelSize.xy * float2(0, 1) ;
                output.uv[6] = uv + _MainTex_TexelSize.xy * float2(1, -1) ;
                output.uv[7] = uv + _MainTex_TexelSize.xy * float2(1, 0) ;
                output.uv[8] = uv + _MainTex_TexelSize.xy * float2(1, 1) ;
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
				half edge = Sobel(input.uv);
				return edge;
            }
            ENDHLSL
            
        }
    }
}

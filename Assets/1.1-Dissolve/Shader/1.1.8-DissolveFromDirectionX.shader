//https://www.jianshu.com/p/d8b535efa9db

Shader "RoadOfShader/1.1-Dissolve/Dissolve From Direction X"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        _NoiseTex ("Noise Tex", 2D) = "white" { }
        _Threshold ("Threshold", Range(0, 1)) = 0
        _EdgeLength ("Edge Length", Range(0.0, 0.2)) = 0.1
        _RampTex ("Ramp Tex", 2D) = "white" { }
        _Direction ("Direction", Int) = 1 //1表示从X正方向开始，其他值则从负方向
        _MinBorderX ("Min Border X", Float) = -0.5 //从程序传入
        _MaxBorderX ("Max Border X", Float) = 0.5  //从程序传入
        _DistanceEffect ("Distance Effect", Range(0, 1)) = 0.5
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
            
            #pragma shader_feature _ALPHATEST_ON
            
            #define _ALPHATEST_ON 1
            
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
                float4 uv: TEXCOORD0;
                float objPosX: TEXCOORD1;
                float4 vertex: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _NoiseTex_ST;
            half _Threshold;
            float _EdgeLength;
            float4 _RampTex_ST;
            int _Direction;
            float _MinBorderX;
            float _MaxBorderX;
            half _DistanceEffect;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);   SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_RampTex);    SAMPLER(sampler_RampTex);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                output.vertex = TransformObjectToHClip(input.positionOS.xyz);
                output.uv.xy = TRANSFORM_TEX(input.uv, _MainTex);
                output.uv.zw = TRANSFORM_TEX(input.uv, _NoiseTex);
                
                output.objPosX = input.positionOS.x;
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                float range = _MaxBorderX - _MinBorderX;
                float border = _MinBorderX;
                if (_Direction == 1) //1表示从X正方向开始，其他值则从负方向
                    border = _MaxBorderX;
                
                float distance = abs(input.objPosX - border);
                float normalizedDistance = saturate(distance / range);
                
                float cutout = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, input.uv.zw).r * (1.0 - _DistanceEffect) + normalizedDistance * _DistanceEffect;
                AlphaDiscard(cutout, _Threshold);
                
                float degree = saturate((cutout - _Threshold) / _EdgeLength);
                half4 edgeColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(degree, degree));
                
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv.xy);
                
                half4 finalColor = lerp(edgeColor, col, degree);
                
                return half4(finalColor.rgb, 1.0);
            }
            ENDHLSL
            
        }
    }
}

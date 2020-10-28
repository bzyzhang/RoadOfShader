//https://www.jianshu.com/p/d8b535efa9db

Shader "RoadOfShader/1.1-Dissolve/Direction Ash"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        [NoScaleOffset]_NoiseTex ("Noise Tex", 2D) = "white" { }
        [NoScaleOffset]_WhiteNoiseTex("White Noise Tex",2D) = "white" {}
        [NoScaleOffset] _RampTex ("Ramp Tex", 2D) = "white" { }
        _Threshold ("Threshold", Range(0, 1)) = 0
        _EdgeLength ("Edge Length", Range(0.0, 0.2)) = 0.1
        _MinBorderY("Min Border Y",Float) = 0
        _MaxBorderY("Max Border Y",Float) = 0
        _DistanceEffect ("Distance Effect", Range(0, 1)) = 0.5
        _AshColor("Ash Color",Color) = (1,1,1,1)
        _AshWidth("Ash Width",range(0.0,0.25)) = 0
        _AshDensity("Ash Density", Range(0, 1)) = 1
        _FlyIntensity("Fly Intensity", Range(0,0.3)) = 0.1
		_FlyDirection("Fly Direction", Vector) = (1,1,1,1) 
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
                float2 uv: TEXCOORD0;
                float3 positionWS: TEXCOORD1;
                float4 vertex: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _Threshold;
            float _EdgeLength;
            float _MinBorderY;
            float _MaxBorderY;
            half _DistanceEffect;
            half4 _AshColor;
            float _AshWidth;
            float _AshDensity;
            float _FlyIntensity;
            float4 _FlyDirection;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_NoiseTex);   SAMPLER(sampler_NoiseTex);
            TEXTURE2D(_WhiteNoiseTex);  SAMPLER(sampler_WhiteNoiseTex);
            TEXTURE2D(_RampTex);    SAMPLER(sampler_RampTex);

            float GetNormalizeDistance(float posY)
            {
                float range = _MaxBorderY - _MinBorderY;
                float border = _MaxBorderY;

                float distance = abs(posY - border);
                return saturate(distance / range);
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                output.uv = input.uv;               
                output.positionWS = TransformObjectToWorld(input.positionOS.xyz);

                float cutout = GetNormalizeDistance(output.positionWS.y);
                float3 localFlyDirection = TransformWorldToObjectDir(_FlyDirection.xyz);
                float flyDegree = (_Threshold- cutout) / _EdgeLength;
                float val = saturate(flyDegree * _FlyIntensity);
                input.positionOS.xyz += localFlyDirection * val;

                output.vertex = TransformObjectToHClip(input.positionOS.xyz);
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                half4 albedo = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
                float commonNoise = SAMPLE_TEXTURE2D(_NoiseTex,sampler_NoiseTex,input.uv).r;
                float whiteNoise = SAMPLE_TEXTURE2D(_WhiteNoiseTex,sampler_WhiteNoiseTex,input.uv).r;
                
                float normalizedDistance = GetNormalizeDistance(input.positionWS.y);
                
                float cutout = commonNoise * (1.0 - _DistanceEffect) + normalizedDistance * _DistanceEffect;
                float edgeCutout = cutout - _Threshold;
                clip(edgeCutout + _AshWidth);
                
                float degree = saturate(edgeCutout / _EdgeLength);
                half4 edgeColor = SAMPLE_TEXTURE2D(_RampTex, sampler_RampTex, float2(degree, degree));
                
                half4 finalColor = lerp(edgeColor, albedo, degree);
                if(degree < 0.001)
                {
                    clip(whiteNoise * _AshDensity + normalizedDistance * _DistanceEffect - _Threshold);
                    finalColor = _AshColor;
                }
                
                return half4(finalColor.rgb, 1.0);
            }
            ENDHLSL
            
        }
    }
}

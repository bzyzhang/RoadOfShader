Shader "RoadOfShader/2.2-SpeedLine/Speed Line"
{
    Properties
    {
        [NoScaleOffset]_NoiseTex ("NoiseTex", 2D) = "white" { }
        _Center ("Center", Vector) = (0.5, 0.5, 0, 0)
        _RotateSpeed ("Rotate Speed", Range(0,5)) = 0.2
        _RayMultiply ("RayMultiply", Range(0.001, 50)) = 7.5
        _RayPower ("RayPower", Range(0, 50)) = 3.22
        _Threshold ("Threshold", Range(0, 1)) = 1
        _TintColor ("Tint Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            
            HLSLPROGRAM

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
            };
            
            struct Varyings
            {
                float2 uv: TEXCOORD0;
                float4 vertex: SV_POSITION;
            };
            
            CBUFFER_START(UnityPerMaterial)
            half4 _Center;
            half _RotateSpeed;
            half _RayMultiply;
            half _RayPower;
            half _Threshold;
            half4 _TintColor;
            CBUFFER_END
            
            TEXTURE2D(_NoiseTex);   SAMPLER(sampler_NoiseTex);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                output.vertex = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                half2 uv = input.uv - _Center.xy;

                half angle = _RotateSpeed * _Time.y;

                half cosAngle = cos(angle);
                half sinAngle = sin(angle);

                half2x2 rotateMatrix0 = half2x2(cosAngle, -sinAngle, sinAngle, cosAngle);
                half2 normalizedUV0 = normalize(mul(rotateMatrix0, uv));

                half2x2 rotateMatrix1 = half2x2(cosAngle, sinAngle, -sinAngle, cosAngle);
                half2 normalizedUV1 = normalize(mul(rotateMatrix1, uv));
                
                half textureMask = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, normalizedUV0).r * SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, normalizedUV1).r;

                half uvMask = pow(_RayMultiply * length(uv), _RayPower);

                half mask = smoothstep(_Threshold - 0.1, _Threshold + 0.1, textureMask * uvMask);
                
                return half4(_TintColor.rgb, mask * _TintColor.a);
            }
            ENDHLSL
        }
    }
}

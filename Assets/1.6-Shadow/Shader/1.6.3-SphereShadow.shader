Shader "RoadOfShader/1.6-Shadow/Sphere Shadow"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        _ShadowFalloff ("_ShadowFalloff", Float) = 0.05
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
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
                float4 positionCS: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _ShadowFalloff;
            
            float4 _SpherePos;
            float _SphereRadius;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionWS = vertexInput.positionWS;
                output.positionCS = vertexInput.positionCS;
                
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);
                
                float3 toSphere = normalize(_SpherePos.xyz - input.positionWS);
                float angle = acos(dot(lightDir, toSphere));//到圆向量和到光源向量的夹角
                
                float distToSphere = length(_SpherePos.xyz - input.positionWS);
                float maxAngle = atan(_SphereRadius / distToSphere);//圆覆盖的角度
                
                if (angle < maxAngle)//处于圆覆盖的范围
                {
					half atten = (angle / maxAngle)  / _ShadowFalloff;
					return smoothstep(0, 1, atten);
                }
                else
                {
                    half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                    return col;
                }
            }
            ENDHLSL
            
        }
    }
}

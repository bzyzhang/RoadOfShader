Shader "RoadOfShader/1.10-Subsurface Scattering/Fast SSS"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _SSSDistortion ("SSS Distortion", Range(0, 1)) = 1
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float3 normalOS: NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float3 positionWS: TEXCOORD0;
                float3 normalWS: NORMAL;
                float4 positionCS: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            half4 _Diffuse;
            half _SSSDistortion;
            CBUFFER_END
            
            half3 computeSSS(Light light, float3 normal, float3 viewDir)
            {
                half3 lightDir = normalize(light.direction);
                half3 dir = normalize(lightDir + normal * _SSSDistortion);
                half3 sss = _Diffuse.rgb * light.color * saturate(dot(viewDir, -dir));

                return sss;
            }

            half3 LightingBased(Light light, half3 normalWS, half3 viewDirWS)
            {
                half3 lightDirWS = normalize(light.direction);
                half diff = saturate(dot(normalWS, lightDirWS));
                half3 diffuse = light.color * _Diffuse.rgb * diff;

                half3 sss = computeSSS(light, normalWS, viewDirWS);
                
                return (diffuse + sss) * light.distanceAttenuation * light.shadowAttenuation;
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionWS = vertexInput.positionWS;
                output.positionCS = vertexInput.positionCS;
                
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                half3 normalWS = normalize(input.normalWS);
                half3 viewDirWS = normalize(GetCameraPositionWS() - input.positionWS);
                
                Light mainLight = GetMainLight();
                half3 lightDirWS = normalize(mainLight.direction);
                
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _Diffuse.rgb;
                
                half diff = saturate(dot(normalWS, lightDirWS));
                half3 diffuse = mainLight.color * _Diffuse.rgb * diff;

                half3 sss = computeSSS(mainLight, normalWS, viewDirWS);
                
                half3 finalColor = ambient + diffuse + sss;
                
                uint pixelLightCount = GetAdditionalLightsCount();
                for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++ lightIndex)
                {
                    Light light = GetAdditionalLight(lightIndex, input.positionWS);
                    finalColor += LightingBased(light, normalWS, viewDirWS);
                }

                return half4(finalColor, 1.0);
            }
            ENDHLSL
            
        }
    }
}

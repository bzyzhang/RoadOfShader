Shader "RoadOfShader/2.1-PBR/Custom Metallic PBR"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo", 2D) = "white" { }
        _Glossiness ("Smoothness", Range(0.0, 1.0)) = 0.5
        _MetallicGlossMap ("Metallic", 2D) = "white" { }
        _BumpScale ("Bump Scale", Float) = 1.0
        _BumpMap ("Normal Map", 2D) = "bump" { }
        _EmissionColor ("Color", Color) = (0, 0, 0)
        _EmissionMap ("Emission", 2D) = "white" { }
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
            
            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
            
            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                float3 normalOS: NORMAL;
                float4 tangentOS: TANGENT;
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                float4 TtoW0: TEXCOORD1;
                float4 TtoW1: TEXCOORD2;
                float4 TtoW2: TEXCOORD3;
                float fogFactor: TEXCOORD4;
                float4 shadowCoord: TEXCOORD5;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            half4 _Color;
            float4 _MainTex_ST;
            half _Glossiness;
            half _BumpScale;
            half3 _EmissionColor;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
            TEXTURE2D(_BumpMap);   SAMPLER(sampler_BumpMap);
            TEXTURE2D(_EmissionMap);   SAMPLER(sampler_EmissionMap);
            
            inline half3 CustomDisneyDiffuseTerm(half NdotV, half NdotL, half LdotH, half roughness, half3 baseColor)
            {
                half fd90 = 0.5 + 2 * LdotH * LdotH * roughness;
                
                // Two schlick fresnel term
                half lightScatter = 1 + (fd90 - 1) * pow(1 - NdotL, 5);
                half viewScatter = 1 + (fd90 - 1) * pow(1 - NdotV, 5);
                
                return baseColor * INV_PI * lightScatter * viewScatter;
            }
            
            inline half CustomSmithJointGGXVisibilityTerm(half NdotL, half NdotV, half roughness)
            {
                half a2 = roughness * roughness;
                half lambdaV = NdotL * (NdotV * (1 - a2) + a2);
                half lambdaL = NdotV * (NdotL * (1 - a2) + a2);
                
                return 0.5f / (lambdaV + lambdaL + 1e-5f);
            }
            
            inline half CustomGGXTerm(half NdotH, half roughness)
            {
                half a2 = roughness * roughness;
                half d = (NdotH * a2 - NdotH) * NdotH + 1.0f;
                return INV_PI * a2 / (d * d + 1e-7f);
            }
            
            inline half3 CustomFresnelTerm(half3 c, half cosA)
            {
                half t = pow(1 - cosA, 5);
                return c + (1 - c) * t;
            }
            
            inline half3 CustomFresnelLerp(half3 c0, half3 c1, half cosA)
            {
                half t = pow(1 - cosA, 5);
                return lerp(c0, c1, t);
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                
                output.positionCS = vertexInput.positionCS;
                
                output.TtoW0 = float4(normalInput.tangentWS.x, normalInput.bitangentWS.x, normalInput.normalWS.x, vertexInput.positionWS.x);
                output.TtoW1 = float4(normalInput.tangentWS.y, normalInput.bitangentWS.y, normalInput.normalWS.y, vertexInput.positionWS.y);
                output.TtoW2 = float4(normalInput.tangentWS.z, normalInput.bitangentWS.z, normalInput.normalWS.z, vertexInput.positionWS.z);
                
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                
                output.fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
                
                output.shadowCoord = GetShadowCoord(vertexInput);
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                //**********************************************************************************
                //Prepare all the inputs
                half4 metallicMap = SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, input.uv);
                half metallic = metallicMap.r;
                half smoothness = metallicMap.a * _Glossiness;
                half roughness = 1.0 - smoothness;
                
                half3 albedo = _Color.rgb * SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).rgb;
                
                half oneMinusReflectivity = kDieletricSpec.a - metallic * kDieletricSpec.a;
                half3 diffColor = albedo * oneMinusReflectivity;
                half3 specColor = lerp(kDieletricSpec.rgb, albedo, metallic);
                
                half3 normalTS = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, input.uv));
                normalTS.xy *= _BumpScale;
                normalTS.z = sqrt(1.0 - saturate(dot(normalTS.xy, normalTS.xy)));
                half3 normalWS = normalize(half3(dot(input.TtoW0.xyz, normalTS), dot(input.TtoW1.xyz, normalTS), dot(input.TtoW2.xyz, normalTS)));
                
                float3 positionWS = float3(input.TtoW0.w, input.TtoW1.w, input.TtoW2.w);
                half3 viewDirWS = normalize(GetCameraPositionWS() - positionWS);
                half3 reflDirWS = reflect(-viewDirWS, normalWS);
                
                Light mainLight = GetMainLight(input.shadowCoord);
                half3 lightDirWS = normalize(mainLight.direction);
                
                //Compute BRDF terms
                half3 halfDir = normalize(lightDirWS + viewDirWS);
                half nv = saturate(dot(normalWS, viewDirWS));
                half nl = saturate(dot(normalWS, lightDirWS));
                half nh = saturate(dot(normalWS, halfDir));
                half lv = saturate(dot(lightDirWS, viewDirWS));
                half lh = saturate(dot(lightDirWS, halfDir));
                
                //Diffuse Term
                half3 diffuseTerm = CustomDisneyDiffuseTerm(nv, nl, lh, roughness, diffColor);
                
                //Specualr Term
                half V = CustomSmithJointGGXVisibilityTerm(nl, nv, roughness);
                half D = CustomGGXTerm(nh, roughness * roughness);
                half3 F = CustomFresnelTerm(specColor, lh);
                half3 specularTerm = F * V * D;
                
                half3 emissionTerm = SAMPLE_TEXTURE2D(_EmissionMap, sampler_EmissionMap, input.uv).rgb * _EmissionColor.rgb;
                
                //IBL
                half perceptualRoughness = roughness * (1.7 - 0.7 * roughness);
                half mip = perceptualRoughness * 6;
                half4 envMap = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflDirWS, mip);
                half grazingTerm = saturate((1 - roughness) + (1 - oneMinusReflectivity));
                half surfaceReduction = 1.0 / (roughness * roughness + 1.0);
                half3 indirectSpecular = surfaceReduction * envMap.rgb * CustomFresnelLerp(specColor, grazingTerm, nv);
                
                //Combine all togather
                half3 col = emissionTerm + PI * (diffuseTerm + specularTerm) * mainLight.color * nl * mainLight.distanceAttenuation * mainLight.shadowAttenuation
                + indirectSpecular;
                
                col.rgb = MixFog(col.rgb, input.fogFactor);
                
                return half4(col, 1);
            }
            ENDHLSL
            
        }
    }
}

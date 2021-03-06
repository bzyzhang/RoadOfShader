﻿//https://www.jianshu.com/p/fea6c9fc610f

Shader "RoadOfShader/1.2-Bump/Bump"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        _DepthMap ("Depth Map", 2D) = "bump" { }
        _Scale ("Scale", Range(0, 10)) = 0
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
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 uv: TEXCOORD0;
                float3 lightDirTS : TEXCOORD1;
                float4 positionCS: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _DepthMap_ST;
            float4 _DepthMap_TexelSize;
            float _Scale;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_DepthMap);   SAMPLER(sampler_DepthMap);

            float3 CalculateNormal(float2 uv)
            {
                float2 du = float2(_DepthMap_TexelSize.x * 0.5,0);
                float u1 = SAMPLE_TEXTURE2D(_DepthMap,sampler_DepthMap,uv - du).r;
                float u2 = SAMPLE_TEXTURE2D(_DepthMap,sampler_DepthMap,uv + du).r;
                float3 tu = float3(1,0,(u2 - u1)*_Scale);

                float2 dv = float2(0,_DepthMap_TexelSize.y * 0.5);
                float v1 = SAMPLE_TEXTURE2D(_DepthMap,sampler_DepthMap,uv - dv).r;
                float v2 = SAMPLE_TEXTURE2D(_DepthMap,sampler_DepthMap,uv + dv).r;
                float3 tv = float3(0,1,(v2 - v1)*_Scale);

                return normalize(-cross(tu,tv));
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                Light mainLight = GetMainLight();
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS,input.tangentOS);
                float3x3 tbn = float3x3(normalInputs.tangentWS,normalInputs.bitangentWS,normalInputs.normalWS);
                output.lightDirTS = mul(tbn,mainLight.direction);
                
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv.xy = TRANSFORM_TEX(input.uv, _MainTex);
                output.uv.zw = TRANSFORM_TEX(input.uv, _DepthMap);
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float3 lightDirTS = normalize(input.lightDirTS);
                float3 normalTS = CalculateNormal(input.uv.zw);
                
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv.xy);

                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz *  albedo.rgb;
                
                Light mainLight = GetMainLight();
                half3 diffuseColor = mainLight.color * albedo.rgb * saturate(dot(normalTS,lightDirTS));

                half3 finalColor = albedo.rgb + diffuseColor;

                return half4(finalColor,1.0);
            }
            ENDHLSL
            
        }
    }
}

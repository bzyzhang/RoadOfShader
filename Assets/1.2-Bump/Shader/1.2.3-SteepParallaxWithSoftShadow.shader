//https://www.jianshu.com/p/fea6c9fc610f

Shader "RoadOfShader/1.2-Bump/Steep Parallax With Soft Shadow"
{
    Properties
    {
        [NoScaleOffset]_MainTex ("Main Tex", 2D) = "white" { }
        [NoScaleOffset]_NormalMap ("Normal Map", 2D) = "bump" { }
        [NoScaleOffset]_DepthMap ("Depth Map", 2D) = "bump" { }
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(32, 256)) = 64
        _HeightScale ("Height Scale", Range(0, 1)) = 0.1
        _MaxLayerNum ("Max Layer Num", Float) = 1
        _MinLayerNum ("Min Layer Num", Float) = 1
        _ShadowIntensity ("Self Shadow Intensity", Range(0, 1)) = 1
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
                float4 tangentOS: TANGENT;
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float2 uv: TEXCOORD0;
                float3 lightDirTS: TEXCOORD1;
                float3 viewDirTS: TEXCOORD2;
                float4 positionCS: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            struct parallaxDS
            {
                float2 uv;
                float height;
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _SpecularColor;
            float _Gloss;
            float _HeightScale;
            float _MaxLayerNum;
            float _MinLayerNum;
            float _ShadowIntensity;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalMap);   SAMPLER(sampler_NormalMap);
            TEXTURE2D(_DepthMap);   SAMPLER(sampler_DepthMap);

            parallaxDS ParallaxMapping(float2 uv, float3 viewDir_tangent)
            {
                float3 viewDir = normalize(viewDir_tangent);

                float layerNum = lerp(_MaxLayerNum, _MinLayerNum, abs(dot(float3(0, 0, 1), viewDir)));//一点优化：根据视角来决定分层数
                float layerDepth = 1.0 / layerNum;
                float currentLayerDepth = 0.0;
                float2 deltaTexCoords = viewDir.xy / viewDir.z / layerNum * _HeightScale;

                float2 currentTexCoords = uv;
                float currentDepthMapValue = SAMPLE_TEXTURE2D(_DepthMap, sampler_DepthMap, currentTexCoords).r;

                //unable to unroll loop, loop does not appear to terminate in a timely manner
                //上面这个错误是在循环内使用SAMPLE_TEXTURE2D导致的，需要加上unroll来限制循环次数或者改用SAMPLE_TEXTURE2D_LOD
                // [unroll(100)]
                while(currentLayerDepth < currentDepthMapValue)
                {
                    currentTexCoords -= deltaTexCoords;
                    // currentDepthMapValue = SAMPLE_TEXTURE2D(_DepthMap, sampler_DepthMap, currentTexCoords).r;
                    currentDepthMapValue = SAMPLE_TEXTURE2D_LOD(_DepthMap, sampler_DepthMap, currentTexCoords, 0).r;
                    currentLayerDepth += layerDepth;
                }

                parallaxDS o;
                o.uv = currentTexCoords;
                o.height = currentLayerDepth;

                return o;
            }

            float ParallaxShadow(float3 lightDir_tangent, float2 initialUV, float initialHeight)
            {
                float3 lightDir = normalize(lightDir_tangent);

                float shadowMultiplier = 1;

                const float minLayers = 15;
                const float maxLayers = 30;

                //只算正对阳光的面
                if (dot(float3(0, 0, 1), lightDir) > 0)
                {
                    float numSamplesUnderSurface = 0;
                    shadowMultiplier = 0;
                    float numLayers = lerp(maxLayers, minLayers, abs(dot(float3(0, 0, 1), lightDir))); //根据光线方向决定层数
                    float layerHeight = 1 / numLayers;
                    float2 texStep = _HeightScale * lightDir.xy / lightDir.z / numLayers;

                    float currentLayerHeight = initialHeight - layerHeight;
                    float2 currentTexCoords = initialUV + texStep;
                    float heightFromTexture = SAMPLE_TEXTURE2D(_DepthMap, sampler_DepthMap, currentTexCoords).r;
                    int stepIndex = 1;

                    while(currentLayerHeight > 0)
                    {
                        if (heightFromTexture < currentLayerHeight)
                        {
                            numSamplesUnderSurface += 1;
                            float newShadowMultiplier = (currentLayerHeight - heightFromTexture) * (1.0 - stepIndex / numLayers);
                            shadowMultiplier = max(shadowMultiplier, newShadowMultiplier);
                        }

                        stepIndex += 1;
                        currentLayerHeight -= layerHeight;
                        currentTexCoords += texStep;
                        heightFromTexture = SAMPLE_TEXTURE2D_LOD(_DepthMap, sampler_DepthMap, currentTexCoords, 0).r;
                    }

                    if(numSamplesUnderSurface < 1)
                    {
                        shadowMultiplier = 1;
                    }
                    else
                    {
                        shadowMultiplier = 1.0 - shadowMultiplier;
                    }
                }

                return shadowMultiplier;
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

                VertexPositionInputs vertexInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = vertexInputs.positionCS;
                
                Light mainLight = GetMainLight();
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                float3x3 tbn = float3x3(normalInputs.tangentWS, normalInputs.bitangentWS, normalInputs.normalWS);
                output.lightDirTS = mul(tbn, mainLight.direction);
                output.viewDirTS = mul(tbn, GetCameraPositionWS() - vertexInputs.positionWS);

                output.uv = input.uv;
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float3 lightDirTS = normalize(input.lightDirTS);
                float3 viewDirTS = normalize(input.viewDirTS);

                parallaxDS pds = ParallaxMapping(input.uv, viewDirTS);
                float2 uv = pds.uv;
                float parallaxHeight = pds.height;
                if(uv.x > 1.0 || uv.y > 1.0 || uv.x < 0.0 || uv.y < 0.0) //去掉边上的一些古怪的失真，在平面上工作得挺好的
                discard;

                float shadowMultiplier = ParallaxShadow(lightDirTS, uv, parallaxHeight);
                
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                half4 packedNormal = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uv);
                float3 normalTS = UnpackNormal(packedNormal);
                
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo.rgb;
                
                Light mainLight = GetMainLight();
                half3 diffuseColor = mainLight.color * albedo.rgb * (saturate(dot(normalTS, lightDirTS)) * 0.8 + 0.2);

                half3 halfDir = normalize(viewDirTS + lightDirTS);
                half3 specularColor = mainLight.color * _SpecularColor.rgb * pow(saturate(dot(normalTS, halfDir)), _Gloss);
                
                half3 finalColor = albedo.rgb + (diffuseColor + specularColor) * pow(shadowMultiplier, 4.0 * _ShadowIntensity);
                
                return half4(finalColor, 1.0);
            }
            ENDHLSL
            
        }
    }
}

Shader "RoadOfShader/1.8-Lighting/LightingNReflect"
{
    Properties
    {
        _EnvMap ("Env Map", CUBE) = "_skybox" { }
        _MainColor ("Main Color", Color) = (1, 1, 1, 1)
        _ReflectColor ("Reflect Color", Color) = (1, 1, 1, 1)
        _ReflectAmount ("Reflect Amount", Range(0, 1)) = 1
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
                float3 normalOS: NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float3 normalWS: NORMAL;
                float3 reflectDirWS: TEXCOORD0;
                float4 vertex: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            half4 _MainColor;
            half4 _ReflectColor;
            half _ReflectAmount;
            CBUFFER_END
            
            TEXTURECUBE(_EnvMap);    SAMPLER(sampler_EnvMap);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertexInput.positionCS;
                
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                output.reflectDirWS = reflect(-viewDirWS, output.normalWS);
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                half3 normalWS = normalize(input.normalWS);
                
                Light mainLight = GetMainLight();
                half3 lightDirWS = normalize(mainLight.direction);
                
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * _MainColor.rgb;
                
                half3 diffuse = mainLight.color.rgb * _MainColor.rgb * saturate(dot(lightDirWS, normalWS));
                
                half3 reflectColor = SAMPLE_TEXTURECUBE(_EnvMap, sampler_EnvMap, input.reflectDirWS).rgb * _ReflectColor.rgb;
                
                half3 col = lerp(ambient + diffuse, reflectColor, _ReflectAmount);
                return half4(col, 1);
            }
            ENDHLSL
            
        }
    }
}

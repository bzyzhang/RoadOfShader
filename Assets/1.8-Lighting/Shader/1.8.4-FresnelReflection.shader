Shader "RoadOfShader/1.8-Lighting/FresnelReflection"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _FresnelScale ("Fresnel Scale", Range(0, 1)) = 1
        _EnvMap ("Env Map", Cube) = "_Skybox" { }
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
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float3 normalWS: NORMAL;
                float3 reflectDirWS: TEXCOORD0;
                float3 viewDirWS: TEXCOORD1;
                float2 uv: TEXCOORD2;
                float4 vertex: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            half4 _MainTex_ST;
            half _FresnelScale;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURECUBE(_EnvMap);       SAMPLER(sampler_EnvMap);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertexInput.positionCS;
                
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
                output.reflectDirWS = reflect(-output.viewDirWS, output.normalWS);
                
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                half3 normalWS = normalize(input.normalWS);
                half3 viewDirWS = normalize(input.viewDirWS);
                
                Light mainLight = GetMainLight();
                half3 lightDirWS = normalize(mainLight.direction);
                
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo.rgb;
                
                half3 diffuse = mainLight.color.rgb * albedo.rgb * saturate(dot(lightDirWS, normalWS));
                
                half3 reflectColor = SAMPLE_TEXTURECUBE(_EnvMap, sampler_EnvMap, input.reflectDirWS).rgb;
                
                half fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(viewDirWS, normalWS), 5);
                
                half3 col = ambient + lerp(diffuse, reflectColor, saturate(fresnel));
                return half4(col, 1);
            }
            ENDHLSL
            
        }
    }
}

Shader "RoadOfShader/1.9-NPR/Toon"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _Ramp ("Ramp", 2D) = "white" { }
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineWidth ("Outline Width", Range(0, 1)) = 0.2
        _ZOffset ("Z Offset", Float) = -0.5
        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _SpecularThreshold ("Specular Threshold", Range(0, 1)) = 0.4
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        
        UsePass "RoadOfShader/1.9-NPR/Procedural Geometry Silhouette VertexNormal/OUTLINE"
        
        Pass
        {
            Tags { "LightMode" = "SRPDefaultUnlit" }
            
            HLSLPROGRAM
            
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/_Libs/Tools.hlsl"
            
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
                float4 vertex: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 normalWS: TEXCOORD1;
                float3 positionWS: TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _Ramp_ST;
            half4 _SpecularColor;
            half _SpecularThreshold;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            TEXTURE2D(_Ramp);    SAMPLER(sampler_Ramp);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionWS = vertexInput.positionWS;
                output.vertex = vertexInput.positionCS;
                
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                output.uv = input.uv;
                
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
                
                half3 halfDir = normalize(viewDirWS + lightDirWS);
                
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                
                half3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo.rgb;
                
                float diff = Convert01(dot(normalWS, lightDirWS));
                half3 diffuse = mainLight.color * albedo.rgb * SAMPLE_TEXTURE2D(_Ramp, sampler_Ramp, float2(diff, diff)).rgb;  //访问渐变纹理来让漫反射部分是明暗变化的
                
                half spec = dot(normalWS, halfDir);
                //简单实现，但锯齿明显
                // half3 specular = _SpecularColor.rgb * albedo.rgb * step(0, spec - _SpecularThreshold);
                //光滑实现
                // half w = 0.01; //w取一个很小的值即可
                half w = fwidth(spec) * 2.0;
                half3 specular = _SpecularColor.rgb * albedo.rgb * smoothstep(-w, w, spec - _SpecularThreshold);
                
                half4 result = half4(ambient + diffuse + specular, 1);
                return result;
            }
            ENDHLSL
            
        }
    }
}

Shader "RoadOfShader/1.9-NPR/Surface Angle Silhouette"
{
    Properties
    {
        [NoScaleOffset] _MainTex ("Texture", 2D) = "white" { }
        _Outline ("Outline", Range(0, 1)) = 0.3
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
                float3 positionWS: TEXCOORD1;
                float3 normalWS: NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            half _Outline;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            
            half3 SurfaceAngleSilhouette(float3 normal, float3 viewDir)
            {
                float edge = saturate(dot(normal, viewDir));
                edge = edge < _Outline ? edge / 4: 1;
                return edge;
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionWS = vertexInput.positionWS;
                output.vertex = vertexInput.positionCS;
                output.uv = input.uv;
                
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                half3 normalWS = normalize(input.normalWS);
                half3 viewDirWS = normalize(GetCameraPositionWS() - input.positionWS);
                
                half3 edge = SurfaceAngleSilhouette(normalWS, viewDirWS);
                
                half4 col = half4(edge, 1.0);
                return col;
            }
            ENDHLSL
            
        }
    }
}

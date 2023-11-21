Shader "RoadOfShader/2.3-PlaneShadow/Plane Shadow"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }
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

            float4 _CenterPos;
            float _CenterRadius;
            half _ShadowFalloff;
            half _HeightRange;

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

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

                float3 toSphere = _CenterPos.xyz - input.positionWS;
                float sqrDistanceXZ = dot(toSphere.xz, toSphere.xz);

                float yMask = step(toSphere.y, 0) + step(_HeightRange, toSphere.y);

                half atten = (sqrDistanceXZ / _CenterRadius) / _ShadowFalloff;

                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                col *= saturate(atten + yMask);
                return col;
            }
            ENDHLSL

        }
    }
}
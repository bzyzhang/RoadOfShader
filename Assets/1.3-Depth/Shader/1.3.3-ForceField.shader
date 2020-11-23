//https://www.jianshu.com/p/80a932d1f11e

Shader "RoadOfShader/1.3-Depth/Force Field"
{
    Properties
    {
        _MainColor ("Main Color", Color) = (1, 1, 1, 1)
        _RimPower ("Rim Power", Range(0, 1)) = 1
        _IntersectionPower ("Intersect Power", Range(0, 1)) = 0
    }
    
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        
        Pass
        {
            Tags { "LightMode" = "UniversalForward" }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            ZTest LEqual
            
            HLSLPROGRAM
            
            // Required to compile gles 2.0 with standard SRP library
            // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
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
                float eyeZ: TEXCOORD0;
                float4 positionScreen: TEXCOORD1;
                float3 normalWS: NORMAL;
                float3 viewDirWS: TEXCOORD2;
                float4 vertex: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainColor;
            float _RimPower;
            float _IntersectionPower;
            CBUFFER_END
            
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
                
                output.positionScreen = vertexInput.positionNDC;
                output.eyeZ = -vertexInput.positionVS.z;
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float3 normalWS = normalize(input.normalWS);
                float3 viewDirWS = normalize(input.viewDirWS);
                float rim = 1 - saturate(dot(normalWS, viewDirWS)) * _RimPower;
                
                float screenZ = LinearEyeDepth(SampleSceneDepth(input.positionScreen.xy / input.positionScreen.w), _ZBufferParams);
                float intersect = (1 - (screenZ - input.eyeZ)) * _IntersectionPower;
                float v = max(rim, intersect);
                
                half4 finalColor = _MainColor * v;
                
                return finalColor;
            }
            ENDHLSL
            
        }
    }
}

Shader "RoadOfShader/1.9-NPR/Hatching"
{
    Properties
    {
		_OutlineColor("Outline Color", Color) = (0,0,0,1)
		_OutlineWidth("Outline Width", Range(0, 1)) = 0.2
		_ZOffset("Z Offset", Float) = -0.5
		_Tile("Tile", Float) = 8
		_HatchTex0("Hatch Tex 0", 2D) = "white" {}
		_HatchTex1("Hatch Tex 1", 2D) = "white" {}
		_HatchTex2("Hatch Tex 2", 2D) = "white" {}
		_HatchTex3("Hatch Tex 3", 2D) = "white" {}
		_HatchTex4("Hatch Tex 4", 2D) = "white" {}
		_HatchTex5("Hatch Tex 5", 2D) = "white" {}
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
                float3 weights0: TEXCOORD1;
                float4 weights1: TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            half _Tile;
            CBUFFER_END
            
            TEXTURE2D(_HatchTex0);    SAMPLER(sampler_HatchTex0);
            TEXTURE2D(_HatchTex1);    SAMPLER(sampler_HatchTex1);
            TEXTURE2D(_HatchTex2);    SAMPLER(sampler_HatchTex2);
            TEXTURE2D(_HatchTex3);    SAMPLER(sampler_HatchTex3);
            TEXTURE2D(_HatchTex4);    SAMPLER(sampler_HatchTex4);
            TEXTURE2D(_HatchTex5);    SAMPLER(sampler_HatchTex5);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                output.vertex = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv * _Tile;
                
                Light mainLight = GetMainLight();
                half3 lightDirWS = normalize(mainLight.direction);
                half3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                
                half diff = saturate(dot(normalWS, lightDirWS));
                float hatchFactor = diff * 7.0;
                
                output.weights0 = float3(0, 0, 0);
                output.weights1 = float4(0, 0, 0, 1);
                if (hatchFactor > 6.0)
                {
                    //最亮的部分，用留白表示
                }
                else if (hatchFactor > 5.0)
                {
                    output.weights0.x = hatchFactor - 5.0;
                }
                else if(hatchFactor > 4.0)
                {
                    output.weights0.x = hatchFactor - 4.0;
                    output.weights0.y = 1.0 - output.weights0.x;
                }
                else if(hatchFactor > 3.0)
                {
                    output.weights0.y = hatchFactor - 3.0;
                    output.weights0.z = 1 - output.weights0.y;
                }
                else if(hatchFactor > 2.0)
                {
                    output.weights0.z = hatchFactor - 2.0;
                    output.weights1.x = 1 - output.weights0.z;
                }
                else if(hatchFactor > 1.0)
                {
                    output.weights1.x = hatchFactor - 1.0;
                    output.weights1.y = 1 - output.weights1.x;
                }
                else
                {
                    output.weights1.y = hatchFactor;
                    output.weights1.z = 1 - output.weights1.y;
                }
                output.weights1.w = 1 - output.weights0.x - output.weights0.y - output.weights0.z - output.weights1.x - output.weights1.y - output.weights1.z;
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                half4 hatch0 = SAMPLE_TEXTURE2D(_HatchTex0, sampler_HatchTex0, input.uv) * input.weights0.x;
                half4 hatch1 = SAMPLE_TEXTURE2D(_HatchTex1, sampler_HatchTex1, input.uv) * input.weights0.y;
                half4 hatch2 = SAMPLE_TEXTURE2D(_HatchTex2, sampler_HatchTex2, input.uv) * input.weights0.z;
                half4 hatch3 = SAMPLE_TEXTURE2D(_HatchTex3, sampler_HatchTex3, input.uv) * input.weights1.x;
                half4 hatch4 = SAMPLE_TEXTURE2D(_HatchTex4, sampler_HatchTex4, input.uv) * input.weights1.y;
                half4 hatch5 = SAMPLE_TEXTURE2D(_HatchTex5, sampler_HatchTex5, input.uv) * input.weights1.z;
                half4 white = half4(1, 1, 1, 1) * input.weights1.w;
                
                half4 result = hatch0 + hatch1 + hatch2 + hatch3 + hatch4 + hatch5 + white;
                return result;
            }
            ENDHLSL
            
        }
    }
}

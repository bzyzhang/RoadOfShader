Shader "RoadOfShader/1.4-Shape/Polygon"
{
    Properties
    {
		_Num("Num", Int) = 3
		_Size("Size", Range(0, 1)) = 0.5
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
            #include "Assets/_Libs/Tools.hlsl"
            
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
                float4 vertex: SV_POSITION;
                float2 uv: TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            float _Num;
            float _Size;
            CBUFFER_END
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                output.vertex = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
				input.uv = input.uv * 2 - 1; //[-1, 1]，(0,0)在正中心

				float a = atan2(input.uv.x, input.uv.y) + PI; //[0, 2π]，将整个界面变成角度分布（极坐标系）
				float r = (2 * PI) / float(_Num); //一条边对应的角度（中心连接边的两个端点）

				//a / r 相当于将整个界面按照r为单位进行分割，一共N份
				//floor(0.5 + *) 进行四舍五入
				//length(i.uv) 一个渐变的圆
				float d = cos(floor(0.5 + a / r) * r - a) * length(input.uv);
				
				half3 col = 1 - step(_Size, d);
				return half4(col, 1);
            }
            ENDHLSL
            
        }
    }
}

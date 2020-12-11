Shader "RoadOfShader/1.4-Shape/Flower"
{
    Properties
    {
        _Num ("Num", Float) = 5
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
                
                float2 uv = input.uv - 0.5; //[-0.5, 0.5], make (0,0) in the center
                
                float r = length(uv) * 2.0;
                float a = atan2(uv.y, uv.x) * _Num;
                
				float f = abs(cos(a)) * 0.5 + 0.3;
				float cir = Circle(float2(0.5, 0.5), 0.15, input.uv);
				float cir2 = Circle(float2(0.5, 0.5), 0.13, input.uv);

				//1 - cir保证花瓣的函数在中间圆之外执行，step(f, r) * step(r, f + 0.1)描边，(1 - step(f, r)) * fixed3(1, 0, 1)花瓣着色
				half3 col1 = (1 - cir) * (1 - (step(f, r) * step(r, f + 0.1) + (1 - step(f, r)) * half3(1, 0, 1)));
				half3 col2 = (1 - cir2) * cir * half3(1, 0, 1) + cir2 * half3(1, 0, 0);
				half3 col = col1 + col2;
				return half4(col, 1);
            }
            ENDHLSL
            
        }
    }
}

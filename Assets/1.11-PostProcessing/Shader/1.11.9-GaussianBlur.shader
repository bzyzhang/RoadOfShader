Shader "RoadOfShader/1.11-PostProcessing/Gaussian Blur"
{
    Properties
    {
        _BlurSize ("Blur Size", Range(0, 5)) = 1
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        Cull Off
        ZWrite Off
        ZTest Always
        
        HLSLINCLUDE
        
        // Required to compile gles 2.0 with standard SRP library
        // All shaders must be compiled with HLSLcc and currently only gles is not using HLSLcc by default
        #pragma prefer_hlslcc gles
        #pragma exclude_renderers d3d11_9x
        #pragma target 2.0
        
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        
        struct Attributes
        {
            float4 positionOS: POSITION;
            float2 uv: TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };
        
        struct Varyings
        {
            float4 vertex: SV_POSITION;
            float2 uv[5]: TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };
        
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_TexelSize;
        half _BlurSize;
        CBUFFER_END
        
        TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
        
        Varyings vertHorizontal(Attributes input)
        {
            Varyings output = (Varyings)0;
            
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_TRANSFER_INSTANCE_ID(input, output);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            
            output.vertex = TransformObjectToHClip(input.positionOS.xyz);
            float2 uv = input.uv;
            
            //当有多个RenderTarget时，需要自己处理UV翻转问题
            #if UNITY_UV_STARTS_AT_TOP //DirectX之类的
                if (_MainTex_TexelSize.y < 0) //开启了抗锯齿
                uv.y = 1 - uv.y; //满足上面两个条件时uv会翻转，因此需要转回来
            #endif
            
            output.uv[0] = uv;
            output.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            output.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            output.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
            output.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
            
            return output;
        }
        
        Varyings vertVertical(Attributes input)
        {
            Varyings output = (Varyings)0;
            
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_TRANSFER_INSTANCE_ID(input, output);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            
            output.vertex = TransformObjectToHClip(input.positionOS.xyz);
            float2 uv = input.uv;
            
            //当有多个RenderTarget时，需要自己处理UV翻转问题
            #if UNITY_UV_STARTS_AT_TOP //DirectX之类的
                if (_MainTex_TexelSize.y < 0) //开启了抗锯齿
                uv.y = 1 - uv.y; //满足上面两个条件时uv会翻转，因此需要转回来
            #endif
            
            output.uv[0] = uv;
            output.uv[1] = uv + float2(0.0, _MainTex_TexelSize.x * 1.0) * _BlurSize;
            output.uv[2] = uv - float2(0.0, _MainTex_TexelSize.x * 1.0) * _BlurSize;
            output.uv[3] = uv + float2(0.0, _MainTex_TexelSize.x * 2.0) * _BlurSize;
            output.uv[4] = uv - float2(0.0, _MainTex_TexelSize.x * 2.0) * _BlurSize;
            
            return output;
        }
        
        half4 frag(Varyings input): SV_Target
        {
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            
            //高斯核
            float weight[3] = {0.4026, 0.2442, 0.0545};
            
            half3 sum = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[0]).rgb * weight[0];
            
            sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[1]).rgb * weight[1];
            sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[2]).rgb * weight[1];
            sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[3]).rgb * weight[2];
            sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv[4]).rgb * weight[2];
            
            return half4(sum, 1);
        }
        
        ENDHLSL
        
		Pass
		{
			NAME "GAUSSIAN_HOR"
			HLSLPROGRAM
			#pragma vertex vertHorizontal
			#pragma fragment frag
			ENDHLSL
		}

		Pass
		{
			NAME "GAUSSIAN_VERT"
			HLSLPROGRAM
			#pragma vertex vertVertical
			#pragma fragment frag
			ENDHLSL
		}
    }
}

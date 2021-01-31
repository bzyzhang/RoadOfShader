Shader "RoadOfShader/1.11-PostProcessing/Bloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _LuminanceThreshold ("Luminance Threshold", Range(0, 1)) = 0.5
        _BlurSize ("Blur Size", Range(0, 5)) = 2
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
        #include "Assets/_Libs/Tools.hlsl"
        
        struct Attributes
        {
            float4 positionOS: POSITION;
            float2 uv: TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };
        
        struct Varyings_Extract
        {
            float4 vertex: SV_POSITION;
            float2 uv: TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };
        
        struct Varyings_Bloom
        {
            float4 vertex: SV_POSITION;
            float4 uv: TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };
        
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_TexelSize;
        half _LuminanceThreshold;
        half _BlurSize;
        CBUFFER_END
        
        TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
        TEXTURE2D(_BloomTex);    SAMPLER(sampler_BloomTex);
        
        Varyings_Extract vertExtract(Attributes input)
        {
            Varyings_Extract output = (Varyings_Extract)0;
            
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_TRANSFER_INSTANCE_ID(input, output);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            
            output.vertex = TransformObjectToHClip(input.positionOS.xyz);
            output.uv = CorrectUV(input.uv,_MainTex_TexelSize);
            
            return output;
        }
        
        half4 fragExtract(Varyings_Extract input): SV_Target
        {
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            
            half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
            half val = clamp(CustomLuminance(col) - _LuminanceThreshold, 0.0, 1.0);
            return col * val;
        }
        
        Varyings_Bloom vertBloom(Attributes input)
        {
            Varyings_Bloom output = (Varyings_Bloom)0;
            
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_TRANSFER_INSTANCE_ID(input, output);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            
            output.vertex = TransformObjectToHClip(input.positionOS.xyz);
            output.uv.xy = input.uv;
            output.uv.zw = CorrectUV(input.uv, _MainTex_TexelSize);
            
            return output;
        }
        
        half4 fragBloom(Varyings_Bloom input): SV_Target
        {
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            
            return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv.xy) + SAMPLE_TEXTURE2D(_BloomTex, sampler_BloomTex, input.uv.zw);
        }
        
        ENDHLSL
        
		Pass
		{
			HLSLPROGRAM
			#pragma vertex vertExtract
			#pragma fragment fragExtract
			ENDHLSL
		}

		UsePass "RoadOfShader/1.11-PostProcessing/Gaussian Blur/GAUSSIAN_HOR"

		UsePass "RoadOfShader/1.11-PostProcessing/Gaussian Blur/GAUSSIAN_VERT"

		Pass
		{			
			HLSLPROGRAM
			#pragma vertex vertBloom
			#pragma fragment fragBloom
			ENDHLSL
		}
    }
}

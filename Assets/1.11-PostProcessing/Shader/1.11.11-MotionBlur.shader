Shader "RoadOfShader/1.11-PostProcessing/Motion Blur"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        _BlurAmount ("Blur Amount", Float) = 0.5
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
        
        struct Varyings
        {
            float4 vertex: SV_POSITION;
            float2 uv: TEXCOORD0;
            UNITY_VERTEX_INPUT_INSTANCE_ID
            UNITY_VERTEX_OUTPUT_STEREO
        };
        
        CBUFFER_START(UnityPerMaterial)
        float4 _MainTex_TexelSize;
        half _BlurAmount;
        CBUFFER_END
        
        TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
        
        Varyings vert(Attributes input)
        {
            Varyings output = (Varyings)0;
            
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_TRANSFER_INSTANCE_ID(input, output);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            
            output.vertex = TransformObjectToHClip(input.positionOS.xyz);
            output.uv = CorrectUV(input.uv, _MainTex_TexelSize);
            
            return output;
        }
        
        half4 fragRGB(Varyings input): SV_Target
        {
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            
            return half4(SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv).rgb, _BlurAmount);
        }
        
        half4 fragA(Varyings input): SV_Target
        {
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            
            return SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
        }
        
        ENDHLSL
        
		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			ColorMask RGB
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment fragRGB
			ENDHLSL
		}

		Pass
		{
			Blend One Zero
			ColorMask A
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment fragA
			ENDHLSL
		}
    }
}

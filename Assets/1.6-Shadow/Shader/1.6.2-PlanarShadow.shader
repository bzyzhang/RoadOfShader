Shader "RoadOfShader/1.6-Shadow/Planar Shadow"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        
        [Header(Shadow)]
        _GroundHeight ("_GroundHeight", Float) = 0
        _ShadowColor ("_ShadowColor", Color) = (0, 0, 0, 1)
        _ShadowFalloff ("_ShadowFalloff", Range(0, 1)) = 0.05
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" }
        
        //MainColor Pass
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
                float4 vertex: SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END
            
            TEXTURE2D(_MainTex);    SAMPLER(sampler_MainTex);
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                output.vertex = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv);
                return col;
            }
            ENDHLSL
            
        }
        
        //阴影pass
        Pass
        {
            Name "PlanarShadow"
            Tags { "LightMode" = "UniversalForward" }
            
            //用使用模板测试以保证alpha显示正确
            Stencil
            {
                Ref 0
                Comp equal
                Pass incrWrap
                Fail keep
                ZFail keep
            }
            
            Cull Off
            
            //透明混合模式
            Blend SrcAlpha OneMinusSrcAlpha
            
            //关闭深度写入
            ZWrite off
            
            //深度稍微偏移防止阴影与地面穿插
            Offset -1, 0
            
            HLSLPROGRAM
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            #pragma vertex vert
            #pragma fragment frag
            
            struct Attributes
            {
                float4 positionOS: POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 vertex: SV_POSITION;
                float4 color : COLOR;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            CBUFFER_START(UnityPerMaterial)
            half _GroundHeight;
            half4 _ShadowColor;
            half _ShadowFalloff;
            CBUFFER_END
            
            float3 ShadowProjectPos(float3 positionOS)
            {
                float3 positionWS = TransformObjectToWorld(positionOS);
                
                //灯光方向
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                
                //阴影的世界空间坐标（低于地面的部分不做改变）
                float3 shadowPos;
                shadowPos.y = min(positionWS.y, _GroundHeight);
                shadowPos.xz = positionWS.xz - lightDir.xz * max(0, positionWS.y - _GroundHeight) / lightDir.y;
                
                return shadowPos;
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_TRANSFER_INSTANCE_ID(input, output);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                
                //得到阴影的世界空间坐标
                float3 shadowPos = ShadowProjectPos(input.positionOS.xyz);
                
                //转换到裁切空间
                output.vertex = TransformWorldToHClip(shadowPos);
                
                //得到中心点世界坐标
                float3 center = float3(unity_ObjectToWorld[0].w, _GroundHeight, unity_ObjectToWorld[2].w);
                //计算阴影衰减
                float falloff = 1 - saturate(distance(shadowPos, center) * _ShadowFalloff);

                output.color = _ShadowColor;
                output.color.a *= falloff;
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                return input.color;
            }
            ENDHLSL
            
        }
    }
}

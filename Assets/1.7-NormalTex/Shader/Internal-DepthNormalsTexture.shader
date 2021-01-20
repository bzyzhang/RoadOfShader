Shader "RoadOfShader/1.7-NormalTex/Internal-DepthNormalsTexture"
{
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }
        
        Pass
        {
            Name "Depth-Normal"
            
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
            };
            
            struct Varyings
            {
                float4 positionCS: SV_POSITION;
                float4 normal_depth: TEXCOORD0;
            };
            
            // Encoding/decoding view space normals into 2D 0..1 vector
            float2 EncodeViewNormalStereo(float3 n)
            {
                float kScale = 1.7777;
                float2 enc;
                enc = n.xy / (n.z + 1);
                enc /= kScale;
                enc = enc * 0.5 + 0.5;
                return enc;
            }
            
            // Encoding/decoding [0..1) floats into 8 bit/channel RG. Note that 1.0 will not be encoded properly.
            float2 EncodeFloatRG(float v)
            {
                float2 kEncodeMul = float2(1.0, 255.0);
                float kEncodeBit = 1.0 / 255.0;
                float2 enc = kEncodeMul * v;
                enc = frac(enc);
                enc.x -= enc.y * kEncodeBit;
                return enc;
            }
            
            float4 EncodeDepthNormal(float depth, float3 normal)
            {
                float4 enc;
                enc.xy = EncodeViewNormalStereo(normal);
                enc.zw = EncodeFloatRG(depth);
                return enc;
            }
            
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                
                output.positionCS = vertexInput.positionCS;
                output.normal_depth.xyz = mul((float3x3)UNITY_MATRIX_IT_MV, input.normalOS);
                output.normal_depth.w = - (vertexInput.positionVS.z * _ProjectionParams.w);
                
                return output;
            }
            
            half4 frag(Varyings input): SV_Target
            {
                return EncodeDepthNormal(input.normal_depth.w, input.normal_depth.xyz);
            }
            ENDHLSL
            
        }
    }
}

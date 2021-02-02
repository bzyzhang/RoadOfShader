using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class BloomPass : ScriptableRenderPass
    {
        private int m_Iterations = 3;
        private float m_BlurSpread = 0.6f;
        private int m_DownSample = 2;
        private float m_LuminanceThreshold = 0.6f;

        private const int EXTRACT_PASS = 0;
        private const int GAUSSIAN_HOR_PASS = 1;
        private const int GAUSSIAN_VERT_PASS = 2;
        private const int BLOOM_PASS = 3;

        static readonly string k_RenderTag = "Bloom";

        private Material bloomMat;

        private RenderTargetHandle bufferTex0;
        private RenderTargetHandle bufferTex1;

        RenderTargetIdentifier currentTarget;
        private RenderTargetHandle destination { get; set; }

        public BloomPass(int iterations, float blurSpread, int downSample, float luminanceThreshold)
        {
            m_Iterations = iterations;
            m_BlurSpread = blurSpread;
            m_DownSample = downSample;
            m_LuminanceThreshold = luminanceThreshold;

            var shader = Shader.Find("RoadOfShader/1.11-PostProcessing/Bloom");
            bloomMat = CoreUtils.CreateEngineMaterial(shader);

            bufferTex0.Init("_GaussianBlur0");
            bufferTex1.Init("_GaussianBlur1");
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (bloomMat == null)
            {
                UnityEngine.Debug.LogError("材质没找到！");
                return;
            }
            if (!renderingData.cameraData.postProcessEnabled) return;

            var cmd = CommandBufferPool.Get(k_RenderTag);
            Render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        void Render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera) return;

            var source = currentTarget;

            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;

            opaqueDesc.width /= m_DownSample;

            opaqueDesc.height /= m_DownSample;

            opaqueDesc.depthBufferBits = 0;

            cmd.GetTemporaryRT(bufferTex0.id, opaqueDesc, FilterMode.Bilinear);
            cmd.GetTemporaryRT(bufferTex1.id, opaqueDesc, FilterMode.Bilinear);

            bloomMat.SetFloat("_LuminanceThreshold", m_LuminanceThreshold);

            Blit(cmd, source, bufferTex0.Identifier(), bloomMat, EXTRACT_PASS);

            for (int i = 0; i < m_Iterations; i++)
            {
                bloomMat.SetFloat("_BlurSize", 1.0f + i * m_BlurSpread);

                Blit(cmd, bufferTex0.Identifier(), bufferTex1.Identifier(), bloomMat, GAUSSIAN_HOR_PASS);

                Blit(cmd, bufferTex1.Identifier(), bufferTex0.Identifier(), bloomMat, GAUSSIAN_VERT_PASS);
            }

            cmd.SetGlobalTexture("_BloomTex", bufferTex0.Identifier());
            Blit(cmd, source, bufferTex1.Identifier(), bloomMat, BLOOM_PASS);

            Blit(cmd, bufferTex1.Identifier(), source);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            base.FrameCleanup(cmd);

            cmd.ReleaseTemporaryRT(bufferTex0.id);
            cmd.ReleaseTemporaryRT(bufferTex1.id);
        }

        public void Setup(in RenderTargetIdentifier currentTarget, RenderTargetHandle dest)
        {
            this.destination = dest;
            this.currentTarget = currentTarget;
        }
    }
}

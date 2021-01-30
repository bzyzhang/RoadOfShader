using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class GaussianBlurPass : ScriptableRenderPass
    {
        private int m_DownSample = 4;
        private int m_Iterations = 1;

        static readonly string k_RenderTag = "Gaussian Blur";

        private Material gaussianBlurMat;

        private RenderTargetHandle bufferTex0;
        private RenderTargetHandle bufferTex1;

        RenderTargetIdentifier currentTarget;
        private RenderTargetHandle destination { get; set; }

        public GaussianBlurPass(int downSample, int iterations)
        {
            m_DownSample = downSample;
            m_Iterations = iterations;

            var shader = Shader.Find("RoadOfShader/1.11-PostProcessing/Gaussian Blur");
            gaussianBlurMat = CoreUtils.CreateEngineMaterial(shader);

            bufferTex0.Init("_GaussianBlur0");
            bufferTex1.Init("_GaussianBlur1");
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (gaussianBlurMat == null)
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

            Blit(cmd, source, bufferTex0.Identifier());

            for (int i = 0; i < m_Iterations; i++)
            {
                Blit(cmd, bufferTex0.Identifier(), bufferTex1.Identifier(), gaussianBlurMat, 0);

                Blit(cmd, bufferTex1.Identifier(), bufferTex0.Identifier(), gaussianBlurMat, 1);
            }

            Blit(cmd, bufferTex0.Identifier(), source);
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

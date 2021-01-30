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

        private int bufferTex0 = 0;
        private int bufferTex1 = 0;

        RenderTargetIdentifier currentTarget;
        private RenderTargetHandle destination { get; set; }
        private RenderTextureDescriptor m_Descriptor;

        public GaussianBlurPass(int downSample, int iterations)
        {
            m_DownSample = downSample;
            m_Iterations = iterations;

            var shader = Shader.Find("RoadOfShader/1.11-PostProcessing/Gaussian Blur");
            gaussianBlurMat = CoreUtils.CreateEngineMaterial(shader);

            bufferTex0 = Shader.PropertyToID("_GaussianBlur0");
            bufferTex1 = Shader.PropertyToID("_GaussianBlur1");
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

            int w = m_Descriptor.width / m_DownSample;
            int h = m_Descriptor.height / m_DownSample;

            cmd.GetTemporaryRT(bufferTex0, w, h, m_Descriptor.depthBufferBits, FilterMode.Bilinear);
            cmd.GetTemporaryRT(bufferTex1, w, h, m_Descriptor.depthBufferBits, FilterMode.Bilinear);

            cmd.SetGlobalTexture("_MainTex", source);
            Blit(cmd, source, bufferTex0);

            for (int i = 0; i < m_Iterations; i++)
            {
                cmd.SetGlobalTexture("_MainTex", bufferTex0);
                Blit(cmd, bufferTex0, bufferTex1, gaussianBlurMat, 0);

                cmd.SetGlobalTexture("_MainTex", bufferTex1);
                Blit(cmd, bufferTex1, bufferTex0, gaussianBlurMat, 1);
            }

            cmd.ReleaseTemporaryRT(bufferTex1);

            Blit(cmd, bufferTex0, destination.Identifier());

            cmd.ReleaseTemporaryRT(bufferTex0);
        }

        public void Setup(in RenderTargetIdentifier currentTarget, RenderTargetHandle dest, RenderTextureDescriptor descriptor)
        {
            this.destination = dest;
            this.currentTarget = currentTarget;
            this.m_Descriptor = descriptor;
        }
    }
}

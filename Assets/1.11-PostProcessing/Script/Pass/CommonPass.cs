using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class CommonPass : ScriptableRenderPass
    {
        static readonly string k_RenderTag = "Common PostProcessing";

        private Material m_Material;

        RenderTargetIdentifier currentTarget;
        private RenderTargetHandle destination { get; set; }

        private RenderTargetHandle m_TemporaryColorTexture;

        public CommonPass(Material material)
        {
            m_Material = material;

            m_TemporaryColorTexture.Init("_TemporaryColorTexture");
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (m_Material == null)
            {
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

            cmd.GetTemporaryRT(m_TemporaryColorTexture.id, renderingData.cameraData.cameraTargetDescriptor, FilterMode.Bilinear);

            var source = currentTarget;

            cmd.Blit(source, destination.Identifier(), m_Material);
        }

        public override void FrameCleanup(CommandBuffer cmd)
        {
            base.FrameCleanup(cmd);

            cmd.ReleaseTemporaryRT(m_TemporaryColorTexture.id);
        }

        public void Setup(in RenderTargetIdentifier currentTarget, RenderTargetHandle dest)
        {
            this.destination = dest;
            this.currentTarget = currentTarget;
        }
    }
}
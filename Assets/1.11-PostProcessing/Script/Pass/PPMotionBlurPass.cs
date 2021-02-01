using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class PPMotionBlurPass : ScriptableRenderPass
    {
        static readonly string k_RenderTag = "PP Motion Blur";

        private float m_BlurAmount = 0.5f;

        private Material m_Material;

        RenderTargetIdentifier currentTarget;
        private RenderTargetHandle destination { get; set; }

        private RenderTexture m_LastRT;

        public PPMotionBlurPass(float blurAmount)
        {
            m_BlurAmount = blurAmount;

            var shader = Shader.Find("RoadOfShader/1.11-PostProcessing/Motion Blur");
            m_Material = CoreUtils.CreateEngineMaterial(shader);
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

            var source = currentTarget;

            if (m_LastRT == null || m_LastRT.width != renderingData.cameraData.cameraTargetDescriptor.width || m_LastRT.height != renderingData.cameraData.cameraTargetDescriptor.height)
            {
                Object.DestroyImmediate(m_LastRT);
                m_LastRT = new RenderTexture(renderingData.cameraData.cameraTargetDescriptor);
                m_LastRT.hideFlags = HideFlags.HideAndDontSave;
                Blit(cmd, source, m_LastRT);
                return;
            }

            m_LastRT.MarkRestoreExpected();

            m_Material.SetFloat("_BlurAmount",m_BlurAmount);

            Blit(cmd, source, m_LastRT, m_Material);
            Blit(cmd, m_LastRT, source);
        }

        public void Setup(in RenderTargetIdentifier currentTarget, RenderTargetHandle dest)
        {
            this.destination = dest;
            this.currentTarget = currentTarget;
        }
    }
}
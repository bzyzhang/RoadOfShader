using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class PPMotionBlurPass : ScriptableRenderPass
    {
        static readonly string k_RenderTag = "PP Motion Blur";

        private Material m_Material;

        RenderTargetIdentifier currentTarget;
        private RenderTargetHandle destination { get; set; }

        private RenderTexture m_LastRT;

        public PPMotionBlurPass(Material material)
        {
            m_Material = material;
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
                cmd.ReleaseTemporaryRT(m_LastRT.GetNativeTextureID());
                m_LastRT = new RenderTexture(renderingData.cameraData.cameraTargetDescriptor.width, renderingData.cameraData.cameraTargetDescriptor.height, 0);
                m_LastRT.hideFlags = HideFlags.HideAndDontSave; //渲染纹理完全由我们脚本控制，Unity不用插手
                Blit(cmd,source, m_LastRT);
            }

            m_LastRT.MarkRestoreExpected(); //告诉Unity上一帧的纹理不需要清理
            Blit(cmd,source, m_LastRT, m_Material);
            Blit(cmd,m_LastRT, source);
        }

        public void Setup(in RenderTargetIdentifier currentTarget, RenderTargetHandle dest)
        {
            this.destination = dest;
            this.currentTarget = currentTarget;
        }
    }
}
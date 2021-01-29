using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class CommonPass : ScriptableRenderPass
    {
        static readonly string k_RenderTag = "Common";

        private Material m_Material;

        RenderTargetIdentifier currentTarget;
        private RenderTargetHandle destination { get; set; }

        public CommonPass(Material material)
        {
            m_Material = material;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (m_Material == null)
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

            Blit(cmd, source, destination.Identifier(), m_Material);
        }

        public void Setup(in RenderTargetIdentifier currentTarget, RenderTargetHandle dest)
        {
            this.destination = dest;
            this.currentTarget = currentTarget;
        }
    }
}
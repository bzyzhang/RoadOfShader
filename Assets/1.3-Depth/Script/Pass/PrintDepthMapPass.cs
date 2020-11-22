using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class PrintDepthMapPass : ScriptableRenderPass
    {
        static readonly string k_RenderTag = "Print Depth Map";

        private PrintDepthMap printDepthMap;
        private Material depthMapMat;

        RenderTargetIdentifier currentTarget;
        private RenderTargetHandle destination { get; set; }

        public PrintDepthMapPass()
        {
            var shader = Shader.Find("RoadOfShader/1.3-Depth/Print Depth Map");
            depthMapMat = CoreUtils.CreateEngineMaterial(shader);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (depthMapMat == null)
            {
                UnityEngine.Debug.LogError("材质没找到！");
                return;
            }
            if (!renderingData.cameraData.postProcessEnabled) return;
            //通过队列来找到HologramBlock组件，然后
            var stack = VolumeManager.instance.stack;
            printDepthMap = stack.GetComponent<PrintDepthMap>();
            if (printDepthMap == null) { return; }
            if (!printDepthMap.IsActive()) return;

            var cmd = CommandBufferPool.Get(k_RenderTag);
            Render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        void Render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera) return;
            var source = currentTarget;

            Blit(cmd, source, destination.Identifier(), depthMapMat);
        }

        public void Setup(in RenderTargetIdentifier currentTarget, RenderTargetHandle dest)
        {
            this.destination = dest;
            this.currentTarget = currentTarget;
        }
    }
}
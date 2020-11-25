using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class EdgeDetectionPass : ScriptableRenderPass
    {
        static readonly string k_RenderTag = "Edge Detection";

        private EdgeDetection edgeDetection;
        private Material edgeDetectionMat;

        RenderTargetIdentifier currentTarget;
        private RenderTargetHandle destination { get; set; }

        public EdgeDetectionPass()
        {
            var shader = Shader.Find("RoadOfShader/1.3-Depth/Edge Detection");
            edgeDetectionMat = CoreUtils.CreateEngineMaterial(shader);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (edgeDetectionMat == null)
            {
                UnityEngine.Debug.LogError("材质没找到！");
                return;
            }
            if (!renderingData.cameraData.postProcessEnabled) return;
            //通过队列来找到HologramBlock组件，然后
            var stack = VolumeManager.instance.stack;
            edgeDetection = stack.GetComponent<EdgeDetection>();
            if (edgeDetection == null) { return; }
            if (!edgeDetection.IsActive()) return;

            var cmd = CommandBufferPool.Get(k_RenderTag);
            Render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        void Render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera) return;

            var edgeThreshold = edgeDetection.EdgeThreshold.value;
            edgeDetectionMat.SetFloat("_EdgeThreshold", edgeThreshold);

            var source = currentTarget;

            Blit(cmd, source, destination.Identifier(), edgeDetectionMat);
        }

        public void Setup(in RenderTargetIdentifier currentTarget, RenderTargetHandle dest)
        {
            this.destination = dest;
            this.currentTarget = currentTarget;
        }
    }
}
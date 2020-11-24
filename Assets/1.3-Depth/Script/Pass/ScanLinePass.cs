using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class ScanLinePass : ScriptableRenderPass
    {
        static readonly string k_RenderTag = "Scan Line";

        private ScanLine scanLine;
        private Material scanLineMat;

        RenderTargetIdentifier currentTarget;
        private RenderTargetHandle destination { get; set; }

        public ScanLinePass()
        {
            var shader = Shader.Find("RoadOfShader/1.3-Depth/Scan Line");
            scanLineMat = CoreUtils.CreateEngineMaterial(shader);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (scanLineMat == null)
            {
                UnityEngine.Debug.LogError("材质没找到！");
                return;
            }
            if (!renderingData.cameraData.postProcessEnabled) return;
            //通过队列来找到HologramBlock组件，然后
            var stack = VolumeManager.instance.stack;
            scanLine = stack.GetComponent<ScanLine>();
            if (scanLine == null) { return; }
            if (!scanLine.IsActive()) return;

            var cmd = CommandBufferPool.Get(k_RenderTag);
            Render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        void Render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera) return;

            var lineColor = scanLine.LineColor.value.linear;
            var lineWidth = scanLine.LineWidth.value;
            var curValue = scanLine.CurValue.value;
            scanLineMat.SetColor("_LineColor", lineColor);
            scanLineMat.SetFloat("_LineWidth", lineWidth);
            scanLineMat.SetFloat("_CurValue", curValue);

            var source = currentTarget;

            Blit(cmd, source, destination.Identifier(), scanLineMat);
        }

        public void Setup(in RenderTargetIdentifier currentTarget, RenderTargetHandle dest)
        {
            this.destination = dest;
            this.currentTarget = currentTarget;
        }
    }
}
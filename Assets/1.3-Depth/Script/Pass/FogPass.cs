using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class FogPass : ScriptableRenderPass
    {
        static readonly string k_RenderTag = "Fog";

        private Fog fog;
        private Material fogMat;

        RenderTargetIdentifier currentTarget;
        private RenderTargetHandle destination { get; set; }

        public FogPass()
        {
            var shader = Shader.Find("RoadOfShader/1.3-Depth/Fog");
            fogMat = CoreUtils.CreateEngineMaterial(shader);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (fogMat == null)
            {
                UnityEngine.Debug.LogError("材质没找到！");
                return;
            }
            if (!renderingData.cameraData.postProcessEnabled) return;
            //通过队列来找到HologramBlock组件，然后
            var stack = VolumeManager.instance.stack;
            fog = stack.GetComponent<Fog>();
            if (fog == null) { return; }
            if (!fog.IsActive()) return;

            var cmd = CommandBufferPool.Get(k_RenderTag);
            Render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        void Render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera) return;

            var fogColor = fog.fogColor.value.linear;
            var fogDensity = fog.fogDensity.value;
            fogMat.SetColor("_FogColor", fogColor);
            fogMat.SetFloat("_FogDensity", fogDensity);

            var source = currentTarget;

            Blit(cmd, source, destination.Identifier(), fogMat);
        }

        public void Setup(in RenderTargetIdentifier currentTarget, RenderTargetHandle dest)
        {
            this.destination = dest;
            this.currentTarget = currentTarget;
        }
    }
}
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class DisplayNormalTexturePass : ScriptableRenderPass
    {
        static readonly string k_RenderTag = "Display Normal Texture";

        private Material normalTextureMat;

        RenderTargetIdentifier currentTarget;
        private RenderTargetHandle destination { get; set; }

        public DisplayNormalTexturePass()
        {
            var shader = Shader.Find("RoadOfShader/1.7-NormalTex/Display Normal Texture");
            normalTextureMat = CoreUtils.CreateEngineMaterial(shader);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (normalTextureMat == null)
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

            Blit(cmd, source, destination.Identifier(), normalTextureMat);
        }

        public void Setup(in RenderTargetIdentifier currentTarget, RenderTargetHandle dest)
        {
            this.destination = dest;
            this.currentTarget = currentTarget;
        }
    }
}
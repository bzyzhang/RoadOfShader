using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class CustomDepthOfFieldPass : ScriptableRenderPass
    {
        static readonly string k_RenderTag = "Custom Depth Of Field";

        private CustomDepthOfField customDepthOfField;
        private Material simpleBlurMat;
        private Material customDepthOfFieldMat;

        private int blurTex = 0;

        RenderTargetIdentifier currentTarget;
        private RenderTargetHandle destination { get; set; }

        private RenderTextureDescriptor m_Descriptor;

        public CustomDepthOfFieldPass()
        {
            var simpleBlurShader = Shader.Find("RoadOfShader/1.3-Depth/Simple Blur");
            simpleBlurMat = CoreUtils.CreateEngineMaterial(simpleBlurShader);

            var customDepthOfFieldShader = Shader.Find("RoadOfShader/1.3-Depth/Custom Depth Of Field");
            customDepthOfFieldMat = CoreUtils.CreateEngineMaterial(customDepthOfFieldShader);

            blurTex = Shader.PropertyToID("_BlurTex");
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (simpleBlurMat == null || customDepthOfFieldMat == null)
            {
                UnityEngine.Debug.LogError("材质没找到！");
                return;
            }
            if (!renderingData.cameraData.postProcessEnabled) return;
            //通过队列来找到HologramBlock组件，然后
            var stack = VolumeManager.instance.stack;
            customDepthOfField = stack.GetComponent<CustomDepthOfField>();
            if (customDepthOfField == null) { return; }
            if (!customDepthOfField.IsActive()) return;

            var cmd = CommandBufferPool.Get(k_RenderTag);
            Render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        void Render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera) return;

            var source = currentTarget;

            cmd.GetTemporaryRT(blurTex, m_Descriptor, FilterMode.Bilinear);

            var blurLevel = customDepthOfField._BlurLevel.value;
            simpleBlurMat.SetFloat("_BlurLevel", blurLevel);
            Blit(cmd, source, blurTex, simpleBlurMat);
            cmd.SetGlobalTexture(blurTex, blurTex);

            var focusDistance = customDepthOfField.FocusDistance.value;
            var focusLevel = customDepthOfField.FocusLevel.value;
            customDepthOfFieldMat.SetFloat("_FocusDistance", focusDistance);
            customDepthOfFieldMat.SetFloat("_FocusLevel", focusLevel);

            Blit(cmd, source, destination.Identifier(), customDepthOfFieldMat);

            cmd.ReleaseTemporaryRT(blurTex);
        }

        public void Setup(in RenderTargetIdentifier currentTarget, RenderTargetHandle dest, RenderTextureDescriptor descriptor)
        {
            this.destination = dest;
            this.currentTarget = currentTarget;
            this.m_Descriptor = descriptor;
        }
    }
}
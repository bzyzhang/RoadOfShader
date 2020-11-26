using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class CustomMotionBlurPass : ScriptableRenderPass
    {
        static readonly string k_RenderTag = "Custom Motion Blur";

        private CustomMotionBlur customMotionBlur;
        private Material customMotionBlurMat;

        private bool mFirstTime = true;

        private Matrix4x4 mLastVP;

        RenderTargetIdentifier currentTarget;
        private RenderTargetHandle destination { get; set; }

        public CustomMotionBlurPass()
        {
            var shader = Shader.Find("RoadOfShader/1.3-Depth/Custom Motion Blur");
            customMotionBlurMat = CoreUtils.CreateEngineMaterial(shader);

            mFirstTime = true;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (customMotionBlurMat == null)
            {
                UnityEngine.Debug.LogError("材质没找到！");
                return;
            }
            if (!renderingData.cameraData.postProcessEnabled) return;
            //通过队列来找到HologramBlock组件，然后
            var stack = VolumeManager.instance.stack;
            customMotionBlur = stack.GetComponent<CustomMotionBlur>();
            if (customMotionBlur == null) { return; }
            if (!customMotionBlur.IsActive()) return;

            var cmd = CommandBufferPool.Get(k_RenderTag);
            Render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);

            mFirstTime = false;
        }

        void Render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera) return;

            var camera = renderingData.cameraData.camera;
            var proj = camera.projectionMatrix;
            var view = camera.worldToCameraMatrix;
            var viewProj = proj * view;

            customMotionBlurMat.SetMatrix("_CurrentInverseVP", viewProj.inverse);

            if (mFirstTime)
                customMotionBlurMat.SetMatrix("_LastVP", viewProj);
            else
                customMotionBlurMat.SetMatrix("_LastVP", mLastVP);

            var source = currentTarget;

            Blit(cmd, source, destination.Identifier(), customMotionBlurMat);

            mLastVP = viewProj;
        }

        public void Setup(in RenderTargetIdentifier currentTarget, RenderTargetHandle dest)
        {
            this.destination = dest;
            this.currentTarget = currentTarget;
        }
    }
}
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class VerticalFogPass : ScriptableRenderPass
    {
        static readonly string k_RenderTag = "Vertical Fog";

        private VerticalFog verticalFog;
        private Material verticalFogMat;

        RenderTargetIdentifier currentTarget;
        private RenderTargetHandle destination { get; set; }

        public VerticalFogPass()
        {
            var shader = Shader.Find("RoadOfShader/1.3-Depth/Vertical Fog");
            verticalFogMat = CoreUtils.CreateEngineMaterial(shader);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (verticalFogMat == null)
            {
                UnityEngine.Debug.LogError("材质没找到！");
                return;
            }
            if (!renderingData.cameraData.postProcessEnabled) return;
            //通过队列来找到HologramBlock组件，然后
            var stack = VolumeManager.instance.stack;
            verticalFog = stack.GetComponent<VerticalFog>();
            if (verticalFog == null) { return; }
            if (!verticalFog.IsActive()) return;

            var cmd = CommandBufferPool.Get(k_RenderTag);
            Render(cmd, ref renderingData);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        void Render(CommandBuffer cmd, ref RenderingData renderingData)
        {
            if (renderingData.cameraData.isSceneViewCamera) return;

            Camera cam = renderingData.cameraData.camera;
            float tanHalfFOV = Mathf.Tan(0.5f * cam.fieldOfView * Mathf.Deg2Rad);
            float halfHeight = tanHalfFOV * cam.nearClipPlane;
            float halfWidth = halfHeight * cam.aspect;
            Vector3 toTop = cam.transform.up * halfHeight;
            Vector3 toRight = cam.transform.right * halfWidth;
            Vector3 forward = cam.transform.forward * cam.nearClipPlane;
            Vector3 toTopLeft = forward + toTop - toRight;
            Vector3 toBottomLeft = forward - toTop - toRight;
            Vector3 toTopRight = forward + toTop + toRight;
            Vector3 toBottomRight = forward - toTop + toRight;

            toTopLeft /= cam.nearClipPlane;
            toBottomLeft /= cam.nearClipPlane;
            toTopRight /= cam.nearClipPlane;
            toBottomRight /= cam.nearClipPlane;

            Matrix4x4 frustumDir = Matrix4x4.identity;
            frustumDir.SetRow(0, toBottomLeft);
            frustumDir.SetRow(1, toBottomRight);
            frustumDir.SetRow(2, toTopLeft);
            frustumDir.SetRow(3, toTopRight);
            verticalFogMat.SetMatrix("_FrustumDir", frustumDir);

            var fogColor = verticalFog.FogColor.value.linear;
            var fogDensity = verticalFog.FogDensity.value;
            var startY = verticalFog.StartY.value;
            var endY = verticalFog.EndY.value;
            verticalFogMat.SetColor("_FogColor", fogColor);
            verticalFogMat.SetFloat("_FogDensity", fogDensity);
            verticalFogMat.SetFloat("_StartY", startY);
            verticalFogMat.SetFloat("_EndY", endY);

            var source = currentTarget;

            Blit(cmd, source, destination.Identifier(), verticalFogMat);
        }

        public void Setup(in RenderTargetIdentifier currentTarget, RenderTargetHandle dest)
        {
            this.destination = dest;
            this.currentTarget = currentTarget;
        }
    }
}
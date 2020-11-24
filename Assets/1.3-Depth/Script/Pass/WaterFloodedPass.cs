using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Experiemntal.Rendering.Universal
{
    public class WaterFloodedPass : ScriptableRenderPass
    {
        static readonly string k_RenderTag = "Water Flooded";

        private WaterFlooded waterFlooded;
        private Material waterFloodedMat;

        RenderTargetIdentifier currentTarget;
        private RenderTargetHandle destination { get; set; }

        public WaterFloodedPass()
        {
            var shader = Shader.Find("RoadOfShader/1.3-Depth/Water Flooded");
            waterFloodedMat = CoreUtils.CreateEngineMaterial(shader);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (waterFloodedMat == null)
            {
                UnityEngine.Debug.LogError("材质没找到！");
                return;
            }
            if (!renderingData.cameraData.postProcessEnabled) return;
            //通过队列来找到HologramBlock组件，然后
            var stack = VolumeManager.instance.stack;
            waterFlooded = stack.GetComponent<WaterFlooded>();
            if (waterFlooded == null) { return; }
            if (!waterFlooded.IsActive()) return;

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
            waterFloodedMat.SetMatrix("_FrustumDir", frustumDir);

            var waterColor = waterFlooded.WaterColor.value.linear;
            var waterHeight = waterFlooded.WaterHeight.value;
            waterFloodedMat.SetColor("_WaterColor", waterColor);
            waterFloodedMat.SetFloat("_WaterHeight", waterHeight);

            var source = currentTarget;

            Blit(cmd, source, destination.Identifier(), waterFloodedMat);
        }

        public void Setup(in RenderTargetIdentifier currentTarget, RenderTargetHandle dest)
        {
            this.destination = dest;
            this.currentTarget = currentTarget;
        }
    }
}
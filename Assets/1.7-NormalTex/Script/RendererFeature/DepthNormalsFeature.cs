using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DepthNormalsFeature : ScriptableRendererFeature
{
    DepthNormalsPass depthNormalsPass;
    RenderTargetHandle depthNormalsTexture;
    Material depthNormalsMaterial;

    public override void Create()
    {
        depthNormalsMaterial = CoreUtils.CreateEngineMaterial("RoadOfShader/1.7-NormalTex/Internal-DepthNormalsTexture");
        depthNormalsPass = new DepthNormalsPass(RenderQueueRange.opaque, -1, depthNormalsMaterial)
        {
            renderPassEvent = RenderPassEvent.AfterRenderingPrePasses
        };
        depthNormalsTexture.Init("_CameraDepthNormalsTexture");
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        depthNormalsPass.Setup(renderingData.cameraData.cameraTargetDescriptor, depthNormalsTexture);
        renderer.EnqueuePass(depthNormalsPass);
    }
}
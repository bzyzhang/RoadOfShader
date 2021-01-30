using UnityEngine.Experiemntal.Rendering.Universal;
using UnityEngine.Rendering.Universal;

public class GaussianBlurRendererFeature : ScriptableRendererFeature
{
    public int downSample = 4;
    public int iterations = 4;

    GaussianBlurPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new GaussianBlurPass(downSample, iterations);
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var dest = RenderTargetHandle.CameraTarget;
        m_ScriptablePass.Setup(renderer.cameraColorTarget, dest, renderingData.cameraData.cameraTargetDescriptor);
        renderer.EnqueuePass(m_ScriptablePass);
    }
}

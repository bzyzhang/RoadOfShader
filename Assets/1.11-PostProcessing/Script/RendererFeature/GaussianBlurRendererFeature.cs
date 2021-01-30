using UnityEngine.Experiemntal.Rendering.Universal;
using UnityEngine.Rendering.Universal;

public class GaussianBlurRendererFeature : ScriptableRendererFeature
{
    public int downSample = 4;
    public int iterations = 4;
    public RenderPassEvent PassEvent = RenderPassEvent.BeforeRenderingPostProcessing;

    GaussianBlurPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new GaussianBlurPass(downSample, iterations)
        {
            renderPassEvent = PassEvent
        };
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var dest = RenderTargetHandle.CameraTarget;
        m_ScriptablePass.Setup(renderer.cameraColorTarget, dest);
        renderer.EnqueuePass(m_ScriptablePass);
    }
}

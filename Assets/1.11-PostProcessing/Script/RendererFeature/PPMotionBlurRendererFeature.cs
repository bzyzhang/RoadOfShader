using UnityEngine.Experiemntal.Rendering.Universal;
using UnityEngine.Rendering.Universal;

public class PPMotionBlurRendererFeature : ScriptableRendererFeature
{
    public RenderPassEvent PassEvent = RenderPassEvent.BeforeRenderingPostProcessing;

    PPMotionBlurPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new PPMotionBlurPass()
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

using UnityEngine.Experiemntal.Rendering.Universal;
using UnityEngine.Rendering.Universal;

public class CustomMotionBlurRendererFeature : ScriptableRendererFeature
{
    CustomMotionBlurPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new CustomMotionBlurPass();
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var dest = RenderTargetHandle.CameraTarget;
        m_ScriptablePass.Setup(renderer.cameraColorTarget, dest);
        renderer.EnqueuePass(m_ScriptablePass);
    }
}

using UnityEngine.Experiemntal.Rendering.Universal;
using UnityEngine.Rendering.Universal;

public class CustomDepthOfFieldRendererFeature : ScriptableRendererFeature
{
    CustomDepthOfFieldPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new CustomDepthOfFieldPass();
        m_ScriptablePass.renderPassEvent = RenderPassEvent.AfterRenderingPostProcessing;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        var dest = RenderTargetHandle.CameraTarget;
        m_ScriptablePass.Setup(renderer.cameraColorTarget, dest, renderingData.cameraData.cameraTargetDescriptor);
        renderer.EnqueuePass(m_ScriptablePass);
    }
}

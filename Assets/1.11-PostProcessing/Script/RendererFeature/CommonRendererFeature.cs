using UnityEngine;
using UnityEngine.Experiemntal.Rendering.Universal;
using UnityEngine.Rendering.Universal;

public class CommonRendererFeature : ScriptableRendererFeature
{
    public Material UsedMaterial;
    public RenderPassEvent PassEvent = RenderPassEvent.BeforeRenderingPostProcessing;

    CommonPass m_ScriptablePass;

    RenderTargetHandle m_CameraColorAttachment;

    public override void Create()
    {
        m_ScriptablePass = new CommonPass(UsedMaterial)
        {
            renderPassEvent = PassEvent
        };

        m_CameraColorAttachment.Init("_CameraColorTexture");
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        m_ScriptablePass.Setup(renderer.cameraColorTarget, m_CameraColorAttachment);
        renderer.EnqueuePass(m_ScriptablePass);
    }
}

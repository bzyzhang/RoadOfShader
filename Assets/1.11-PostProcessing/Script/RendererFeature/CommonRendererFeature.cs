using UnityEngine;
using UnityEngine.Experiemntal.Rendering.Universal;
using UnityEngine.Rendering.Universal;

public class CommonRendererFeature : ScriptableRendererFeature
{
    public Material UsedMaterial;
    public RenderPassEvent PassEvent = RenderPassEvent.BeforeRenderingPostProcessing;

    CommonPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new CommonPass(UsedMaterial)
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

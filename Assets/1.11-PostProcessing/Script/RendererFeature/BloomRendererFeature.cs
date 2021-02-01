﻿using UnityEngine.Experiemntal.Rendering.Universal;
using UnityEngine.Rendering.Universal;

public class BloomRendererFeature : ScriptableRendererFeature
{
    public int downSample = 4;
    public int iterations = 4;
    public float luminanceThreshold = 0.5f;
    public int blurSize = 2;
    public RenderPassEvent PassEvent = RenderPassEvent.BeforeRenderingPostProcessing;

    BloomPass m_ScriptablePass;

    public override void Create()
    {
        m_ScriptablePass = new BloomPass(downSample, iterations, luminanceThreshold, blurSize)
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
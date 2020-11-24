using System;

namespace UnityEngine.Rendering.Universal
{
    [Serializable, VolumeComponentMenu("Custom Post-processing/Scan Line")]
    public sealed class ScanLine : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("是否开启效果")]
        public BoolParameter enableEffect = new BoolParameter(false);
        [Tooltip("扫描线颜色")]
        public ColorParameter LineColor = new ColorParameter(new Color(0, 0.8f, 0.2f, 1), false, false, true);
        [Tooltip("扫描线宽度")]
        public ClampedFloatParameter LineWidth = new ClampedFloatParameter(0.05f, 0, 0.08f);
        [Tooltip("扫描线深度")]
        public ClampedFloatParameter CurValue = new ClampedFloatParameter(0, 0, 0.9f);

        public bool IsActive() => enableEffect == true;

        public bool IsTileCompatible() => false;
    }
}

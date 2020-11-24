using System;

namespace UnityEngine.Rendering.Universal
{
    [Serializable, VolumeComponentMenu("Custom Post-processing/Vertical Fog")]
    public sealed class VerticalFog : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("是否开启效果")]
        public BoolParameter enableEffect = new BoolParameter(false);
        [Tooltip("雾颜色")]
        public ColorParameter FogColor = new ColorParameter(new Color(0, 0, 0.8f, 1), false, true, true);
        [Tooltip("雾强度")]
        public FloatParameter FogDensity = new FloatParameter(1.0f);
        [Tooltip("开始高度")]
        public FloatParameter StartY = new FloatParameter(0.0f);
        [Tooltip("结束高度")]
        public FloatParameter EndY = new FloatParameter(10.0f);

        public bool IsActive() => enableEffect == true;

        public bool IsTileCompatible() => false;
    }
}

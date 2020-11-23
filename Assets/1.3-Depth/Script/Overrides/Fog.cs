using System;

namespace UnityEngine.Rendering.Universal
{
    [Serializable, VolumeComponentMenu("Custom Post-processing/Fog")]
    public sealed class Fog : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("是否开启效果")]
        public BoolParameter enableEffect = new BoolParameter(false);
        [Tooltip("雾效颜色")]
        public ColorParameter fogColor = new ColorParameter(Color.white, false, false, true);
        [Tooltip("雾效浓度")]
        public FloatParameter fogDensity = new FloatParameter(1.0f);

        public bool IsActive() => enableEffect == true;

        public bool IsTileCompatible() => false;
    }
}

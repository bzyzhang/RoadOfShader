using System;

namespace UnityEngine.Rendering.Universal
{
    [Serializable, VolumeComponentMenu("Custom Post-processing/Water Flooded")]
    public sealed class WaterFlooded : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("是否开启效果")]
        public BoolParameter enableEffect = new BoolParameter(false);
        [Tooltip("水颜色")]
        public ColorParameter WaterColor = new ColorParameter(new Color(0, 0, 0.8f, 1), false, true, true);
        [Tooltip("水深度")]
        public FloatParameter WaterHeight = new FloatParameter(1.0f);

        public bool IsActive() => enableEffect == true;

        public bool IsTileCompatible() => false;
    }
}

using System;

namespace UnityEngine.Rendering.Universal
{
    [Serializable, VolumeComponentMenu("Custom Post-processing/Custom Depth Of Field")]
    public sealed class CustomDepthOfField : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("是否开启效果")]
        public BoolParameter enableEffect = new BoolParameter(false);
        [Tooltip("模糊程度")]
        public FloatParameter _BlurLevel = new FloatParameter(1);
        [Tooltip("聚焦范围")]
        public ClampedFloatParameter FocusDistance = new ClampedFloatParameter(0, 0, 1.0f);
        [Tooltip("聚焦程度")]
        public FloatParameter FocusLevel = new FloatParameter(3.0f);

        public bool IsActive() => enableEffect == true;

        public bool IsTileCompatible() => false;
    }
}

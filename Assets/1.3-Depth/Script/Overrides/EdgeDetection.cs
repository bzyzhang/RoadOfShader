using System;

namespace UnityEngine.Rendering.Universal
{
    [Serializable, VolumeComponentMenu("Custom Post-processing/Edge Detection")]
    public sealed class EdgeDetection : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("是否开启效果")]
        public BoolParameter enableEffect = new BoolParameter(false);
        [Tooltip("边缘检测阈值")]
        public ClampedFloatParameter EdgeThreshold = new ClampedFloatParameter(0, 0.001f, 1.0f);

        public bool IsActive() => enableEffect == true;

        public bool IsTileCompatible() => false;
    }
}

using System;

namespace UnityEngine.Rendering.Universal
{
    [Serializable, VolumeComponentMenu("Custom Post-processing/Custom Motion Blur")]
    public sealed class CustomMotionBlur : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("是否开启效果")]
        public BoolParameter enableEffect = new BoolParameter(false);

        public bool IsActive() => enableEffect == true;

        public bool IsTileCompatible() => false;
    }
}

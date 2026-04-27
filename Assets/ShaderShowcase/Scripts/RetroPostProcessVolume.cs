using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace ShaderShowcase
{
    [Serializable]
    [VolumeComponentMenu("Shader Showcase/Retro Post Process")]
    public class RetroPostProcessVolume : VolumeComponent, IPostProcessComponent
    {
        public BoolParameter enableEffect = new BoolParameter(false);
        public ClampedFloatParameter chromatic = new ClampedFloatParameter(1.6f, 0f, 6f);
        public ClampedFloatParameter scanlineIntensity = new ClampedFloatParameter(0.22f, 0f, 1f);
        public MinFloatParameter scanlineCount = new MinFloatParameter(220f, 1f);
        public ClampedFloatParameter vignetteIntensity = new ClampedFloatParameter(0.55f, 0f, 2f);
        public ClampedFloatParameter vignetteSmoothness = new ClampedFloatParameter(0.62f, 0f, 1f);
        public ClampedFloatParameter saturation = new ClampedFloatParameter(1.18f, 0f, 2f);
        public ClampedFloatParameter contrast = new ClampedFloatParameter(1.06f, 0f, 2f);
        public ClampedFloatParameter exposure = new ClampedFloatParameter(1.05f, 0f, 2f);
        public ClampedFloatParameter noise = new ClampedFloatParameter(0.05f, 0f, 0.5f);
        public ClampedFloatParameter curvature = new ClampedFloatParameter(0.045f, 0f, 0.5f);
        public ClampedFloatParameter bloomThreshold = new ClampedFloatParameter(0.85f, 0f, 2f);
        public ClampedFloatParameter bloomIntensity = new ClampedFloatParameter(0.9f, 0f, 4f);
        public ColorParameter colorTint = new ColorParameter(new Color(1f, 0.97f, 1.05f, 1f), true, false, true);

        public bool IsActive() => enableEffect.value;
        public bool IsTileCompatible() => false;
    }
}

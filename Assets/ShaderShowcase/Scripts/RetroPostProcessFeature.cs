using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.RenderGraphModule.Util;
using UnityEngine.Rendering.Universal;

namespace ShaderShowcase
{
    public class RetroPostProcessFeature : ScriptableRendererFeature
    {
        public Material material;
        public RenderPassEvent injectionPoint = RenderPassEvent.AfterRenderingPostProcessing;

        RetroPass pass;

        static readonly int IdChromatic = Shader.PropertyToID("_ChromaticAmount");
        static readonly int IdScanlineIntensity = Shader.PropertyToID("_ScanlineIntensity");
        static readonly int IdScanlineCount = Shader.PropertyToID("_ScanlineCount");
        static readonly int IdVignetteIntensity = Shader.PropertyToID("_VignetteIntensity");
        static readonly int IdVignetteSmoothness = Shader.PropertyToID("_VignetteSmoothness");
        static readonly int IdSaturation = Shader.PropertyToID("_Saturation");
        static readonly int IdContrast = Shader.PropertyToID("_Contrast");
        static readonly int IdExposure = Shader.PropertyToID("_Exposure");
        static readonly int IdNoise = Shader.PropertyToID("_NoiseAmount");
        static readonly int IdCurvature = Shader.PropertyToID("_Curvature");
        static readonly int IdBloomThreshold = Shader.PropertyToID("_BloomThreshold");
        static readonly int IdBloomIntensity = Shader.PropertyToID("_BloomIntensity");
        static readonly int IdColorTint = Shader.PropertyToID("_ColorTint");

        public override void Create()
        {
            pass = new RetroPass { renderPassEvent = injectionPoint };
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (material == null) return;
            if (renderingData.cameraData.cameraType != CameraType.Game) return;

            var stack = VolumeManager.instance.stack;
            var volume = stack.GetComponent<RetroPostProcessVolume>();
            if (volume == null || !volume.IsActive()) return;

            material.SetFloat(IdChromatic, volume.chromatic.value);
            material.SetFloat(IdScanlineIntensity, volume.scanlineIntensity.value);
            material.SetFloat(IdScanlineCount, volume.scanlineCount.value);
            material.SetFloat(IdVignetteIntensity, volume.vignetteIntensity.value);
            material.SetFloat(IdVignetteSmoothness, volume.vignetteSmoothness.value);
            material.SetFloat(IdSaturation, volume.saturation.value);
            material.SetFloat(IdContrast, volume.contrast.value);
            material.SetFloat(IdExposure, volume.exposure.value);
            material.SetFloat(IdNoise, volume.noise.value);
            material.SetFloat(IdCurvature, volume.curvature.value);
            material.SetFloat(IdBloomThreshold, volume.bloomThreshold.value);
            material.SetFloat(IdBloomIntensity, volume.bloomIntensity.value);
            material.SetColor(IdColorTint, volume.colorTint.value);

            pass.material = material;
            pass.renderPassEvent = injectionPoint;
            renderer.EnqueuePass(pass);
        }

        class RetroPass : ScriptableRenderPass
        {
            public Material material;

            public RetroPass()
            {
                requiresIntermediateTexture = true;
            }

            public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
            {
                if (material == null) return;
                var resourceData = frameData.Get<UniversalResourceData>();

                var src = resourceData.activeColorTexture;
                var desc = renderGraph.GetTextureDesc(src);
                desc.name = "RetroPP_Temp";
                desc.depthBufferBits = DepthBits.None;
                desc.clearBuffer = false;
                var tmp = renderGraph.CreateTexture(desc);

                var blitParams = new RenderGraphUtils.BlitMaterialParameters(src, tmp, material, 0);
                renderGraph.AddBlitPass(blitParams, "RetroPP_Apply");

                renderGraph.AddBlitPass(tmp, src, Vector2.one, Vector2.zero, passName: "RetroPP_Copy");
            }
        }
    }
}

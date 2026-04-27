Shader "ShaderShowcase/MagicCrystal"
{
    Properties
    {
        _CoreColor ("Core Color", Color) = (0.45, 0.20, 0.95, 1.0)
        _ShellColor ("Shell Color", Color) = (0.85, 0.95, 1.00, 1.0)
        _GlowColor ("Glow Color", Color) = (1.20, 0.55, 1.40, 1.0)
        _FresnelPower ("Fresnel Power", Range(0.1, 8)) = 2.2
        _FresnelStrength ("Fresnel Strength", Range(0, 5)) = 2.4
        _InnerNoiseScale ("Inner Noise Scale", Float) = 4.0
        _InnerNoiseSpeed ("Inner Noise Speed", Float) = 0.3
        _Refraction ("Refraction Strength", Range(0, 1)) = 0.55
        _IridescenceSpeed ("Iridescence Speed", Float) = 0.6
        _Alpha ("Alpha", Range(0, 1)) = 0.85
        _DepthFalloff ("Depth Falloff", Range(0.05, 4)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "RenderPipeline"="UniversalPipeline" "Queue"="Transparent" }
        LOD 200

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }
            Cull Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS  : TEXCOORD0;
                float3 positionOS  : TEXCOORD1;
                float3 normalWS    : TEXCOORD2;
                float3 viewDirWS   : TEXCOORD3;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _CoreColor;
                float4 _ShellColor;
                float4 _GlowColor;
                float  _FresnelPower;
                float  _FresnelStrength;
                float  _InnerNoiseScale;
                float  _InnerNoiseSpeed;
                float  _Refraction;
                float  _IridescenceSpeed;
                float  _Alpha;
                float  _DepthFalloff;
            CBUFFER_END

            float Hash3(float3 p)
            {
                p = frac(p * float3(123.34, 234.56, 345.67));
                p += dot(p, p.yzx + 45.32);
                return frac(p.x * p.y + p.z);
            }

            float Noise3(float3 p)
            {
                float3 i = floor(p);
                float3 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);
                float n000 = Hash3(i);
                float n100 = Hash3(i + float3(1, 0, 0));
                float n010 = Hash3(i + float3(0, 1, 0));
                float n110 = Hash3(i + float3(1, 1, 0));
                float n001 = Hash3(i + float3(0, 0, 1));
                float n101 = Hash3(i + float3(1, 0, 1));
                float n011 = Hash3(i + float3(0, 1, 1));
                float n111 = Hash3(i + float3(1, 1, 1));
                float nx00 = lerp(n000, n100, f.x);
                float nx10 = lerp(n010, n110, f.x);
                float nx01 = lerp(n001, n101, f.x);
                float nx11 = lerp(n011, n111, f.x);
                float nxy0 = lerp(nx00, nx10, f.y);
                float nxy1 = lerp(nx01, nx11, f.y);
                return lerp(nxy0, nxy1, f.z);
            }

            float Fbm3(float3 p)
            {
                float v = 0;
                float a = 0.5;
                for (int i = 0; i < 4; i++)
                {
                    v += a * Noise3(p);
                    p *= 2.07;
                    a *= 0.5;
                }
                return v;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs vpi = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionHCS = vpi.positionCS;
                OUT.positionWS  = vpi.positionWS;
                OUT.positionOS  = IN.positionOS.xyz;
                OUT.normalWS    = TransformObjectToWorldNormal(IN.normalOS);
                OUT.viewDirWS   = GetWorldSpaceViewDir(vpi.positionWS);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 N = normalize(IN.normalWS);
                float3 V = normalize(IN.viewDirWS);
                float NdV = saturate(dot(N, V));
                float fres = pow(1.0 - NdV, _FresnelPower);

                float t = _Time.y;
                float3 noisePos = IN.positionOS * _InnerNoiseScale + float3(0, t * _InnerNoiseSpeed, 0);
                float core = Fbm3(noisePos);
                float core2 = Fbm3(noisePos * 1.7 + 11.0 - t * _InnerNoiseSpeed * 0.7);

                float3 viewSlide = V * _Refraction;
                float layered = Fbm3(IN.positionOS * (_InnerNoiseScale * 1.5) + viewSlide + t * _InnerNoiseSpeed);

                float3 irid = 0.5 + 0.5 * cos(6.2831 * (NdV + float3(0.0, 0.33, 0.67)) + t * _IridescenceSpeed);

                float3 inner = lerp(_CoreColor.rgb, _ShellColor.rgb, core);
                inner = lerp(inner, _GlowColor.rgb, smoothstep(0.55, 0.95, core2));

                float depthMask = pow(saturate(layered), _DepthFalloff);
                inner *= 0.6 + depthMask * 1.4;

                float3 col = lerp(inner, _ShellColor.rgb * irid, fres * _FresnelStrength * 0.4);
                col += _GlowColor.rgb * fres * _FresnelStrength;

                Light light = GetMainLight();
                float3 H = normalize(light.direction + V);
                float spec = pow(saturate(dot(N, H)), 64);
                col += spec * light.color * _ShellColor.rgb * 1.5;

                float alpha = saturate(_Alpha + fres * 0.5);
                return half4(col, alpha);
            }
            ENDHLSL
        }
    }
    FallBack Off
}

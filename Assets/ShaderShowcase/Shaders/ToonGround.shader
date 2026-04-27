Shader "ShaderShowcase/ToonGround"
{
    Properties
    {
        _GrassDeep ("Grass Deep", Color) = (0.05, 0.18, 0.10, 1.0)
        _GrassMid  ("Grass Mid",  Color) = (0.18, 0.45, 0.22, 1.0)
        _GrassLight ("Grass Light", Color) = (0.55, 0.85, 0.40, 1.0)
        _PathColor ("Path Color", Color) = (0.45, 0.35, 0.25, 1.0)
        _GlowColor ("Glow Color", Color) = (0.55, 0.95, 1.40, 1.0)
        _GlowStrength ("Glow Strength", Range(0, 4)) = 1.2
        _GlowFrequency ("Glow Frequency", Float) = 1.6
        _NoiseScale ("Noise Scale", Float) = 1.6
        _ToonSteps ("Toon Steps", Range(2, 12)) = 4
        _SpecPower ("Spec Power", Range(2, 200)) = 32
        _RimColor ("Rim Color", Color) = (0.7, 0.9, 1.0, 1.0)
        _RimPower ("Rim Power", Range(0.1, 8)) = 3.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        LOD 200

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

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
                float3 normalWS    : TEXCOORD1;
                float2 uv          : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _GrassDeep;
                float4 _GrassMid;
                float4 _GrassLight;
                float4 _PathColor;
                float4 _GlowColor;
                float  _GlowStrength;
                float  _GlowFrequency;
                float  _NoiseScale;
                float  _ToonSteps;
                float  _SpecPower;
                float4 _RimColor;
                float  _RimPower;
            CBUFFER_END

            float Hash2(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            float ValueNoise2(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);
                float a = Hash2(i);
                float b = Hash2(i + float2(1, 0));
                float c = Hash2(i + float2(0, 1));
                float d = Hash2(i + float2(1, 1));
                return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
            }

            float Fbm2(float2 p)
            {
                float v = 0;
                float a = 0.5;
                for (int i = 0; i < 5; i++)
                {
                    v += a * ValueNoise2(p);
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
                OUT.normalWS    = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv          = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 N = normalize(IN.normalWS);
                Light light = GetMainLight();
                float3 V = normalize(GetWorldSpaceViewDir(IN.positionWS));

                float NdotL = saturate(dot(N, light.direction));
                float steps = max(_ToonSteps, 2.0);
                float toonShade = floor(NdotL * steps) / steps;

                float2 worldUV = IN.positionWS.xz * _NoiseScale * 0.1;
                float pattern = Fbm2(worldUV);
                float patternHigh = Fbm2(worldUV * 3.5 + 5.0);

                float3 grass = lerp(_GrassDeep.rgb, _GrassMid.rgb, smoothstep(0.25, 0.55, pattern));
                grass = lerp(grass, _GrassLight.rgb, smoothstep(0.55, 0.85, patternHigh));

                float pathMask = smoothstep(0.74, 0.84, pattern);
                float3 ground = lerp(grass, _PathColor.rgb, pathMask);

                float3 lit = ground * (toonShade * light.color + SampleSH(N) * 0.7);

                float3 H = normalize(V + light.direction);
                float NdotH = saturate(dot(N, H));
                float spec = step(0.6, pow(NdotH, _SpecPower));
                lit += spec * light.color * 0.4;

                float pulse = sin(IN.positionWS.x * _GlowFrequency
                                + IN.positionWS.z * _GlowFrequency * 1.3
                                + _Time.y * 1.6);
                float glowMask = smoothstep(0.55, 1.0, pulse) * (1.0 - pathMask);
                lit += _GlowColor.rgb * glowMask * _GlowStrength;

                float fres = pow(1.0 - saturate(dot(N, V)), _RimPower);
                lit += _RimColor.rgb * fres * 0.25;

                return half4(lit, 1);
            }
            ENDHLSL
        }
    }
    FallBack Off
}

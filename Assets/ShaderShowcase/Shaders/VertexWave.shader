Shader "ShaderShowcase/VertexWave"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.35, 0.7, 1.0, 1.0)
        _CrestColor ("Crest Color", Color) = (1.0, 0.95, 0.7, 1.0)
        _WaveAmplitude ("Wave Amplitude", Float) = 0.25
        _WaveFrequency ("Wave Frequency", Float) = 3.5
        _WaveSpeed ("Wave Speed", Float) = 1.6
        _RippleStrength ("Ripple Strength", Range(0, 2)) = 1.0
        _NormalCurvature ("Normal Curvature", Range(0, 4)) = 1.5
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
                float  height      : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _CrestColor;
                float  _WaveAmplitude;
                float  _WaveFrequency;
                float  _WaveSpeed;
                float  _RippleStrength;
                float  _NormalCurvature;
            CBUFFER_END

            float WaveField(float3 p, float t)
            {
                float a = sin(p.x * _WaveFrequency + t);
                float b = cos(p.z * _WaveFrequency * 1.27 + t * 1.4);
                float c = sin((p.x + p.z) * _WaveFrequency * 0.6 - t * 0.8);
                float radial = sin(length(p.xz) * _WaveFrequency * 0.9 - t * 2.2) * _RippleStrength;
                return ((a + b) * 0.5 + c * 0.4 + radial * 0.6) * _WaveAmplitude;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float t = _Time.y * _WaveSpeed;

                float h = WaveField(IN.positionOS.xyz, t);
                float3 displaced = IN.positionOS.xyz + IN.normalOS * h;

                float eps = 0.015;
                float dx = WaveField(IN.positionOS.xyz + float3(eps, 0, 0), t) - h;
                float dz = WaveField(IN.positionOS.xyz + float3(0, 0, eps), t) - h;

                float3 perturbed = normalize(IN.normalOS + float3(-dx, 0, -dz) * (_NormalCurvature / max(eps, 1e-4)));

                VertexPositionInputs vpi = GetVertexPositionInputs(displaced);
                OUT.positionHCS = vpi.positionCS;
                OUT.positionWS  = vpi.positionWS;
                OUT.normalWS    = TransformObjectToWorldNormal(perturbed);
                OUT.height      = h;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 N = normalize(IN.normalWS);
                Light light = GetMainLight();
                float NdotL = saturate(dot(N, light.direction));
                float3 ambient = SampleSH(N);

                float3 viewDir = normalize(GetWorldSpaceViewDir(IN.positionWS));
                float fres = pow(1.0 - saturate(dot(N, viewDir)), 3.0);

                float crest = saturate(IN.height / max(_WaveAmplitude, 1e-3) * 0.5 + 0.5);
                float3 baseCol = lerp(_BaseColor.rgb, _CrestColor.rgb, crest);

                float3 lit = baseCol * (NdotL * light.color + ambient * 0.6);
                lit += _CrestColor.rgb * fres * 0.6;

                return half4(lit, 1);
            }
            ENDHLSL
        }
    }
    FallBack Off
}

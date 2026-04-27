using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.SceneManagement;

namespace ShaderShowcase.EditorTools
{
    public static class ShaderShowcaseBuilder
    {
        const string Root = "Assets/ShaderShowcase";
        const string MatDir = Root + "/Materials";
        const string SceneDir = Root + "/Scenes";
        const string PCRendererPath = "Assets/Settings/PC_Renderer.asset";

        [MenuItem("Tools/Shader Showcase/Build All Demo Scenes")]
        public static void BuildAll()
        {
            EnsureFolder(Root);
            EnsureFolder(MatDir);
            EnsureFolder(SceneDir);

            var matVertex   = MakeMat("VertexWaveMat",        "ShaderShowcase/VertexWave");
            var matFragment = MakeMat("FragmentSwirlMat",     "ShaderShowcase/FragmentSwirl");
            var matItem     = MakeMat("ItemDissolveMat",      "ShaderShowcase/ItemDissolve");
            var matLava     = MakeMat("LavaMat",              "ShaderShowcase/EnvironmentLava");
            var matRetro    = MakeMat("RetroPostProcessMat",  "ShaderShowcase/PostProcessRetro");
            var matCrystal  = MakeMat("MagicCrystalMat",      "ShaderShowcase/MagicCrystal");
            var matSky      = MakeMat("StarSkyMat",           "ShaderShowcase/StarSky");
            var matGround   = MakeMat("ToonGroundMat",        "ShaderShowcase/ToonGround");

            ConfigureLava(matLava);
            ConfigureCrystal(matCrystal);
            ConfigureSky(matSky);
            ConfigureGround(matGround);

            BuildVertexScene(matVertex);
            BuildFragmentScene(matFragment);
            BuildItemScene(matItem);
            BuildEnvironmentScene(matLava);
            BuildPostProcessScene(matRetro);
            BuildCreativeScene(matCrystal, matSky, matGround, matLava);

            AddRetroFeatureToRenderer(matRetro);

            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();

            EditorUtility.DisplayDialog(
                "Shader Showcase",
                "Built all materials and scenes inside Assets/ShaderShowcase.\n\nOpen any scene in Assets/ShaderShowcase/Scenes and press Play.",
                "OK");
        }

        [MenuItem("Tools/Shader Showcase/Add Retro Post Process Feature")]
        public static void AddRetroFeatureMenu()
        {
            var matRetro = AssetDatabase.LoadAssetAtPath<Material>($"{MatDir}/RetroPostProcessMat.mat");
            if (matRetro == null)
            {
                EditorUtility.DisplayDialog("Shader Showcase", "Run 'Build All Demo Scenes' first.", "OK");
                return;
            }
            AddRetroFeatureToRenderer(matRetro);
        }

        static void EnsureFolder(string path)
        {
            if (AssetDatabase.IsValidFolder(path)) return;
            var parent = Path.GetDirectoryName(path).Replace('\\', '/');
            var leaf = Path.GetFileName(path);
            if (!AssetDatabase.IsValidFolder(parent)) EnsureFolder(parent);
            AssetDatabase.CreateFolder(parent, leaf);
        }

        static Material MakeMat(string fileName, string shaderName)
        {
            var path = $"{MatDir}/{fileName}.mat";
            var shader = Shader.Find(shaderName);
            if (shader == null)
            {
                Debug.LogError($"[ShaderShowcase] Missing shader: {shaderName}");
                return null;
            }
            var existing = AssetDatabase.LoadAssetAtPath<Material>(path);
            if (existing != null)
            {
                existing.shader = shader;
                EditorUtility.SetDirty(existing);
                return existing;
            }
            var mat = new Material(shader) { name = fileName };
            AssetDatabase.CreateAsset(mat, path);
            return mat;
        }

        static void ConfigureLava(Material m)
        {
            if (m == null) return;
            m.SetFloat("_FlowSpeed", 0.06f);
            m.SetFloat("_NoiseScaleA", 1.4f);
            m.SetFloat("_NoiseScaleB", 4.0f);
            m.SetFloat("_CrustThreshold", 0.46f);
            m.SetFloat("_CrustSharpness", 0.07f);
            m.SetFloat("_Emissive", 4.5f);
            m.SetFloat("_BubbleAmplitude", 0.06f);
            m.SetFloat("_BubbleSpeed", 1.6f);
            m.SetFloat("_BubbleScale", 6.0f);
            m.globalIlluminationFlags = MaterialGlobalIlluminationFlags.EmissiveIsBlack;
        }

        static void ConfigureCrystal(Material m)
        {
            if (m == null) return;
            m.SetColor("_CoreColor", new Color(0.40f, 0.18f, 0.95f, 1f));
            m.SetColor("_ShellColor", new Color(0.85f, 0.95f, 1.00f, 1f));
            m.SetColor("_GlowColor", new Color(1.20f, 0.55f, 1.40f, 1f));
            m.SetFloat("_FresnelPower", 2.4f);
            m.SetFloat("_FresnelStrength", 2.6f);
            m.SetFloat("_InnerNoiseScale", 4.5f);
            m.SetFloat("_InnerNoiseSpeed", 0.45f);
            m.SetFloat("_Refraction", 0.65f);
            m.SetFloat("_IridescenceSpeed", 0.7f);
            m.SetFloat("_Alpha", 0.8f);
        }

        static void ConfigureSky(Material m)
        {
            if (m == null) return;
            m.SetColor("_SkyTop", new Color(0.01f, 0.01f, 0.06f, 1f));
            m.SetColor("_SkyBottom", new Color(0.18f, 0.04f, 0.36f, 1f));
            m.SetColor("_NebulaColorA", new Color(0.55f, 0.10f, 0.90f, 1f));
            m.SetColor("_NebulaColorB", new Color(0.10f, 0.45f, 1.00f, 1f));
            m.SetFloat("_NebulaIntensity", 1.6f);
            m.SetFloat("_StarDensity", 220f);
            m.SetFloat("_StarBrightness", 3f);
            m.SetFloat("_TwinkleSpeed", 1.5f);
        }

        static void ConfigureGround(Material m)
        {
            if (m == null) return;
            m.SetColor("_GrassDeep", new Color(0.04f, 0.10f, 0.07f, 1f));
            m.SetColor("_GrassMid", new Color(0.10f, 0.30f, 0.22f, 1f));
            m.SetColor("_GrassLight", new Color(0.45f, 0.85f, 0.55f, 1f));
            m.SetColor("_GlowColor", new Color(0.50f, 1.00f, 1.30f, 1f));
            m.SetFloat("_GlowStrength", 1.4f);
            m.SetFloat("_GlowFrequency", 1.2f);
            m.SetFloat("_NoiseScale", 1.4f);
            m.SetFloat("_ToonSteps", 4f);
        }

        static Scene NewScene()
        {
            var s = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            return s;
        }

        static void SaveScene(Scene s, string name)
        {
            var path = $"{SceneDir}/{name}.unity";
            EditorSceneManager.MarkSceneDirty(s);
            EditorSceneManager.SaveScene(s, path);
        }

        static GameObject MakeLight(string name, Color col, float intensity, Quaternion rot)
        {
            var go = new GameObject(name);
            var l = go.AddComponent<Light>();
            l.type = LightType.Directional;
            l.color = col;
            l.intensity = intensity;
            l.shadows = LightShadows.Soft;
            go.transform.rotation = rot;
            return go;
        }

        static GameObject MakeOrbitCamera(Vector3 pivot, float distance, float height, float speed = 25f, Color? bg = null)
        {
            var go = new GameObject("Main Camera");
            go.tag = "MainCamera";
            var cam = go.AddComponent<Camera>();
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = bg ?? new Color(0.02f, 0.02f, 0.05f, 1);
            cam.fieldOfView = 55f;
            cam.nearClipPlane = 0.1f;
            cam.farClipPlane = 200f;
            var addCam = go.AddComponent<UniversalAdditionalCameraData>();
            addCam.renderPostProcessing = true;
            addCam.antialiasing = AntialiasingMode.SubpixelMorphologicalAntiAliasing;
            go.AddComponent<AudioListener>();

            var pivotGo = new GameObject("OrbitPivot");
            pivotGo.transform.position = pivot;

            var orb = go.AddComponent<OrbitCamera>();
            orb.target = pivotGo.transform;
            orb.distance = distance;
            orb.height = height;
            orb.speed = speed;
            return go;
        }

        static GameObject MakeProcMesh(string name, ProceduralMesh.Shape shape, Material m)
        {
            var go = new GameObject(name);
            go.AddComponent<MeshFilter>();
            var r = go.AddComponent<MeshRenderer>();
            r.sharedMaterial = m;
            var pm = go.AddComponent<ProceduralMesh>();
            pm.shape = shape;
            return go;
        }

        static void BuildVertexScene(Material m)
        {
            var s = NewScene();

            var sphere = MakeProcMesh("VertexSphere", ProceduralMesh.Shape.UvSphere, m);
            var procMesh = sphere.GetComponent<ProceduralMesh>();
            procMesh.shape = ProceduralMesh.Shape.UvSphere;
            procMesh.latitudeSegments = 96;
            procMesh.longitudeSegments = 128;
            procMesh.radius = 1.5f;
            procMesh.Rebuild();
            sphere.transform.position = Vector3.zero;

            MakeLight("Sun", new Color(1.0f, 0.95f, 0.85f, 1), 1.4f, Quaternion.Euler(50, 30, 0));
            MakeLight("FillLight", new Color(0.4f, 0.55f, 0.9f, 1), 0.4f, Quaternion.Euler(-25, 200, 0));

            MakeOrbitCamera(Vector3.zero, 5.5f, 1.6f, 22f, new Color(0.04f, 0.05f, 0.10f));
            AddBasicVolume();

            SaveScene(s, "01_VertexShader_Scene");
        }

        static void BuildFragmentScene(Material m)
        {
            var s = NewScene();

            var quad = MakeProcMesh("FragmentQuad", ProceduralMesh.Shape.Plane, m);
            var pm = quad.GetComponent<ProceduralMesh>();
            pm.shape = ProceduralMesh.Shape.Plane;
            pm.resolution = 4;
            pm.size = 5f;
            pm.Rebuild();
            quad.transform.rotation = Quaternion.Euler(90, 0, 0);
            quad.transform.position = Vector3.zero;

            MakeLight("Sun", Color.white, 1f, Quaternion.Euler(50, 30, 0));

            var cam = MakeOrbitCamera(Vector3.zero, 5.5f, 0.0f, 0f, new Color(0.0f, 0.0f, 0.05f));
            cam.GetComponent<OrbitCamera>().autoOrbit = false;
            cam.transform.position = new Vector3(0, 0, -5.5f);
            cam.transform.rotation = Quaternion.LookRotation(Vector3.forward);
            AddBasicVolume();

            SaveScene(s, "02_FragmentShader_Scene");
        }

        static void BuildItemScene(Material m)
        {
            var s = NewScene();

            var ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.name = "Ground";
            ground.transform.localScale = Vector3.one * 4f;
            ground.transform.position = new Vector3(0, -1, 0);
            var groundMat = new Material(Shader.Find("Universal Render Pipeline/Lit"));
            groundMat.SetColor("_BaseColor", new Color(0.18f, 0.18f, 0.22f));
            groundMat.SetFloat("_Smoothness", 0.15f);
            ground.GetComponent<Renderer>().sharedMaterial = groundMat;

            var item = GameObject.CreatePrimitive(PrimitiveType.Cube);
            item.name = "MagicItem";
            item.transform.position = new Vector3(0, 0.6f, 0);
            item.transform.localScale = Vector3.one * 1.2f;
            item.GetComponent<Renderer>().sharedMaterial = m;
            var spin = item.AddComponent<Spinner>();
            spin.axis = new Vector3(0.3f, 1f, 0.1f);
            spin.speed = 35f;
            spin.bobAxis = Vector3.up;
            spin.bobAmplitude = 0.18f;
            spin.bobSpeed = 1.4f;
            item.AddComponent<DissolveController>();

            MakeLight("Sun", new Color(1f, 0.95f, 0.9f), 1.0f, Quaternion.Euler(45, 30, 0));
            MakeLight("Rim", new Color(0.3f, 0.6f, 1.0f), 0.5f, Quaternion.Euler(20, -150, 0));

            MakeOrbitCamera(new Vector3(0, 0.6f, 0), 4.5f, 1.5f, 18f, new Color(0.04f, 0.04f, 0.07f));
            AddBasicVolume();

            SaveScene(s, "03_ItemShader_Scene");
        }

        static void BuildEnvironmentScene(Material lavaMat)
        {
            var s = NewScene();

            var lava = MakeProcMesh("LavaSurface", ProceduralMesh.Shape.Plane, lavaMat);
            var pm = lava.GetComponent<ProceduralMesh>();
            pm.shape = ProceduralMesh.Shape.Plane;
            pm.resolution = 180;
            pm.size = 16f;
            pm.Rebuild();
            lava.transform.position = new Vector3(0, -0.3f, 0);

            var rockShader = Shader.Find("Universal Render Pipeline/Lit");
            var rockMaterial = new Material(rockShader);
            rockMaterial.SetColor("_BaseColor", new Color(0.10f, 0.08f, 0.07f));
            rockMaterial.SetFloat("_Smoothness", 0.1f);

            var rng = new System.Random(12345);
            for (int i = 0; i < 18; i++)
            {
                var rock = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                rock.name = $"Rock_{i}";
                float r = (float)rng.NextDouble() * 6f + 2.5f;
                float a = (float)rng.NextDouble() * Mathf.PI * 2f;
                float scale = 0.6f + (float)rng.NextDouble() * 1.4f;
                rock.transform.position = new Vector3(Mathf.Cos(a) * r, -0.6f + (float)rng.NextDouble() * 0.4f, Mathf.Sin(a) * r);
                rock.transform.localScale = new Vector3(scale, scale * 0.6f, scale);
                rock.transform.rotation = Quaternion.Euler((float)rng.NextDouble() * 360f, (float)rng.NextDouble() * 360f, (float)rng.NextDouble() * 360f);
                rock.GetComponent<Renderer>().sharedMaterial = rockMaterial;
            }

            MakeLight("Sun", new Color(1f, 0.4f, 0.2f), 0.7f, Quaternion.Euler(35, 40, 0));
            MakeLight("Ambient", new Color(0.6f, 0.2f, 0.1f), 0.3f, Quaternion.Euler(120, -60, 0));

            MakeOrbitCamera(Vector3.zero, 9f, 4f, 12f, new Color(0.10f, 0.04f, 0.02f));
            AddBasicVolume();

            RenderSettings.ambientMode = AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.6f, 0.25f, 0.1f);
            RenderSettings.ambientEquatorColor = new Color(0.4f, 0.1f, 0.05f);
            RenderSettings.ambientGroundColor = new Color(0.2f, 0.05f, 0.02f);
            RenderSettings.fog = true;
            RenderSettings.fogColor = new Color(0.18f, 0.05f, 0.03f);
            RenderSettings.fogMode = FogMode.ExponentialSquared;
            RenderSettings.fogDensity = 0.03f;

            SaveScene(s, "04_EnvironmentShader_Scene");
        }

        static void BuildPostProcessScene(Material retroMat)
        {
            var s = NewScene();

            var ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.name = "Ground";
            ground.transform.localScale = Vector3.one * 3f;
            ground.transform.position = new Vector3(0, -1, 0);
            var groundMat = new Material(Shader.Find("Universal Render Pipeline/Lit"));
            groundMat.SetColor("_BaseColor", new Color(0.10f, 0.10f, 0.14f));
            groundMat.SetFloat("_Smoothness", 0.7f);
            groundMat.SetFloat("_Metallic", 0.4f);
            ground.GetComponent<Renderer>().sharedMaterial = groundMat;

            Color[] palette =
            {
                new Color(1.0f, 0.25f, 0.55f), new Color(0.20f, 0.85f, 1.00f),
                new Color(1.0f, 0.85f, 0.20f), new Color(0.60f, 0.30f, 1.00f),
                new Color(0.20f, 1.00f, 0.60f), new Color(1.00f, 0.55f, 0.20f),
            };
            var litShader = Shader.Find("Universal Render Pipeline/Lit");

            for (int i = 0; i < 8; i++)
            {
                var go = GameObject.CreatePrimitive(i % 2 == 0 ? PrimitiveType.Cube : PrimitiveType.Sphere);
                go.name = $"Prop_{i}";
                float a = (i / 8f) * Mathf.PI * 2f;
                go.transform.position = new Vector3(Mathf.Cos(a) * 2.4f, 0.2f, Mathf.Sin(a) * 2.4f);
                go.transform.localScale = Vector3.one * (0.8f + 0.3f * Mathf.Sin(i));

                var mat = new Material(litShader);
                Color c = palette[i % palette.Length];
                mat.SetColor("_BaseColor", c * 0.6f);
                mat.SetColor("_EmissionColor", c * 1.8f);
                mat.EnableKeyword("_EMISSION");
                mat.SetFloat("_Smoothness", 0.85f);
                mat.SetFloat("_Metallic", 0.2f);
                go.GetComponent<Renderer>().sharedMaterial = mat;

                var sp = go.AddComponent<Spinner>();
                sp.axis = new Vector3(Mathf.Sin(i), 1, Mathf.Cos(i)).normalized;
                sp.speed = 30f + i * 5f;
                sp.bobAxis = Vector3.up;
                sp.bobAmplitude = 0.15f;
                sp.bobSpeed = 1.0f + i * 0.1f;
            }

            var pillar = GameObject.CreatePrimitive(PrimitiveType.Cube);
            pillar.name = "Centerpiece";
            pillar.transform.position = new Vector3(0, 0.6f, 0);
            pillar.transform.localScale = new Vector3(0.6f, 1.6f, 0.6f);
            var pmat = new Material(litShader);
            pmat.SetColor("_BaseColor", new Color(0.05f, 0.05f, 0.08f));
            pmat.SetColor("_EmissionColor", new Color(2.0f, 0.5f, 1.5f));
            pmat.EnableKeyword("_EMISSION");
            pillar.GetComponent<Renderer>().sharedMaterial = pmat;
            var psp = pillar.AddComponent<Spinner>();
            psp.axis = Vector3.up;
            psp.speed = 12f;

            MakeLight("Sun", new Color(0.7f, 0.85f, 1.0f), 0.7f, Quaternion.Euler(50, 30, 0));
            MakeLight("Rim", new Color(1.0f, 0.5f, 0.9f), 0.5f, Quaternion.Euler(20, -150, 0));

            MakeOrbitCamera(new Vector3(0, 0.4f, 0), 5.5f, 2.0f, 16f, new Color(0.02f, 0.02f, 0.05f));
            AddPostProcessVolume();

            SaveScene(s, "05_PostProcessing_Scene");
        }

        static void BuildCreativeScene(Material crystalMat, Material skyMat, Material groundMat, Material lavaMat)
        {
            var s = NewScene();

            var sky = MakeProcMesh("SkyDome", ProceduralMesh.Shape.UvSphere, skyMat);
            var spm = sky.GetComponent<ProceduralMesh>();
            spm.shape = ProceduralMesh.Shape.UvSphere;
            spm.latitudeSegments = 32;
            spm.longitudeSegments = 64;
            spm.radius = 60f;
            spm.flipNormals = true;
            spm.Rebuild();
            sky.transform.position = Vector3.zero;

            var ground = MakeProcMesh("MagicGround", ProceduralMesh.Shape.Plane, groundMat);
            var gpm = ground.GetComponent<ProceduralMesh>();
            gpm.shape = ProceduralMesh.Shape.Plane;
            gpm.resolution = 80;
            gpm.size = 30f;
            gpm.Rebuild();
            ground.transform.position = new Vector3(0, -1f, 0);

            var crystal = GameObject.CreatePrimitive(PrimitiveType.Cube);
            DestroyImmediateSafe(crystal.GetComponent<BoxCollider>());
            crystal.name = "MagicCrystal";
            crystal.transform.position = new Vector3(0, 0.5f, 0);
            crystal.transform.localScale = new Vector3(0.9f, 1.7f, 0.9f);
            crystal.transform.rotation = Quaternion.Euler(0, 35, 0);
            crystal.GetComponent<Renderer>().sharedMaterial = crystalMat;
            var sp = crystal.AddComponent<Spinner>();
            sp.axis = Vector3.up;
            sp.speed = 18f;
            sp.bobAxis = Vector3.up;
            sp.bobAmplitude = 0.2f;
            sp.bobSpeed = 0.9f;

            for (int i = 0; i < 6; i++)
            {
                var orb = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                orb.name = $"Orbiter_{i}";
                orb.transform.localScale = Vector3.one * 0.3f;
                float a = (i / 6f) * Mathf.PI * 2f;
                orb.transform.position = new Vector3(Mathf.Cos(a) * 2.0f, 0.6f + Mathf.Sin(i) * 0.3f, Mathf.Sin(a) * 2.0f);
                orb.transform.parent = crystal.transform;
                orb.GetComponent<Renderer>().sharedMaterial = crystalMat;
            }

            var lavaPool = MakeProcMesh("LavaPool", ProceduralMesh.Shape.Disc, lavaMat);
            var lpm = lavaPool.GetComponent<ProceduralMesh>();
            lpm.shape = ProceduralMesh.Shape.Disc;
            lpm.resolution = 90;
            lpm.size = 5f;
            lpm.Rebuild();
            lavaPool.transform.position = new Vector3(7f, -0.95f, -3f);

            MakeLight("Sun", new Color(0.85f, 0.9f, 1.0f), 0.9f, Quaternion.Euler(40, 35, 0));
            MakeLight("Magic", new Color(0.6f, 0.4f, 1.0f), 0.6f, Quaternion.Euler(-25, -120, 0));

            MakeOrbitCamera(new Vector3(0, 0.5f, 0), 6.5f, 2.5f, 14f, new Color(0.01f, 0.01f, 0.04f));
            AddPostProcessVolume(softer: true);

            RenderSettings.ambientMode = AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.1f, 0.1f, 0.25f);
            RenderSettings.ambientEquatorColor = new Color(0.2f, 0.05f, 0.3f);
            RenderSettings.ambientGroundColor = new Color(0.05f, 0.05f, 0.1f);
            RenderSettings.fog = true;
            RenderSettings.fogColor = new Color(0.1f, 0.05f, 0.2f);
            RenderSettings.fogMode = FogMode.ExponentialSquared;
            RenderSettings.fogDensity = 0.012f;

            SaveScene(s, "06_CreativeShowcase_Scene");
        }

        static void DestroyImmediateSafe(Object o)
        {
            if (o == null) return;
            Object.DestroyImmediate(o);
        }

        static void AddBasicVolume()
        {
            var go = new GameObject("Volume");
            go.transform.position = Vector3.zero;
            var v = go.AddComponent<Volume>();
            v.isGlobal = true;

            var path = $"{MatDir}/BasicVolumeProfile.asset";
            var profile = AssetDatabase.LoadAssetAtPath<VolumeProfile>(path);
            if (profile == null)
            {
                profile = ScriptableObject.CreateInstance<VolumeProfile>();
                AssetDatabase.CreateAsset(profile, path);
            }

            EnsureOverride<UnityEngine.Rendering.Universal.Bloom>(profile, b =>
            {
                b.intensity.overrideState = true;
                b.intensity.value = 0.4f;
                b.threshold.overrideState = true;
                b.threshold.value = 1.1f;
            });
            EnsureOverride<UnityEngine.Rendering.Universal.Vignette>(profile, x =>
            {
                x.intensity.overrideState = true;
                x.intensity.value = 0.2f;
            });

            v.sharedProfile = profile;
            EditorUtility.SetDirty(profile);
        }

        static void AddPostProcessVolume(bool softer = false)
        {
            var go = new GameObject("Volume");
            var v = go.AddComponent<Volume>();
            v.isGlobal = true;

            var profileName = softer ? "CreativeVolumeProfile" : "PostProcessVolumeProfile";
            var path = $"{MatDir}/{profileName}.asset";
            VolumeProfile profile = AssetDatabase.LoadAssetAtPath<VolumeProfile>(path);
            if (profile == null)
            {
                profile = ScriptableObject.CreateInstance<VolumeProfile>();
                AssetDatabase.CreateAsset(profile, path);
            }

            EnsureOverride<UnityEngine.Rendering.Universal.Bloom>(profile, b =>
            {
                b.intensity.overrideState = true;
                b.intensity.value = softer ? 0.6f : 1.1f;
                b.threshold.overrideState = true;
                b.threshold.value = 0.9f;
                b.scatter.overrideState = true;
                b.scatter.value = 0.7f;
            });
            EnsureOverride<UnityEngine.Rendering.Universal.Vignette>(profile, x =>
            {
                x.intensity.overrideState = true;
                x.intensity.value = softer ? 0.25f : 0.35f;
            });
            EnsureOverride<UnityEngine.Rendering.Universal.ColorAdjustments>(profile, c =>
            {
                c.contrast.overrideState = true;
                c.contrast.value = 8f;
                c.saturation.overrideState = true;
                c.saturation.value = 12f;
            });
            EnsureOverride<UnityEngine.Rendering.Universal.Tonemapping>(profile, t =>
            {
                t.mode.overrideState = true;
                t.mode.value = UnityEngine.Rendering.Universal.TonemappingMode.ACES;
            });
            EnsureOverride<RetroPostProcessVolume>(profile, r =>
            {
                r.enableEffect.overrideState = true;
                r.enableEffect.value = true;
                r.chromatic.overrideState = true;
                r.chromatic.value = softer ? 1.0f : 1.6f;
                r.scanlineIntensity.overrideState = true;
                r.scanlineIntensity.value = softer ? 0.10f : 0.22f;
                r.vignetteIntensity.overrideState = true;
                r.vignetteIntensity.value = softer ? 0.40f : 0.60f;
                r.curvature.overrideState = true;
                r.curvature.value = softer ? 0.025f : 0.045f;
                r.bloomIntensity.overrideState = true;
                r.bloomIntensity.value = softer ? 0.6f : 1.0f;
                r.noise.overrideState = true;
                r.noise.value = softer ? 0.025f : 0.05f;
            });

            v.sharedProfile = profile;
            EditorUtility.SetDirty(profile);
        }

        static void EnsureOverride<T>(VolumeProfile p, System.Action<T> configure) where T : VolumeComponent
        {
            T c;
            if (!p.TryGet<T>(out c))
            {
                c = p.Add<T>(true);
            }
            configure(c);
            EditorUtility.SetDirty(p);
        }

        static void AddRetroFeatureToRenderer(Material retroMat)
        {
            var rendererData = AssetDatabase.LoadAssetAtPath<ScriptableRendererData>(PCRendererPath);
            if (rendererData == null)
            {
                Debug.LogWarning($"[ShaderShowcase] Could not load renderer at {PCRendererPath}; skipping post-process feature setup.");
                return;
            }

            foreach (var f in rendererData.rendererFeatures)
            {
                if (f is RetroPostProcessFeature rf)
                {
                    rf.material = retroMat;
                    EditorUtility.SetDirty(rf);
                    EditorUtility.SetDirty(rendererData);
                    AssetDatabase.SaveAssets();
                    Debug.Log("[ShaderShowcase] Updated existing RetroPostProcessFeature material.");
                    return;
                }
            }

            var feature = ScriptableObject.CreateInstance<RetroPostProcessFeature>();
            feature.name = nameof(RetroPostProcessFeature);
            feature.material = retroMat;

            AssetDatabase.AddObjectToAsset(feature, rendererData);
            AssetDatabase.SaveAssets();

            AssetDatabase.TryGetGUIDAndLocalFileIdentifier(feature, out string _, out long localId);

            var so = new SerializedObject(rendererData);
            var listProp = so.FindProperty("m_RendererFeatures");
            var mapProp = so.FindProperty("m_RendererFeatureMap");

            int idx = listProp.arraySize;
            listProp.InsertArrayElementAtIndex(idx);
            listProp.GetArrayElementAtIndex(idx).objectReferenceValue = feature;

            if (mapProp != null && mapProp.isArray)
            {
                mapProp.InsertArrayElementAtIndex(mapProp.arraySize);
                mapProp.GetArrayElementAtIndex(mapProp.arraySize - 1).longValue = localId != 0 ? localId : (long)Random.Range(int.MinValue, int.MaxValue);
            }

            so.ApplyModifiedProperties();

            EditorUtility.SetDirty(feature);
            EditorUtility.SetDirty(rendererData);
            AssetDatabase.SaveAssets();
            AssetDatabase.ImportAsset(PCRendererPath);

            Debug.Log("[ShaderShowcase] Added RetroPostProcessFeature to PC_Renderer.");
        }
    }
}

using UnityEngine;
using UnityEngine.Rendering;

namespace ShaderShowcase
{
    [ExecuteAlways]
    [RequireComponent(typeof(MeshFilter))]
    public class ProceduralMesh : MonoBehaviour
    {
        public enum Shape { Plane, UvSphere, Disc }

        public Shape shape = Shape.Plane;

        [Header("Plane / Disc")]
        public int resolution = 100;
        public float size = 6f;

        [Header("Sphere")]
        public int latitudeSegments = 64;
        public int longitudeSegments = 96;
        public float radius = 1f;
        public bool flipNormals = false;

        Mesh built;

        void OnEnable() { Rebuild(); }
        void OnValidate() { Rebuild(); }

        public void Rebuild()
        {
            var mf = GetComponent<MeshFilter>();
            if (built == null)
            {
                built = new Mesh { name = "ProceduralMesh", indexFormat = IndexFormat.UInt32 };
            }
            built.Clear();

            switch (shape)
            {
                case Shape.Plane: BuildPlane(); break;
                case Shape.UvSphere: BuildSphere(); break;
                case Shape.Disc: BuildDisc(); break;
            }

            built.RecalculateBounds();
            mf.sharedMesh = built;
        }

        void BuildPlane()
        {
            int n = Mathf.Max(2, resolution) + 1;
            var verts = new Vector3[n * n];
            var uvs = new Vector2[n * n];
            var normals = new Vector3[n * n];
            var tris = new int[(n - 1) * (n - 1) * 6];

            for (int z = 0; z < n; z++)
            for (int x = 0; x < n; x++)
            {
                int i = z * n + x;
                float u = x / (float)(n - 1);
                float v = z / (float)(n - 1);
                verts[i] = new Vector3((u - 0.5f) * size, 0f, (v - 0.5f) * size);
                uvs[i] = new Vector2(u, v);
                normals[i] = Vector3.up;
            }

            int t = 0;
            for (int z = 0; z < n - 1; z++)
            for (int x = 0; x < n - 1; x++)
            {
                int i = z * n + x;
                tris[t++] = i;
                tris[t++] = i + n;
                tris[t++] = i + n + 1;
                tris[t++] = i;
                tris[t++] = i + n + 1;
                tris[t++] = i + 1;
            }

            built.vertices = verts;
            built.uv = uvs;
            built.normals = normals;
            built.triangles = tris;
        }

        void BuildSphere()
        {
            int lat = Mathf.Max(3, latitudeSegments);
            int lon = Mathf.Max(3, longitudeSegments);
            int vCount = (lat + 1) * (lon + 1);
            var verts = new Vector3[vCount];
            var uvs = new Vector2[vCount];
            var normals = new Vector3[vCount];
            var tris = new int[lat * lon * 6];

            for (int la = 0; la <= lat; la++)
            {
                float a = Mathf.PI * la / lat;
                float sinA = Mathf.Sin(a);
                float cosA = Mathf.Cos(a);
                for (int lo = 0; lo <= lon; lo++)
                {
                    float b = 2f * Mathf.PI * lo / lon;
                    float sinB = Mathf.Sin(b);
                    float cosB = Mathf.Cos(b);
                    int i = la * (lon + 1) + lo;
                    var n = new Vector3(sinA * cosB, cosA, sinA * sinB);
                    verts[i] = n * radius;
                    uvs[i] = new Vector2(lo / (float)lon, la / (float)lat);
                    normals[i] = flipNormals ? -n : n;
                }
            }

            int t = 0;
            for (int la = 0; la < lat; la++)
            for (int lo = 0; lo < lon; lo++)
            {
                int i = la * (lon + 1) + lo;
                int j = i + lon + 1;
                if (flipNormals)
                {
                    tris[t++] = i; tris[t++] = j + 1; tris[t++] = j;
                    tris[t++] = i; tris[t++] = i + 1; tris[t++] = j + 1;
                }
                else
                {
                    tris[t++] = i; tris[t++] = j; tris[t++] = j + 1;
                    tris[t++] = i; tris[t++] = j + 1; tris[t++] = i + 1;
                }
            }

            built.vertices = verts;
            built.uv = uvs;
            built.normals = normals;
            built.triangles = tris;
        }

        void BuildDisc()
        {
            int n = Mathf.Max(8, resolution);
            int vCount = n * n;
            var verts = new Vector3[vCount];
            var uvs = new Vector2[vCount];
            var normals = new Vector3[vCount];
            var tris = new int[(n - 1) * (n - 1) * 6];

            for (int j = 0; j < n; j++)
            for (int i = 0; i < n; i++)
            {
                int idx = j * n + i;
                float u = i / (float)(n - 1);
                float v = j / (float)(n - 1);
                float angle = u * Mathf.PI * 2f;
                float r = v * (size * 0.5f);
                verts[idx] = new Vector3(Mathf.Cos(angle) * r, 0f, Mathf.Sin(angle) * r);
                uvs[idx] = new Vector2(u, v);
                normals[idx] = Vector3.up;
            }

            int t = 0;
            for (int j = 0; j < n - 1; j++)
            for (int i = 0; i < n - 1; i++)
            {
                int a = j * n + i;
                int b = a + n;
                tris[t++] = a; tris[t++] = b; tris[t++] = b + 1;
                tris[t++] = a; tris[t++] = b + 1; tris[t++] = a + 1;
            }

            built.vertices = verts;
            built.uv = uvs;
            built.normals = normals;
            built.triangles = tris;
        }
    }
}

using UnityEngine;

namespace ShaderShowcase
{
    [RequireComponent(typeof(Renderer))]
    public class DissolveController : MonoBehaviour
    {
        public float minAmount = 0f;
        public float maxAmount = 1f;
        public float speed = 0.4f;
        public bool pingPong = true;
        public bool autoplay = true;

        static readonly int DissolveAmountID = Shader.PropertyToID("_DissolveAmount");

        Material instance;
        float t;

        void Start()
        {
            var r = GetComponent<Renderer>();
            instance = r.material;
        }

        void Update()
        {
            if (!autoplay || instance == null) return;
            t += Time.deltaTime * speed;
            float k = pingPong ? Mathf.PingPong(t, 1f) : Mathf.Repeat(t, 1f);
            float v = Mathf.Lerp(minAmount, maxAmount, k);
            instance.SetFloat(DissolveAmountID, v);
        }

        public void SetAmount(float a)
        {
            if (instance == null) return;
            instance.SetFloat(DissolveAmountID, Mathf.Clamp01(a));
        }
    }
}

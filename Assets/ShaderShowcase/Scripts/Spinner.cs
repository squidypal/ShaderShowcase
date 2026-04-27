using UnityEngine;

namespace ShaderShowcase
{
    public class Spinner : MonoBehaviour
    {
        public Vector3 axis = Vector3.up;
        public float speed = 30f;
        public Vector3 bobAxis = Vector3.up;
        public float bobAmplitude = 0.0f;
        public float bobSpeed = 1.0f;

        Vector3 startPos;

        void Start() { startPos = transform.position; }

        void Update()
        {
            transform.Rotate(axis.normalized, speed * Time.deltaTime, Space.World);
            if (bobAmplitude > 0f)
            {
                transform.position = startPos + bobAxis.normalized * Mathf.Sin(Time.time * bobSpeed) * bobAmplitude;
            }
        }
    }
}

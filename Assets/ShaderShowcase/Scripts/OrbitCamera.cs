using UnityEngine;

namespace ShaderShowcase
{
    public class OrbitCamera : MonoBehaviour
    {
        public Transform target;
        public float distance = 6f;
        public float height = 2.5f;
        public float speed = 25f;
        public float lookOffset = 0.5f;
        public bool autoOrbit = true;
        public float manualMouseSensitivity = 120f;

        float angle;

        void Start()
        {
            if (target == null)
            {
                var go = new GameObject("OrbitTarget");
                go.transform.position = Vector3.zero;
                target = go.transform;
            }
        }

        void LateUpdate()
        {
            if (target == null) return;

            if (autoOrbit)
            {
                angle += speed * Time.deltaTime;
            }
            else if (Input.GetMouseButton(1))
            {
                angle += Input.GetAxis("Mouse X") * manualMouseSensitivity * Time.deltaTime;
            }

            float rad = angle * Mathf.Deg2Rad;
            Vector3 offset = new Vector3(Mathf.Cos(rad), 0, Mathf.Sin(rad)) * distance;
            offset.y = height;
            transform.position = target.position + offset;
            transform.LookAt(target.position + Vector3.up * lookOffset);
        }
    }
}

using UnityEngine;

public class PlaneShadow : MonoBehaviour
{
    public float Radius;
    public float ShadowFalloff;
    public float HeightRange;

    void Update()
    {
        Shader.SetGlobalVector("_CenterPos", transform.position);
        Shader.SetGlobalFloat("_CenterRadius", Radius * Radius);
        Shader.SetGlobalFloat("_ShadowFalloff", ShadowFalloff);
        Shader.SetGlobalFloat("_HeightRange", HeightRange);
    }
}

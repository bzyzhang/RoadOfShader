using UnityEngine;

public class MoveForward : MonoBehaviour
{
    public float Speed = 5;

    private void Update()
    {
        transform.Translate(transform.forward * Speed * Time.deltaTime, Space.World);
    }
}

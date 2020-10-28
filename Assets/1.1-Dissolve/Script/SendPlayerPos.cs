using System.Collections;
using UnityEngine;

[ExecuteInEditMode]
public class SendPlayerPos : MonoBehaviour {
    public Transform player;
    public Material blockMat;

    void Update () {
        blockMat.SetVector ("_PlayerPos", player.position);
    }
}
using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

[Serializable]
public class SimpleObject
{
    public string Name;
    public PrimitiveType Type;
    public int siblingIndex;
    public Vector3 Position;
    public Vector3 EulerAngles;
    public Vector3 Scale;
}

[Serializable]
public class SimpleObjects
{
    public List<SimpleObject> Objects;
}

public class SceneHelper
{
    private static string FILE_NAME = "Objects.json";

    [MenuItem("Tools/CollectObjects")]
    private static void CollectObjects()
    {
        List<SimpleObject> objects = new List<SimpleObject>();

        foreach (Transform transform in UnityEngine.Object.FindObjectsOfType(typeof(Transform)))
        {
            if (transform.parent != null)
                continue;

            PrimitiveType primitiveType = PrimitiveType.Cube;
            var meshFilter = transform.GetComponent<MeshFilter>();
            if (meshFilter != null)
                primitiveType = ConvertToPrimitiveType(meshFilter.sharedMesh.name);

            SimpleObject simpleObject = new SimpleObject
            {
                Name = transform.name,
                Type = primitiveType,
                siblingIndex = transform.GetSiblingIndex(),
                Position = transform.position,
                EulerAngles = transform.eulerAngles,
                Scale = transform.localScale
            };
            objects.Add(simpleObject);
        }

        objects.Sort((a, b) =>
        {
            int o = a.siblingIndex - b.siblingIndex;
            return o;
        });

        SimpleObjects SimpleObjects = new SimpleObjects
        {
            Objects = objects
        };

        var objectsJson = JsonUtility.ToJson(SimpleObjects, true);

        var filePath = string.Format($"{Application.dataPath}/{FILE_NAME}");

        if (!File.Exists(filePath))
        {
            File.Create(filePath);
        }

        File.WriteAllText(filePath, objectsJson);
    }

    [MenuItem("Tools/InstantiteObjects")]
    private static void InstantiteObjects()
    {
        var filePath = string.Format($"{Application.dataPath}/{FILE_NAME}");

        if (!File.Exists(filePath))
        {
            Debug.LogError("没有文件啊");
            return;
        }

        var objectsStr = File.ReadAllText(filePath);
        var objects = JsonUtility.FromJson<SimpleObjects>(objectsStr);

        foreach (var item in objects.Objects)
        {
            if (item.Name.IndexOf("Main Camera") >= 0)
            {
                var camera = GameObject.Find("Main Camera");
                if (camera)
                {
                    camera.transform.position = item.Position;
                    camera.transform.eulerAngles = item.EulerAngles;
                    camera.transform.localScale = item.Scale;
                }
            }
            else if (item.Name.IndexOf("Directional Light") >= 0)
            {
                var light = GameObject.Find("Directional Light");
                if (light)
                {
                    light.transform.position = item.Position;
                    light.transform.eulerAngles = item.EulerAngles;
                    light.transform.localScale = item.Scale;
                }
            }
            else
            {
                var primitive = GameObject.CreatePrimitive(item.Type);
                primitive.name = item.Name;
                primitive.transform.position = item.Position;
                primitive.transform.eulerAngles = item.EulerAngles;
                primitive.transform.localScale = item.Scale;
            }
        }
    }

    private static PrimitiveType ConvertToPrimitiveType(string name)
    {
        PrimitiveType primitiveType = PrimitiveType.Cube;

        if (name.IndexOf("Sphere") >= 0)
        {
            primitiveType = PrimitiveType.Sphere;
        }
        else if (name.IndexOf("Capsule") >= 0)
        {
            primitiveType = PrimitiveType.Capsule;
        }
        else if (name.IndexOf("Cylinder") >= 0)
        {
            primitiveType = PrimitiveType.Cylinder;
        }
        else if (name.IndexOf("Cube") >= 0)
        {
            primitiveType = PrimitiveType.Cube;
        }
        else if (name.IndexOf("Plane") >= 0)
        {
            primitiveType = PrimitiveType.Plane;
        }
        else if (name.IndexOf("Quad") >= 0)
        {
            primitiveType = PrimitiveType.Quad;
        }
        else
        {
            Debug.LogError(name);
        }

        return primitiveType;
    }
}

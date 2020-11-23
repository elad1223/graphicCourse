using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class MeshData
{
    public List<Vector3> vertices; // The vertices of the mesh 
    public List<int> triangles; // Indices of vertices that make up the mesh faces
    public Vector3[] normals; // The normals of the mesh, one per vertex

    // Class initializer
    public MeshData()
    {
        vertices = new List<Vector3>();
        triangles = new List<int>();
    }

    // Returns a Unity Mesh of this MeshData that can be rendered
    public Mesh ToUnityMesh()
    {
        Mesh mesh = new Mesh
        {
            vertices = vertices.ToArray(),
            triangles = triangles.ToArray(),
            normals = normals
        };

        return mesh;
    }

    // Calculates surface normals for each vertex, according to face orientation
    public void CalculateNormals()
    {
        normals = new Vector3[vertices.Count];
        //foreach tringle
        for (int i = 0; i < triangles.Count; i += 3)
        {
            Vector3 a=vertices[triangles[i]],
                b= vertices[triangles[i+1]],
                c=vertices[triangles[i+2]];
            Vector3 normal_surface = Vector3.Cross(a - c, b - c).normalized;
            //adding the normals to each vertex that build it
            for(int j=i;j<i+3;j++)
                normals[triangles[j]] = normals[triangles[j]] + normal_surface;
        }
        //normalize the normals
        for (int i = 0; i < normals.Length; i++)
            normals[i] = normals[i].normalized;
    }

    // Edits mesh such that each face has a unique set of 3 vertices
    public void MakeFlatShaded()
    {
        HashSet<int> seen = new HashSet<int>();
        for(int i = 0; i < triangles.Count; i++)
        {
            int index = triangles[i];
            if (seen.Contains(index))
            {
                Vector3 to_add = vertices[triangles[i]];
                vertices.Add(to_add);
                triangles[i] = vertices.Count - 1;
            }
            else { seen.Add(index); }
        }
        // Your implementation
    }
}
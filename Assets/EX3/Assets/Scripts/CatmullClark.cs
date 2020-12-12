using System;
using System.Collections.Generic;
using UnityEngine;

public class CCMeshData
{
    public List<Vector3> points; // Original mesh points
    public List<Vector4> faces; // Original mesh quad faces
    public List<Vector4> edges; // Original mesh edges
    public List<Vector3> facePoints; // Face points, as described in the Catmull-Clark algorithm
    public List<Vector3> edgePoints; // Edge points, as described in the Catmull-Clark algorithm
    public List<Vector3> newPoints; // New locations of the original mesh points, according to Catmull-Clark
}


public static class CatmullClark
{
    // Returns a QuadMeshData representing the input mesh after one iteration of Catmull-Clark subdivision.
    public static QuadMeshData Subdivide(QuadMeshData quadMeshData)
    {
        // Create and initialize a CCMeshData corresponding to the given QuadMeshData
        CCMeshData meshData = new CCMeshData();
        meshData.points = quadMeshData.vertices;
        meshData.faces = quadMeshData.quads;
        meshData.edges = GetEdges(meshData);
        meshData.facePoints = GetFacePoints(meshData);
        meshData.edgePoints = GetEdgePoints(meshData);
        meshData.newPoints = GetNewPoints(meshData);
        // Combine facePoints, edgePoints and newPoints into a subdivided QuadMeshData

        List<Vector4> quads = new List<Vector4>();
        Dictionary<Vector2, Vector4> semi_quad = new Dictionary<Vector2, Vector4>();
        int vertexNumber = meshData.newPoints.Count,
            edgeNumber = meshData.edges.Count;
        for (int edge_index = 0; edge_index < meshData.edges.Count; edge_index++)
        {
            int vertex_index1 = (int)meshData.edges[edge_index].x,
                vertex_index2 = (int)meshData.edges[edge_index].y,
                face_index1 = (int)meshData.edges[edge_index].z,
                face_index2 = (int)meshData.edges[edge_index].w;
            add_to_dict(ref semi_quad, true, vertexNumber, edgeNumber, vertex_index1, edge_index, face_index1);
            add_to_dict(ref semi_quad, false, vertexNumber, edgeNumber, vertex_index2, edge_index, face_index1);
            add_to_dict(ref semi_quad, false,vertexNumber, edgeNumber, vertex_index1, edge_index, face_index2);
            add_to_dict(ref semi_quad, true,vertexNumber, edgeNumber, vertex_index2, edge_index, face_index2);
        }
        foreach (Vector4 quad in semi_quad.Values) quads.Add(quad);

        List<Vector3> allPoint = new List<Vector3>();
        allPoint.AddRange(meshData.newPoints);
        allPoint.AddRange(meshData.edgePoints);
        allPoint.AddRange(meshData.facePoints);
        Debug.Log(quads.Count);

        return new QuadMeshData(allPoint,quads);
    }
    public static void add_to_dict(ref Dictionary<Vector2,Vector4> semi_quad,
        bool clockwise,int vertexNumber,int edgeNumber,int vertex,int edge,int face)
    {
        Vector2 key = new Vector2(vertex, face);
        if (semi_quad.ContainsKey(key))
        {
            semi_quad[key]=new Vector4(semi_quad[key].x, semi_quad[key].y,
                semi_quad[key].z, vertexNumber + edge);
        }
        else
        {
            if(clockwise)
            semi_quad[key] = new Vector4(vertex, edge + vertexNumber,
                vertexNumber + edgeNumber + face, -1);
            else
                semi_quad[key] = new Vector4(vertexNumber + edgeNumber + face, edge + vertexNumber,
                vertex, -1);
        }
    }
    public class Vec2Comparer : EqualityComparer<Vector2>
    {
        private static int PRIME = 31;
        public override bool Equals(Vector2 x, Vector2 y)
        {
            return (x.x == y.x && x.y == y.y) || (x.x == y.y && x.y == y.x);
        }
        public override int GetHashCode(Vector2 obj)
        {
            return (int)(obj.x+obj.y)*PRIME;
        }
    }

    // Returns a list of all edges in the mesh defined by given points and faces.
    // Each edge is represented by Vector4(p1, p2, f1, f2)
    // p1, p2 are the edge vertices
    // f1, f2 are faces incident to the edge. If the edge belongs to one face only, f2 is -1
    public static List<Vector4> GetEdges(CCMeshData mesh)
    {
        Vec2Comparer comparer = new Vec2Comparer();
        Dictionary<Vector2, Vector2> edges_dict = new Dictionary<Vector2, Vector2>(comparer);
        for (int index = 0; index < mesh.faces.Count; index++)
        {
            Vector4 face = mesh.faces[index];
            for (int i = 0; i < 4; i++)
            {
                int index_vertex = (int)face[i], index_vertex2 = (int)face[(i + 1) % 4];
                Vector2 key = new Vector2(index_vertex, index_vertex2);
                if (edges_dict.ContainsKey(key))
                    edges_dict[key] = new Vector2(edges_dict[key].x, index);
                else
                    edges_dict[key] = new Vector2(index, -1);
            }
        }
        List<Vector4> edges = new List<Vector4>();
        foreach (Vector2 key in edges_dict.Keys)
            edges.Add(new Vector4(key.x, key.y, edges_dict[key].x, edges_dict[key].y));
        return edges;
    }

    // Returns a list of "face points" for the given CCMeshData, as described in the Catmull-Clark algorithm 
    public static List<Vector3> GetFacePoints(CCMeshData mesh)
    {
        List<Vector3> facePoints = new List<Vector3>();
        for (int i = 0; i < mesh.faces.Count; i++)
        {
            Vector4 face = mesh.faces[i];
            facePoints.Add((mesh.points[(int)face[0]] + mesh.points[(int)face[1]] +
                mesh.points[(int)face[2]] + mesh.points[(int)face[3]]) / 4);
        }
        return facePoints;
    }

    // Returns a list of "edge points" for the given CCMeshData, as described in the Catmull-Clark algorithm 
    public static List<Vector3> GetEdgePoints(CCMeshData mesh)
    {
        List<Vector3> edgePoints = new List<Vector3>();
        for (int i = 0; i < mesh.edges.Count; i++)
        {
            Vector4 edge = mesh.edges[i];
            if (edge.w != -1)
                edgePoints.Add((mesh.points[(int)edge.x] + mesh.points[(int)edge.y] + //vertex
                    mesh.facePoints[(int)edge.z] + mesh.facePoints[(int)edge.w]) / 4); //facesPoints
            else
                edgePoints.Add((mesh.points[(int)edge.x] + mesh.points[(int)edge.y] + //vertex
                    mesh.facePoints[(int)edge.z]) / 3); //facesPoints
        }
        return edgePoints;
    }

    // Returns a list of new locations of the original points for the given CCMeshData, as described in the CC algorithm 
    public static List<Vector3> GetNewPoints(CCMeshData mesh)
    {
        List<Vector3> newPoints = new List<Vector3>();
        for(int index = 0; index < mesh.points.Count; index++)
        {
            HashSet<int> face_indecies = new HashSet<int>();
            Vector3 p = mesh.points[index];
            Vector3 f = new Vector3();
            Vector3 r = new Vector3();
            for (int edge_index = 0; edge_index < mesh.edges.Count; edge_index++)
            {
                Vector4 edge = mesh.edges[edge_index];
                if ((int)edge.x != index && (int)edge.y != index) continue;

                r += (mesh.points[(int)edge.x] + mesh.points[(int)edge.y])/2;

                int edge_int = (int)edge.z;
                if (!face_indecies.Contains(edge_int)) { 
                    face_indecies.Add(edge_int);
                    f += mesh.facePoints[edge_int];
                }
                edge_int = (int)edge.w;
                if (!face_indecies.Contains(edge_int))
                {
                    face_indecies.Add(edge_int);
                    f += mesh.facePoints[edge_int];
                }
            }
            int n = face_indecies.Count;
            f /= n;r /= n;
            newPoints.Add((f+2*r+(n-3)*p)/n);
        }
        return newPoints;
    }
}

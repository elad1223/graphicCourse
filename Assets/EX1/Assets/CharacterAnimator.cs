using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Animations;
using UnityEngine.XR;

public class CharacterAnimator : MonoBehaviour
{
    public TextAsset BVHFile; // The BVH file that defines the animation and skeleton
    public bool animate; // Indicates whether or not the animation should be running

    private BVHData data; // BVH data of the BVHFile will be loaded here
    private int currFrame = 0; // Current frame of the animation
    private float time=0;
    // Start is called before the first frame update
    void Start()
    {
        BVHParser parser = new BVHParser();
        data = parser.Parse(BVHFile);

        CreateJoint(data.rootJoint, Vector3.zero);
    }

    // Returns a Matrix4x4 representing a rotation aligning the up direction of an object with the given v
    Matrix4x4 RotateTowardsVector(Vector3 v)
    {
        Vector3 normalized = v.normalized;

        float tethaX = Mathf.Atan2(normalized.z, normalized.y) * Mathf.Rad2Deg;
        Matrix4x4 XRotationM = MatrixUtils.RotateX(-tethaX);

        float yCoordinateOnXY = Mathf.Sqrt((normalized.y * normalized.y) + (normalized.z * normalized.z));

        Vector3 projectionOnYx = new Vector3(normalized.x, yCoordinateOnXY, 0);
        float tethaZ = Mathf.Atan2(projectionOnYx.x, projectionOnYx.y) * Mathf.Rad2Deg;
        Matrix4x4 ZRotationM = MatrixUtils.RotateZ(tethaZ);

        Matrix4x4 R = XRotationM.inverse * ZRotationM.inverse;
        return R;
    }

    // Creates a Cylinder GameObject between two given points in 3D space
    GameObject CreateCylinderBetweenPoints(Vector3 p1, Vector3 p2, float diameter)
    {
        GameObject Bone = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
        Vector3 line = p1 - p2;
        float length = Vector3.Distance(p1, p2)/2f;

        Matrix4x4 translateM = Matrix4x4.Translate(p2 + (line/2f));
        Matrix4x4 rotationM = RotateTowardsVector(line);
        Matrix4x4 scaleM = Matrix4x4.Scale(new Vector3(diameter, length, diameter));

        MatrixUtils.ApplyTransform(Bone, translateM * rotationM * scaleM);

        return Bone;
    }

    // Creates a GameObject representing a given BVHJoint and recursively creates GameObjects for it's child joints
    GameObject CreateJoint(BVHJoint joint, Vector3 parentPosition)
    {
        joint.gameObject = new GameObject(joint.name);
        GameObject sphere = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        sphere.transform.parent = joint.gameObject.transform;
        Matrix4x4 ScaleM = MatrixUtils.Scale(joint.name=="Head"?
                                                new Vector3(8,8,8):
                                                new Vector3(2,2,2));
        MatrixUtils.ApplyTransform(sphere, ScaleM);
         Vector3 LocationWorld = joint.offset + parentPosition;
        Matrix4x4 poistionM = MatrixUtils.Translate(LocationWorld);

        MatrixUtils.ApplyTransform(joint.gameObject, poistionM);
        
        foreach(BVHJoint childJoint in joint.children)
        {
            GameObject child = CreateJoint(childJoint, LocationWorld);
            if (childJoint.isEndSite)
                child.transform.parent = joint.gameObject.transform;
            GameObject bone = CreateCylinderBetweenPoints(LocationWorld, childJoint.offset + LocationWorld, 0.5f);
            bone.transform.parent = joint.gameObject.transform;


        }
        return joint.gameObject;
    }

    // Transforms BVHJoint according to the keyframe channel data, and recursively transforms its children
    private void TransformJoint(BVHJoint joint, Matrix4x4 parentTransform, float[] keyframe)
    {
        float xPos = keyframe[joint.positionChannels[0]];
        float yPos = keyframe[joint.positionChannels[1]];
        float zPos = keyframe[joint.positionChannels[2]];
        Matrix4x4 translationM = MatrixUtils.Translate(
            MatrixUtils.CheckEquality(Matrix4x4.identity,parentTransform)?
            new Vector3(xPos,yPos,zPos):
            joint.offset);

        Vector3Int order2Axis = new Vector3Int();
        for (int order = 0; order < 3; order++)
            order2Axis[joint.rotationOrder[order]] = order;

        Vector3 rotations = new Vector3();
        for (int i = 0; i < 3; i++)
            rotations[i] = keyframe[joint.rotationChannels[i]];
        Matrix4x4 xRotM = MatrixUtils.RotateX(rotations[0]);
        Matrix4x4 yRotM = MatrixUtils.RotateY(rotations[1]);
        Matrix4x4 zRotM = MatrixUtils.RotateZ(rotations[2]);
        Matrix4x4[] RotationMArray = { xRotM, yRotM, zRotM };

        Matrix4x4 rotationM = Matrix4x4.identity;
        for (int order = 0; order < 3; order++) //multi order
            rotationM *= RotationMArray[order2Axis[order]];
        

        Matrix4x4 overallChangeMatrix = parentTransform * translationM * rotationM;
        MatrixUtils.ApplyTransform(joint.gameObject, overallChangeMatrix);
    
        foreach (BVHJoint childJoint in joint.children)
            if (!childJoint.isEndSite)
                TransformJoint(childJoint, overallChangeMatrix, keyframe    );
    }

    // Update is called once per frame
    void Update()
    {
        if (animate)
        {
            time += Time.deltaTime;
            if (time > data.frameLength)
            {
                time -= data.frameLength;
                currFrame++;
                if (currFrame >= data.numFrames)
                    currFrame = 0;

                TransformJoint(data.rootJoint, Matrix4x4.identity, data.keyframes[currFrame]);
            }
            // Your code here
        }
    }
}

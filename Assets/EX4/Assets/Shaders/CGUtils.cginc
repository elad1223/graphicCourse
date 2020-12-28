#ifndef CG_UTILS_INCLUDED
#define CG_UTILS_INCLUDED

#define PI 3.141592653

// A struct containing all the data needed for bump-mapping
struct bumpMapData
{ 
    float3 normal;       // Mesh surface normal at the point
    float3 tangent;      // Mesh surface tangent at the point
    float2 uv;           // UV coordinates of the point
    sampler2D heightMap; // Heightmap texture to use for bump mapping
    float du;            // Increment size for u partial derivative approximation
    float dv;            // Increment size for v partial derivative approximation
    float bumpScale;     // Bump scaling factor
};


// Receives pos in 3D cartesian coordinates (x, y, z)
// Returns UV coordinates corresponding to pos using spherical texture mapping
float2 getSphericalUV(float3 pos)
{
    // Your implementation
    return 0;
}

// Implements an adjusted version of the Blinn-Phong lighting model
fixed3 blinnPhong(float3 n, float3 v, float3 l, float shininess, fixed4 albedo, fixed4 specularity, float ambientIntensity)
{
    // Your implementation
    fixed4 ambientC = ambientIntensity * albedo;
    fixed4 diffuseC = max(0, dot(n, l)) * albedo;
    fixed3 halfway = (l + v) / 2;
    fixed4 specularC = pow(max(0, dot(n, halfway)), shininess) * specularity;
    return ambientC + diffuseC + specularC;
}

// Returns the world-space bump-mapped normal for the given bumpMapData
float3 getBumpMappedNormal(bumpMapData i)
{
    // Your implementation
    float3 b = cross(i.normal, i.tangent);
    float heightNormal = tex2D(i.heightMap, i.uv + fixed2(i.du, i.dv)).x;
    float3 normal_h = mul(unity_ObjectToWorld, i.normal);
    //heightNormal = normalize(heightNormal * 2 - 1);
    float3 normal_bump = 
        i.tangent * normal_h.x + i.normal * normal_h.z * i.bumpScale + b * normal_h.y;
    return normalize(normal_bump);
}


#endif // CG_UTILS_INCLUDED

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
    float2 uv;
    pos = normalize(pos);
    uv.x = atan2(pos.z, pos.x) / (2*PI); 
    uv.y = (0.5 + (asin(pos.y) / PI));
    return uv;
}

// Implements an adjusted version of the Blinn-Phong lighting model
fixed3 blinnPhong(float3 n, float3 v, float3 l, float shininess, fixed4 albedo, fixed4 specularity, float ambientIntensity)
{
    /*
    fixed4 ambientC = ambientIntensity * albedo;
    fixed4 diffuseC = max(0, dot(n, l)) * albedo;
    fixed3 halfway = (l + v) / 2;
    fixed4 specularC = pow(max(0, dot(n, halfway)), shininess) * specularity;
    return ambientC + diffuseC + specularC;
    */

    
    float3 normal = normalize(n);
    float lightAngle = dot(l, normal);

    fixed4 ambientC = ambientIntensity * albedo;
    fixed4 diffuseC = max(0, lightAngle) * albedo;
    fixed3 halfway = normalize((l + v)/2);
    fixed4 specularC = fixed4(0.0, 0.0, 0.0, 0.0);  // deafult
    if (lightAngle >= 0.0) {
        // some light is projected from the object to the viewer
        specularC = pow(max(0.0, dot(normal, halfway)), shininess) * specularity;
    }
    return ambientC + diffuseC + specularC;
    
}

// Returns the world-space bump-mapped normal for the given bumpMapData
float3 getBumpMappedNormal(bumpMapData i)
{
    half4 c = tex2D(i.heightMap, i.uv);
    float uDerivative = (tex2D(i.heightMap, i.uv + float2(i.du, 0)) - c) / i.du;
    float vDerivative = (tex2D(i.heightMap, i.uv + float2(0, i.dv)) - c) / i.dv;

    float3 normalHeight = normalize(float3(-i.bumpScale * uDerivative, -i.bumpScale * vDerivative, 1.0));
    float3 b = cross(i.tangent, i.normal);
    float3 normalHeightWorld = (i.tangent * normalHeight.x + i.normal * normalHeight.z + b * normalHeight.y);
    return normalHeightWorld;
}


#endif // CG_UTILS_INCLUDED

// Implements an adjusted version of the Blinn-Phong lighting model
float3 blinnPhong(float3 n, float3 v, float3 l, float shininess, float3 albedo)
{
    float3 diffuse = max(dot(n, l), 0) * albedo;
    float3 h = normalize(l + v);
    float3 specular = pow(max(0, dot(n, h)), shininess) * 0.4;
    return diffuse + specular;
}

// Reflects the given ray from the given hit point
void reflectRay(inout Ray ray, RayHit hit)
{
    ray.origin = hit.position;
    ray.direction = 2 * dot(-ray.direction, hit.normal) * hit.normal + ray.direction;
    ray.energy *= hit.material.specular;
}

// Refracts the given ray from the given hit point
void refractRay(inout Ray ray, RayHit hit)
{
    ray.origin = hit.position;
    float refractionDirection = dot(hit.normal, ray.direction);
    float refractCoefficient = 1 / hit.material.refractiveIndex;
    if (refractionDirection > 0) {
        hit.normal = - hit.normal;
        refractCoefficient = 1 / refractCoefficient;
    }
    float c1 = abs(refractionDirection);
    float c2 = sqrt(1 - (1 - (c1 * c1)));
    float t = refractCoefficient * ray.direction + (refractCoefficient * c1 - c2) * hit.normal;
    ray.direction = t;
}

// Samples the _SkyboxTexture at a given direction vector
float3 sampleSkybox(float3 direction)
{
    float theta = acos(direction.y) / -PI;
    float phi = atan2(direction.x, -direction.z) / -PI * 0.5f;
    return _SkyboxTexture.SampleLevel(sampler_SkyboxTexture, float2(phi, theta), 0).xyz;
}
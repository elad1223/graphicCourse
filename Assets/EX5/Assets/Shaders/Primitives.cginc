// Checks for an intersection between a ray and a sphere
// The sphere center is given by sphere.xyz and its radius is sphere.w
void intersectSphere(Ray ray, inout RayHit bestHit, Material material, float4 sphere)
{
    ray.direction = normalize(ray.direction);
    float3 origin_center = (ray.origin - sphere.xyz);
    float B = 2 * dot(origin_center, ray.direction);
    float C = dot(origin_center, origin_center) - (sphere.w * sphere.w);
    float D = B * B - (4 * C);
    if (D >= 0 ) {
        float sqrtD = sqrt(D);
        float t0 = -B + sqrtD;
        float t1 = -B - sqrtD;
        if (t1 > 0) {
            t0 = t1;
        }
        if (bestHit.distance > (t0 / 2) && t0>=0) {
            bestHit.distance = (t0 / 2);
            bestHit.position = ray.origin + ray.direction * bestHit.distance;
            bestHit.normal = normalize(bestHit.position - sphere.xyz);
            bestHit.material = material;
        }
    }
}

// Checks for an intersection between a ray and a plane
// The plane passes through point c and has a surface normal n
void intersectPlane(Ray ray, inout RayHit bestHit, Material material, float3 c, float3 n)
{
    ray.direction = normalize(ray.direction);
    float nDir = dot(ray.direction, n);
    if (nDir < 0 && bestHit.distance > -dot((ray.origin - c), n) / nDir) {
        bestHit.distance = -dot((ray.origin - c), n)/nDir;
        bestHit.position = ray.origin + ray.direction * bestHit.distance;
        bestHit.normal = n;
        bestHit.material = material;
    }
}

Material metiralLarp(Material m1, Material m2, float t) {
    Material c;
    c.albedo = t * (m1.albedo) + (1 - t) * m2.albedo;
    c.specular = t * (m1.specular) + (1 - t) * m2.specular;
    c.refractiveIndex = t * (m1.refractiveIndex) + (1 - t) * m2.refractiveIndex;
    return c;
}
// Interpolates a given array v of 4 float2 values using bicubic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
//
// [0]=====o==[1]
//         |
//         t
//         |
// [2]=====o==[3]
//
Material bicubicInterpolation(Material v[4], float2 t)
{
    float2 u = t; 
    // Interpolate in the x direction
    Material x1 = metiralLarp(v[0], v[1], u.x);
    Material x2 = metiralLarp(v[2], v[3], u.x);

    // Interpolate in the y direction and return
    return metiralLarp(x1, x2, u.y);
}
Material checkerPlane(Material m1, Material m2, float2 position) {
    if ((floor(2 * position.x) + floor(2 * position.y)) % 2 == 0)
        return m1;
    return m2;
}
// Checks for an intersection between a ray and a plane
// The plane passes through point c and has a surface normal n
// The material returned is either m1 or m2 in a way that creates a checkerboard pattern 
void intersectPlaneCheckered(Ray ray, inout RayHit bestHit, Material m1, Material m2, float3 c, float3 n)
{
    ray.direction = normalize(ray.direction);
    float nDir = dot(ray.direction, n);
    if (nDir < 0 && bestHit.distance > -dot((ray.origin - c), n) / nDir) {
        bestHit.distance = -dot((ray.origin - c), n) / nDir;
        bestHit.position = ray.origin + ray.direction * bestHit.distance;
        bestHit.normal = n;
        
        Material array[4];
        float2 left_bottom_corner = float2(floor(bestHit.position.x), floor(bestHit.position.z));
        for (uint i = 0; i < 4; i++)
            array[i] = checkerPlane(m1,m2,left_bottom_corner + float2(i%2, i / 2));
        //bestHit.material= bicubicInterpolation(array, float2(frac(bestHit.position.x), frac(bestHit.position.z)));
        bestHit.material = checkerPlane(m1, m2, float2(bestHit.position.x, bestHit.position.z));
    }
}


// Checks for an intersection between a ray and a triangle
// The triangle is defined by points a, b, c
void intersectTriangle(Ray ray, inout RayHit bestHit, Material material, float3 a, float3 b, float3 c)
{
    float3 normal = normalize(cross(a - c, b - c));
    float nDir = dot(ray.direction, normal);
    float t = (-dot((ray.origin - c), normal)) / nDir;
    float3 position = ray.origin + ray.direction * t;
    if (dot(cross(b - a, position - a), normal) >= 0 &&
        dot(cross(c - b, position - b), normal) >= 0 &&
        dot(cross(a - c, position - c), normal) >= 0 &&
        bestHit.distance > t &&
        t>=0) {

        bestHit.distance = t;
        bestHit.position = position;
        bestHit.normal = normal;
        bestHit.material = material;
    }
}


// Checks for an intersection between a ray and a 2D circle
// The circle center is given by circle.xyz, its radius is circle.w and its orientation vector is n 
void intersectCircle(Ray ray, inout RayHit bestHit, Material material, float4 circle, float3 n)
{
    float3 origin_center = (ray.origin - circle.xyz);
    ray.direction = normalize(ray.direction);
    float nDir = dot(ray.direction, n);
    if (nDir >= 0)return;
    float B = 2 * dot(origin_center, ray.direction);
    float C = dot(origin_center, origin_center) - circle.w * circle.w;
    float D = B * B - 4 * C;
    float t = -dot(origin_center, n) / nDir;
    if (D >= 0 && nDir < 0 &&
        bestHit.distance > t && t>=0) {

        float sqrtD = sqrt(D);
        float t0 = (-B + sqrtD)/2;
        float t1 = (-B - sqrtD)/2;
        float final_t = -1;
        if ((t>t1 && t0>t)|| (t > t0 && t1 > t)) {
            final_t = t;
        }
        if (bestHit.distance > final_t && final_t>0) {
            bestHit.distance = final_t;
            bestHit.position = ray.origin + ray.direction * bestHit.distance;
            bestHit.normal = n;
            bestHit.material = material;
        }
    }
}


// Checks for an intersection between a ray and a cylinder aligned with the Y axis
// The cylinder center is given by cylinder.xyz, its radius is cylinder.w and its height is h
void intersectCylinderY(Ray ray, inout RayHit bestHit, Material material, float4 cylinder, float h)
{
    float4 topCircle = cylinder;
    topCircle.y = cylinder.y + 0.5*h;
    float4 bottomCircle = cylinder;
    bottomCircle.y = cylinder.y - 0.5*h;
    float3 circleNormal = float3(0.0, 1.0, 0.0);  // need to find correct oriantation

    float3 origin_center = float3(ray.origin - cylinder.xyz);
    origin_center.y = 0;
    float3 dir_xz = float3(ray.direction.x, 0, ray.direction.z);
    float A = dot(dir_xz, dir_xz);
    float B = 2 * dot(dir_xz, origin_center);
    float C = dot(origin_center, origin_center) - (cylinder.w * cylinder.w);
    float D = B * B - (4 * A * C);
    if (D >= 0) {
        float sqrtD = sqrt(D);
        float t0 = (-B + sqrtD)/(2*A);
        float t1 = (-B - sqrtD)/(2*A);
        if (t1 > 0) {
            t0 = t1;
        }
        float3 position = ray.origin + ray.direction * t0;
        if (position.y >= bottomCircle.y && position.y <= topCircle.y
            && bestHit.distance > t0 && t0>0) {

            bestHit.distance = t0;
            bestHit.position = position;
            bestHit.normal = normalize(bestHit.position - float3(cylinder.x, position.y, cylinder.z));
            bestHit.material = material;
        }
    }
    intersectCircle(ray, bestHit, material, topCircle, circleNormal);
    intersectCircle(ray, bestHit, material, bottomCircle, -circleNormal);
}

// Checks for an intersection between a ray and a sphere
// The sphere center is given by sphere.xyz and its radius is sphere.w
void intersectSphere(Ray ray, inout RayHit bestHit, Material material, float4 sphere)
{
    ray.direction = normalize(ray.direction);
    float3 origin_center = (ray.origin - sphere.xyz);
    float A = 1;
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
        //
        // float3 c = floor(bestHit.position) / 2;
        //if (frac(c.x + c.z) * 2) {
        if((floor(2 * bestHit.position.x) + floor(2 * bestHit.position.z)) % 2 == 0){
            bestHit.material = m1;
        }
        else {
            bestHit.material = m2;
        }
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
    float B = 2 * dot(origin_center, ray.direction);
    float C = dot(origin_center, origin_center) - circle.w * circle.w;
    float D = B * B - 4 * C;
    if (D >= 0 && nDir < 0 &&
        bestHit.distance > -dot((ray.origin - circle.xyz), n) / nDir) {
        bestHit.distance = -dot((ray.origin - circle.xyz), n) / nDir;//(min(abs(-B + sqrt(D)), abs(-B - sqrt(D)))) / 2;
        bestHit.position = ray.origin + ray.direction * bestHit.distance;
        bestHit.normal = n;
        bestHit.material = material;
    }
}


// Checks for an intersection between a ray and a cylinder aligned with the Y axis
// The cylinder center is given by cylinder.xyz, its radius is cylinder.w and its height is h
void intersectCylinderY(Ray ray, inout RayHit bestHit, Material material, float4 cylinder, float h)
{
    float4 topCircle = cylinder;
    topCircle.y = cylinder.y + 0.5 * h;
    float4 bottomCircle = cylinder;
    bottomCircle.y = cylinder.y - 0.5 * h;
    float3 circleNormal = float3(0.0, 0.5, 0.0);  // need to find correct oriantation

    float A = (ray.direction.x * ray.direction.x) + (ray.direction.z * ray.direction.z);
    float B = 2 * ((ray.origin.x - cylinder.x) * ray.direction.x +
        (ray.origin.z - cylinder.z) * ray.direction.z);
    float C = ((ray.origin.x - cylinder.x) * (ray.origin.x - cylinder.x)) +
        ((ray.origin.z - cylinder.z) * (ray.origin.z - cylinder.z)) - (cylinder.w * cylinder.w);
    float D = B * B - (4 * A * C);
    if (D >= 0) {
        float sqrtD = sqrt(D);
        float t0 = -B + sqrtD;
        float t1 = -B - sqrtD;
        if (t1 > 0) {
            t0 = t1;
        }
        float3 position = ray.origin + ray.direction * t0;
        if ((position.y >= bottomCircle.y) && (position.y <= topCircle.y)) {

            bestHit.distance = (t0 / 2);
            bestHit.position = ray.origin + ray.direction * bestHit.distance;
            bestHit.normal = normalize(bestHit.position - cylinder.xyz);
            bestHit.material = material;
        }
    }
    intersectCircle(ray, bestHit, material, topCircle, circleNormal);
    intersectCircle(ray, bestHit, material, bottomCircle, circleNormal);

    /*
    //float3 origin_center_y = float3(0,ray.origin.y - cylinder.y,0);
    ray.direction = normalize(ray.direction);
    //float3 ray_y = float3(0, ray.direction.y, 0);
    //float A1 = dot(ray_y,ray_y);
    //float B1 = 2 * dot(origin_center_y, ray_y);
    //float C1 = dot(origin_center_y, origin_center_y) - (h*h)/32;
    //float D1 = B1 * B1 - 4 * C1 * A1;
    //if (D1 < 0)return;

    float3 origin_center_xz = float3(ray.origin.x - cylinder.x, 0, ray.origin.z - cylinder.z);
    float3 ray_xz = float3(ray.direction.x, 0, ray.direction.z);
    float A2 = dot(ray_xz,ray_xz);
    float B2 = 2 * dot(origin_center_xz, ray_xz);
    float C2 = dot(origin_center_xz, origin_center_xz) - (cylinder.w * cylinder.w);
    float D2 = B2 * B2 - 4 * C2 * A2;
    if (D2 < 0)return;
    if (bestHit.distance > (-B2 + sqrt(D2)) / (2 * A2)) {
        float sqrtD = sqrt(D2);
        float t0 = -B2 + sqrtD;
        float t1 = -B2 - sqrtD;
        if (t1 > 0) t0 = t1;
        float t = t0 / 2;
        float3 position = ray.origin + ray.direction * bestHit.distance;
        if (abs(position.y - cylinder.y) <= 0.5 * h)
        {
            bestHit.distance = t0 / 2;//(min(abs(-B + sqrt(D)), abs(-B - sqrt(D)))) / 2;
            bestHit.position = ray.origin + ray.direction * bestHit.distance;
            bestHit.normal = normalize(bestHit.position - cylinder.xyz);
            bestHit.material = material;
        }
       
    }*/
}

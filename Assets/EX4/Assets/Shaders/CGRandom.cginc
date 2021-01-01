#ifndef CG_RANDOM_INCLUDED
// Upgrade NOTE: excluded shader from DX11 because it uses wrong array syntax (type[size] name)
#pragma exclude_renderers d3d11
#define CG_RANDOM_INCLUDED

// Returns a psuedo-random float between -1 and 1 for a given float c
float random(float c)
{
    return -1.0 + 2.0 * frac(43758.5453123 * sin(c));
}

// Returns a psuedo-random float2 with componenets between -1 and 1 for a given float2 c 
float2 random2(float2 c)
{
    c = float2(dot(c, float2(127.1, 311.7)), dot(c, float2(269.5, 183.3)));

    float2 v = -1.0 + 2.0 * frac(43758.5453123 * sin(c));
    return v;
}

// Returns a psuedo-random float3 with componenets between -1 and 1 for a given float3 c 
float3 random3(float3 c)
{
    float j = 4096.0 * sin(dot(c, float3(17.0, 59.4, 15.0)));
    float3 r;
    r.z = frac(512.0*j);
    j *= .125;
    r.x = frac(512.0*j);
    j *= .125;
    r.y = frac(512.0*j);
    r = -1.0 + 2.0 * r;
    return r.yzx;
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
float bicubicInterpolation(float2 v[4], float2 t)
{
    float2 u = t * t * (3.0 - 2.0 * t); // Cubic interpolation

    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    // Interpolate in the y direction and return
    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 4 float2 values using biquintic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
float biquinticInterpolation(float2 v[4], float2 t)
{
    float2 u = t * t * t * (10.0 + t * (-15.0  + t * 6.0)); // Cubic interpolation

   // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    // Interpolate in the y direction and return
    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 8 float3 values using triquintic interpolation
// at the given ratio t (a float3 with components between 0 and 1)
//       [4]=======[5]
//     -  |       - |
// [0]=====o==[1]   o
//  |     |    |    |
//  o    [6]===o===[7]
//  |  -       | -
// [2]=====o==[3]
//
float triquinticInterpolation(float3 v[8], float3 t)
{
    float3 u = t; //linear
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);
    float x3 = lerp(v[4], v[5], u.x);
    float x4 = lerp(v[6], v[7], u.x);

    float y1 = lerp(x1, x2, u.y);
    float y2 = lerp(x3, x4, u.y);

    return lerp(y1,y2,u.z);
}

// Returns the value of a 2D value noise function at the given coordinates c
float value2d(float2 c)
{
    float2 array[4];
    float2 left_bottom_corner = float2(floor(c.x), floor(c.y));
    for (uint i = 0; i < 4; i++) 
        array[i] = random2(left_bottom_corner + float2(fmod(i, 2), i / 2));
    return bicubicInterpolation(array,float2(frac(c.x),frac(c.y)));
}

// Returns the value of a 2D Perlin noise function at the given coordinates c
float perlin2d(float2 c)
{
    float2 array[4];
    float2 left_corner = float2(floor(c.x), floor(c.y));
    float2 temp;
    for (uint i = 0; i < 4; i++) {
        temp = left_corner + float2(fmod(i, 2), i/ 2);
        array[i] = dot(random2(temp), temp - c);
    }
    return biquinticInterpolation(array, float2(frac(c.x), frac(c.y)));
}

// Returns the value of a 3D Perlin noise function at the given coordinates c
float perlin3d(float3 c)
{                    
    float3 array[8];
    float3 left_bottom_corner = float3(floor(c.x), floor(c.y),floor(c.z));
    float3 temp;
    for (uint i = 0; i < 8; i++) {
        temp = left_bottom_corner + float3(fmod(i, 2), fmod(i / 2, 2), i / 4);
        array[i] = dot(random3(temp), temp - c);
    }
    return triquinticInterpolation(array,float3(frac(c.x),frac(c.y),frac(c.z)));
}


#endif // CG_RANDOM_INCLUDED

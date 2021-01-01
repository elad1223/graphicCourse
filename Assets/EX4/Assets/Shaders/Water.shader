Shader "CG/Water"
{
    Properties
    {
        _CubeMap("Reflection Cube Map", Cube) = "" {}
        _NoiseScale("Texture Scale", Range(1, 100)) = 10 
        _TimeScale("Time Scale", Range(0.1, 5)) = 3 
        _BumpScale("Bump Scale", Range(0, 0.5)) = 0.05
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "CGUtils.cginc"
                #include "CGRandom.cginc"

                #define DELTA 0.01

                // Declare used properties
                uniform samplerCUBE _CubeMap;
                uniform float _NoiseScale;
                uniform float _TimeScale;
                uniform float _BumpScale;

                struct appdata
                { 
                    float4 vertex   : POSITION;
                    float3 normal   : NORMAL;
                    float4 tangent  : TANGENT;
                    float2 uv       : TEXCOORD0;
                };

                struct v2f
                {
                    float4 pos      : SV_POSITION;
                    float3 normal   : NORMAL;
                    float4 tangent  : TANGENT;
                    float4 vertex   : COORD0;
                    float2 uv       : TEXCOORD0;
                };

                // Returns the value of a noise function simulating water, at coordinates uv and time t
                float waterNoise(float2 uv, float t)
                {
                    // Your implementation
                    return perlin3d(float3(uv * 0.5, t * 0.5)) +
                        0.5 * perlin3d(float3(uv, t)) + 
                        0.2 * perlin3d(float3(2 * uv, 3 * t));
                }

                // Returns the world-space bump-mapped normal for the given bumpMapData and time t
                float3 getWaterBumpMappedNormal(bumpMapData i, float t)
                {
                    // Your implementation
                    float3 b = cross(i.normal, i.tangent);
                    float heightNormal = waterNoise(i.uv + float2(i.du, i.dv), t);
                    float3 normal_h = mul(unity_ObjectToWorld, i.normal);
                    heightNormal = normalize(heightNormal * 2 - 1);
                    float3 normal_bump =
                        i.tangent * normal_h.x + i.normal * normal_h.z * i.bumpScale + b * normal_h.y;
                    return normalize(normal_bump);
                }
                /*struct bumpMapData
                {
                    float3 normal;       // Mesh surface normal at the point
                    float3 tangent;      // Mesh surface tangent at the point
                    float2 uv;           // UV coordinates of the point
                    sampler2D heightMap; // Heightmap texture to use for bump mapping
                    float du;            // Increment size for u partial derivative approximation
                    float dv;            // Increment size for v partial derivative approximation
                    float bumpScale;     // Bump scaling factor
                };*/


                v2f vert (appdata input)
                {
                    v2f output;
                    float2 noise = (waterNoise(input.uv * _NoiseScale, _Time.y * _TimeScale)) / 2 + 0.5;
                    input.vertex.y += noise * _BumpScale;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.normal = input.normal;
                    output.tangent = input.tangent;
                    output.vertex = input.vertex;
                    output.uv = input.uv;
                    return output;
                }

                fixed4 frag(v2f input) : SV_Target
                {
                    bumpMapData bmd;
                    bmd.normal = input.normal;
                    bmd.tangent = input.tangent.xyz;
                    bmd.uv = input.uv;
                    bmd.du = DELTA;
                    bmd.dv = DELTA;
                    bmd.bumpScale = _BumpScale;
                    float3 new_normal = getWaterBumpMappedNormal(bmd, _Time.y * _TimeScale);
                    float3 viewPoint = normalize(_WorldSpaceCameraPos - input.vertex);
                    float dotNormalView = dot(new_normal, viewPoint);
                    float3 reflaction = 2 * dotNormalView * new_normal - viewPoint;
                    float4 ReflectedColor = texCUBE(_CubeMap, reflaction);
                    return  (1.2 - max(0, dotNormalView)) * ReflectedColor;
                }

            ENDCG
        }
    }
}

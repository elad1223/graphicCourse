Shader "CG/Earth"
{
    Properties
    {
        [NoScaleOffset] _AlbedoMap ("Albedo Map", 2D) = "defaulttexture" {}
        _Ambient ("Ambient", Range(0, 1)) = 0.15
        [NoScaleOffset] _SpecularMap ("Specular Map", 2D) = "defaulttexture" {}
        _Shininess ("Shininess", Range(0.1, 100)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "defaulttexture" {}
        _BumpScale ("Bump Scale", Range(1, 100)) = 30
        [NoScaleOffset] _CloudMap ("Cloud Map", 2D) = "black" {}
        _AtmosphereColor ("Atmosphere Color", Color) = (0.8, 0.85, 1, 1)
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "CGUtils.cginc"

                // Declare used properties
                uniform sampler2D _AlbedoMap;
                uniform float _Ambient;
                uniform sampler2D _SpecularMap;
                uniform float _Shininess;
                uniform sampler2D _HeightMap;
                uniform float4 _HeightMap_TexelSize;
                uniform float _BumpScale;
                uniform sampler2D _CloudMap;
                uniform fixed4 _AtmosphereColor;

                struct appdata
                { 
                    float4 vertex : POSITION;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    float3 localPos : TEXCOORD0;
                    float3 worldPos : TEXCOORD1;
                };

                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.localPos = input.vertex.xyz;
                    output.worldPos = mul(unity_ObjectToWorld, input.vertex).xyz;
                    return output;
                }

                fixed4 frag(v2f input) : SV_Target
                {
                    float2 uv = getSphericalUV(input.localPos);
                    float3 normal = normalize(input.worldPos);  // the earth is a sphere
                    float3 viewPoint = normalize(_WorldSpaceCameraPos - input.worldPos);
                    
                    float3 Lambert = max(0.0, dot(normal, _WorldSpaceLightPos0));
                    float3 Atmosphere = (1 - max(0.0, dot(normal, viewPoint))) * sqrt(Lambert) * _AtmosphereColor;
                    float3 Clouds = tex2D(_CloudMap, uv) * (sqrt(Lambert) + _Ambient);


                    bumpMapData bmd;
                    bmd.normal = normal;
                    bmd.tangent = cross(normal, float3(0,1,0));
                    bmd.uv = uv;
                    bmd.heightMap = _HeightMap;
                    bmd.du = _HeightMap_TexelSize.x;
                    bmd.dv = _HeightMap_TexelSize.y;
                    bmd.bumpScale = _BumpScale / 10000;
                    float3 normal_h = getBumpMappedNormal(bmd);
                    float3 finalNormal = ((1 - tex2D(_SpecularMap,uv)) * normal_h) + (tex2D(_SpecularMap, uv) * normal);
                    

                    half4 albedo = tex2D(_AlbedoMap, uv);
                    half4 specular = tex2D(_SpecularMap, uv);
                    return fixed4(blinnPhong(
                        finalNormal, viewPoint, _WorldSpaceLightPos0, _Shininess, albedo, specular, _Ambient) + Atmosphere + Clouds,
                            1);
                }

            ENDCG
        }
    }
}

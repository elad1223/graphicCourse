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
                    float3 position : COORD0;
                };

                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.position = input.vertex.xyz;
                    return output;
                }

                fixed4 frag(v2f input) : SV_Target
                {
                    float2 uv = getSphericalUV(input.position);
                    //return  tex2D(_AlbedoMap, uv);
                    float3 normal = normalize(input.position);
                    float3 viewPoint = normalize(_WorldSpaceCameraPos - input.pos);
                    /*
                    bumpMapData bmd;
                    bmd.normal = normal;
                    bmd.tangent = cross(normal,(0,1,0));
                    bmd.uv = uv;
                    bmd.heightMap = _HeightMap;
                    bmd.du = _HeightMap_TexelSize[2];
                    bmd.dv = _HeightMap_TexelSize[3];
                    bmd.bumpScale = _BumpScale / 10000;
                    float3 normal_h = getBumpMappedNormal(bmd);
                    */
                    return fixed4(blinnPhong(normal, viewPoint, _WorldSpaceLightPos0,
                        _Shininess, tex2D(_AlbedoMap, uv), tex2D(_SpecularMap, uv), _Ambient), 1);
                        
                }

            ENDCG
        }
    }
}

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "CG/Bricks"
{
    Properties
    {
        [NoScaleOffset] _AlbedoMap ("Albedo Map", 2D) = "defaulttexture" {}
        _Ambient ("Ambient", Range(0, 1)) = 0.15
        [NoScaleOffset] _SpecularMap ("Specular Map", 2D) = "defaulttexture" {}
        _Shininess ("Shininess", Range(0.1, 100)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "defaulttexture" {}
        _BumpScale ("Bump Scale", Range(-100, 100)) = 40
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

                struct appdata
                { 
                    float4 vertex   : POSITION;
                    float3 normal   : NORMAL;
                    float4 tangent  : TANGENT;
                    float2 uv       : TEXCOORD0;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    float2 uv  : TEXCOORD0;
                    float3 normal : NORMAL;
                    float4 tangent  : TANGENT;
                };

                v2f vert (appdata input)
                {
                    v2f output;
                    output.uv = input.uv;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.normal = input.normal;
                    output.tangent = input.tangent;
                    return output;
                }

                fixed4 frag(v2f input) : SV_Target
                {

                    //normal_h = mul(unity_ObjectToWorld, normal_h);
                    /*
                    bumpMapData bmd;
                    bmd.normal = input.normal;
                    bmd.tangent = input.tangent.xyz;
                    bmd.uv = input.uv;
                    bmd.heightMap = _HeightMap;
                    bmd.du = _HeightMap_TexelSize[2];
                    bmd.dv = _HeightMap_TexelSize[3];
                    bmd.bumpScale = _BumpScale / 10000;
                    float3 normal_h = getBumpMappedNormal(bmd);
                    */
                    float3 viewPoint = normalize(_WorldSpaceCameraPos - input.pos);
                    return fixed4(blinnPhong(input.normal, viewPoint, _WorldSpaceLightPos0,
                        _Shininess,tex2D(_AlbedoMap,input.uv),tex2D(_SpecularMap, input.uv),_Ambient),1);
                }

            ENDCG
        }
    }
}

Shader "CG/BlinnPhongGouraud"
{
    Properties
    {
        _DiffuseColor ("Diffuse Color", Color) = (0.14, 0.43, 0.84, 1)
        _SpecularColor ("Specular Color", Color) = (0.7, 0.7, 0.7, 1)
        _AmbientColor ("Ambient Color", Color) = (0.05, 0.13, 0.25, 1)
        _Shininess ("Shininess", Range(0.1, 50)) = 10
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

                // From UnityCG
                uniform fixed4 _LightColor0; 

                // Declare used properties
                uniform fixed4 _DiffuseColor;
                uniform fixed4 _SpecularColor;
                uniform fixed4 _AmbientColor;
                uniform float _Shininess;

                struct appdata
                { 
                    float4 vertex : POSITION;
                    float3 normal : NORMAL;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    fixed4 color : TEXCOORD0;
                };


                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex);

                    // the light in our program is directional, so we can assume its constant
                    float3 lightDirection = normalize(_WorldSpaceLightPos0);
                    float3 surfaceNormal = normalize(mul(input.normal, unity_WorldToObject));
                    // the position of the vertex in the world coordinates
                    float3 worldPos = mul(unity_ObjectToWorld, input.vertex).xyz;
                    float3 viewPoint = normalize(_WorldSpaceCameraPos - worldPos);
                    // calculate the halfway vector used in the Blinn-Phong model
                    float3 halfway = (lightDirection + viewPoint) / length(lightDirection + viewPoint);

                    // now we will calculate the ambient, diffuse and specular vectors
                    // that as used to get the Phong Lighting
                    float3 ambient = _LightColor0.rgb * _AmbientColor.rgb;
                    float3 diffuse = 
                        max(0.0, dot(lightDirection, surfaceNormal)) * _LightColor0.rgb * _DiffuseColor.rgb;
                    float specularReflectance;
                    if (dot(surfaceNormal, lightDirection) < 0.0) {
                        // meaning the light source is in the otherside, so no specals are visible
                        specularReflectance = float3(0.0, 0.0, 0.0);
                    }
                    else {
                        specularReflectance = pow(max(0.0, dot(surfaceNormal, halfway)), _Shininess);
                    }
                    output.color = fixed4((ambient + diffuse + specularReflectance), 1);
                    return output;
                }


                fixed4 frag (v2f input) : SV_Target
                {
                    return input.color;
                }

            ENDCG
        }
    }
}

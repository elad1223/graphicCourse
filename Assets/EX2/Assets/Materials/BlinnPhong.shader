Shader "CG/BlinnPhong"
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
                    float3 normal : NORMAL;
                    float3 worldPos : TEXCOORD0;
                };


                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.worldPos = normalize(mul(unity_ObjectToWorld, input.vertex).xyz);
                    output.normal = normalize(mul(input.normal, unity_WorldToObject));
                    return output;
                }


                fixed4 frag (v2f input) : SV_Target
                {
                    // the light in our program is directional, so we can assume its constant
                    float3 lightDirection = _WorldSpaceLightPos0;
                    float3 surfaceNormal = input.normal;
                    // the position of the vertex in the world coordinates
                    float3 viewPoint = normalize(_WorldSpaceCameraPos - input.worldPos);
                    // calculate the halfway vector used in the Blinn-Phong model
                    float3 halfway = normalize(lightDirection + viewPoint);

                    // now we will calculate the ambient, diffuse and specular vectors
                    // that as used to get the Phong Lighting
                    float3 ambient = _LightColor0.rgb * _AmbientColor.rgb;
                    float lightAngle = dot(lightDirection, surfaceNormal);
                    float3 diffuse = max(0.0, lightAngle) * _LightColor0.rgb * _DiffuseColor.rgb;

                    float3 specularReflectance = float3(0.0, 0.0, 0.0);  // deafult
                    if (lightAngle >= 0.0) {
                        // some light is projected from the object to the viewer
                        specularReflectance = pow(max(0.0, dot(surfaceNormal, halfway)), _Shininess)
                            * _LightColor0.rgb * _SpecularColor.rgb;
                    }
                    fixed4 color = fixed4((ambient + diffuse + specularReflectance), 1);
                    return color;
                }

            ENDCG
        }
    }
}

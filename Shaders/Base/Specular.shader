Shader "Unlit/Specular"
{
    Properties
    {
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Specular ("Specular", Range(0, 90)) = 30
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            uniform float4 _Color;
            uniform float _Specular;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD0;
                float3 posWorld : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 lDir = normalize(_WorldSpaceLightPos0.xyz - i.posWorld);
                // float3 lDir = normalize(UnityWorldSpaceLightDir(i.posWorld));
                float3 lReflectDir = reflect(-lDir, i.normal);
                float3 vDir = normalize(_WorldSpaceCameraPos.xyz - i.posWorld);
                // float3 vDir = normalize(UnityWorldSpaceViewDir(i.posWorld));
                float lDotV = dot(lReflectDir, vDir) * 0.5 + 0.5;
                float specular = pow(lDotV, _Specular);
                float3 half = normalize(normalize(lDir) + vDir);
                float bpDot = dot(half, normalize(i.normal)) * 0.5 + 0.5;
                // float specular = pow(bpDot, _Specular);

                float diffuse = dot(i.normal, lDir) * 0.5 + 0.5;
                float4 diffuseColor = float4(diffuse * _Color.xyz, 1);
                float4 specularColor = float4(specular, specular, specular, 1);
                return diffuseColor + specularColor;
                
            }
            ENDCG
        }
    }
}

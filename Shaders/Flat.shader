Shader "Unlit/Flat"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Spec ("Spec", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(0, 90)) = 1
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

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 worldPos: TEXCOORD1;
            };

            float4 _Diffuse;
            float4 _Spec;
            float _Gloss;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(cross(ddy(i.worldPos), ddx(i.worldPos)));
                float3 lDirWS = UnityWorldSpaceLightDir(i.worldPos);
                float3 diffuse = _Diffuse * (dot(normal, lDirWS) * 0.5 + 0.5);
                float3 rDirWS = reflect(-lDirWS, normal);
                float3 vDirWS = normalize(UnityWorldSpaceViewDir(i.worldPos));
                float3 specular = _Spec * pow((dot(rDirWS, vDirWS) * 0.5 + 0.5), _Gloss);
                return float4(diffuse + specular, 1);
            }
            ENDCG
        }
    }
}

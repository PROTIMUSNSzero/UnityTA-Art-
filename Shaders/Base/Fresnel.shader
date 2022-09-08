Shader "Unlit/Fresnel"
{
    Properties
    {
        _FresnelPow("FresnelPow", Range(0, 10)) = 3
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
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal: TEXCOORD0;
                float3 posWS: TEXCOORD1;
            };

            float _FresnelPow;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 vDirWS = normalize(UnityWorldSpaceViewDir(i.posWS));
                float vDotn = dot(normalize(i.normal), vDirWS) * 0.5 + 0.5;
                float fresnel = pow(1 - vDotn, _FresnelPow);
                return float4(fresnel, fresnel, fresnel, 1);
            }
            ENDCG
        }
    }
}

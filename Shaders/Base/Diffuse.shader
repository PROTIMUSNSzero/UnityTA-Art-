Shader "Unlit/Diffuse"
{
    Properties
    {
        _Color("Color", Color) = (1.0, 1.0, 1.0, 1.0)
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

            uniform fixed4 _Color; 

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal: TEXCOORD0;
                float posWorld: TEXCOORD1;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 nDir = normalize(i.normal);
                float3 lDir = normalize(_WorldSpaceLightPos0.xyz - i.posWorld);
                // float final = max(0.0, dot(nDir, lDir));
                float final = dot(nDir, lDir) * 0.5 + 0.5;
                float3 lamb = float3(final, final, final) * _Color;
                return fixed4(lamb, 1);
            }
            ENDCG
        }
    }
}

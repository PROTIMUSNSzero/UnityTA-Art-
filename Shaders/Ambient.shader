Shader "Unlit/Ambient"
{
    Properties
    {
        _EnvUpCol("EnvUpColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _EnvSideCol("EnvSideColor", Color) = (1.0, 1.0, 1.0, 1.0)
        _EnvDownCol("EnvDownColor", Color) = (1.0, 1.0, 1.0, 1.0)
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

            float4 _EnvUpCol;
            float4 _EnvSideCol;
            float4 _EnvDownCol;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal: TEXCOORD1;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {

                float envUp = max(0.0, i.normal.y);
                float envDown = max(0.0, -i.normal.y);
                float envSide = 1 - envUp - envDown;

                float4 col = envUp * _EnvUpCol + envDown * _EnvDownCol + envSide * _EnvSideCol;
                // 与ao贴图相乘 col * tex2D(ao, i.uv)
                return float4(col.xyz, 1);
            }
            ENDCG
        }
    }
}

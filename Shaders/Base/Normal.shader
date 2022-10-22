Shader "Unlit/Normal"
{
    Properties
    {
        _UVTex ("UVTex", 2D) = "white" {}
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
                float3 normal: NORMAL;
                float3 tangent: TANGENT;
                float3 bitangent: TEXCOORD1;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal: TEXCOORD1;
                float3 tangent: TEXCOORD2;
                float3 bitangent: TEXCOORD3;
            };

            sampler2D _UVTex;
            float4 _UVTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = normalize(UnityObjectToWorldNormal(v.normal));
                o.tangent = normalize(mul(unity_ObjectToWorld, v.tangent));
                o.bitangent = normalize(cross(o.normal, o.tangent));
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3x3 TBN = float3x3(i.tangent, i.bitangent, i.normal);
                // 采样法线纹理并解码
                fixed3 nDir = UnpackNormal(tex2D(_UVTex, i.uv)).xyz;
                float3 nDirWS = mul(nDir, TBN);
                float3 lDirWS = normalize(UnityWorldSpaceLightDir(i.vertex));
                float diffuse = dot(nDirWS, lDirWS) * 0.5 + 0.5;
                return float4(diffuse, diffuse, diffuse, 1);
            }
            ENDCG
        }
    }
}

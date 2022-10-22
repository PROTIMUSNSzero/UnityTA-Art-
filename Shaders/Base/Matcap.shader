Shader "Unlit/Matcap"
{
    Properties
    {
        _NormalMap ("Normal", 2D) = "white" {}
        _MatcapMap ("Matcap", 2D) = "white" {}
        // 设为0则无菲涅尔效果
        _FresnelPow ("Fresnel", Range(0, 10)) = 1
        _EnvSpec ("EnvSpec", Range(0, 10)) = 1
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 posWS: TEXCOORD1;
                float3 normal: TEXCOORD2;
                float3 tangent: TEXCOORD3;
                float3 bitangent: TEXCOORD4;
            };

            sampler2D _NormalMap;
            float4 _NormalMap_ST;
            sampler2D _MatcapMap;
            float _FresnelPow;
            float _EnvSpec;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.posWS = normalize(mul(unity_ObjectToWorld, o.vertex));
                o.uv = TRANSFORM_TEX(v.uv, _NormalMap);
                o.normal = normalize(UnityObjectToWorldNormal(v.normal));
                o.tangent = normalize(mul(unity_ObjectToWorld, v.tangent));
                o.bitangent = normalize(cross(o.normal, o.tangent));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 texNormal = UnpackNormal(tex2D(_NormalMap, i.uv)).rgb;
                float3x3 TBN = float3x3(i.tangent, i.bitangent, i.normal);
                float3 nDirWS = normalize(mul(texNormal, TBN));
                float3 nDirVS = mul(UNITY_MATRIX_V, float4(nDirWS, 0)).xyz;
                float3 vDirWS = normalize(UnityWorldSpaceViewDir(i.posWS));
                // 法线向量测试  rgb向量(-1, 1)，转为(0, 1)查看颜色
                // return float4(nDirWS * 0.5 + 0.5, 1);
                // rgb向量(-1, 1)，须转为(0, 1)
                float2 matcapUV = nDirVS.rg * 0.5 + 0.5;
                float3 matcap = tex2D(_MatcapMap, matcapUV);
                float nDotv = dot(nDirWS, vDirWS) * 0.5 + 0.5;
                float fresnel = pow(1 - nDotv, _FresnelPow);
                float3 envSpecLight = matcap * fresnel * _EnvSpec;
                return float4(envSpecLight, 1);
            } 
            ENDCG
        }
    }
}

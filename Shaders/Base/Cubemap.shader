Shader "Unlit/Cubemap"
{
    Properties
    {
        _Cubemap ("Cubemap", Cube) = "_Skybox" {}
        _CubemapMip ("CubemapMip", Range(0, 7)) = 0
        _NormalMap ("NormalMap", 2D) = "white" {}
        _FresnelPow ("FresnelPow", Range(0, 10)) = 1
        _EnvSpec ("EnvSpec", Range(0, 5)) = 1
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
                float4 tangent: TANGENT;
                
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal: TEXCOOR1;
                float3 tangent: TEXCOORD2;
                float3 bitangent: TEXCOORD3;
                float3 posWS: TEXCOORD4;
            };

            samplerCUBE _Cubemap;
            float _CubemapMip;
            sampler2D _NormalMap;
            float4 _NormalMap_ST;
            float _FresnelPow;
            float _EnvSpec;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _NormalMap);
                o.posWS = normalize(mul(unity_ObjectToWorld, v.vertex));
                o.normal = normalize(UnityObjectToWorldNormal(v.normal));
                o.tangent = normalize(mul(unity_ObjectToWorld, v.tangent.xyz));
                o.bitangent = normalize(cross(o.normal, o.tangent) * v.tangent.w);
                // o.bitangent = normalize(cross(o.normal, o.tangent));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3x3 TBN = float3x3(i.tangent, i.bitangent, i.normal);
                float3 nDirTS = UnpackNormal(tex2D(_NormalMap, i.uv)).rgb;
                float3 nDirWS = normalize(mul(nDirTS, TBN));
                float3 vDirWS = normalize(UnityWorldSpaceViewDir(i.posWS));
                float3 rDirWS = reflect(-vDirWS, nDirWS);
                float nDotv = dot(vDirWS, nDirWS) * 0.5 + 0.5;
                float fresnel = pow(1 - nDotv, _FresnelPow);
                float3 cubemap = texCUBElod(_Cubemap, float4(rDirWS, _CubemapMip));
                float3 col = cubemap * fresnel * _EnvSpec;
                return float4(col, 1);
            }
            ENDCG
        }
    }
}

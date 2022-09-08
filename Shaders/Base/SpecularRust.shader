Shader "Unlit/SpecularRust"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DiffuseColorIron ("DiffuseColorIron", Color) = (1.0, 1.0, 1.0, 1.0)
        _DiffuseColorRust ("DiffuseColorRust", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularIron ("SpecularIron", Range(0, 90)) = 30
        _SpecularRust ("SpecularRust", Range(0, 90)) = 30
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal: TEXCOORD1;
                float3 posWorld: TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _DiffuseColorIron;
            float4 _DiffuseColorRust;
            float _SpecularIron;
            float _SpecularRust;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(i.normal);
                float3 lDir = normalize(UnityWorldSpaceLightDir(i.posWorld));
                float3 rlDir = reflect(-lDir, normal);
                float3 vDir = normalize(UnityWorldSpaceViewDir(i.posWorld));
                float diff = dot(normal, lDir) * 0.5 + 0.5;
                float tex = step(0.5, tex2D(_MainTex, i.uv).r);
                float4 diffCol = lerp(_DiffuseColorIron, _DiffuseColorRust, tex);
                float4 diffuse = diff * diffCol;
                float spec = dot(rlDir, vDir) * 0.5 + 0.5;
                fixed specPow = lerp(_SpecularIron, _SpecularRust, tex);
                float specular = pow(spec, specPow);
                float4 specularCol = float4(specular, specular, specular, 1);
                return diffuse + specularCol;
            }
            ENDCG
        }
    }
}

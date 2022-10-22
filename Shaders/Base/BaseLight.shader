Shader "Unlit/BaseLight"
{
    Properties
    {
        _BaseColor("BaseColor", Color) = (1, 1, 1, 1)
        _LightCol("LightColor", Color) = (1, 1, 1, 1)
        _SpecPow("SpecularColor", Range(1, 90)) = 10
        _Occlusion("Occlusion", 2D) = "white" {}
        _EnvIntensity("EnvIntensity", Range(0, 1)) = 0.1
        _EnvUpColor("EnvUpColor", Color) = (1, 1, 1, 1)
        _EnvDownColor("EnvDownColor", Color) = (1, 1, 1, 1)
        _EnvSideColor("EnvSideColor", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0

            uniform float3 _BaseColor;
            uniform float3 _LightCol;
            uniform float _SpecPow;
            uniform sampler2D _Occlusion;
            uniform float _EnvIntensity;
            uniform float3 _EnvUpColor;
            uniform float3 _EnvDownColor;
            uniform float3 _EnvSideColor;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 posWS: TEXCOORD1;
                float3 nDirWS: TEXCOORD2;
                LIGHTING_COORDS(3, 4)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 nDir = normalize(i.nDirWS);
                float3 lDir = normalize(UnityWorldSpaceLightDir(i.posWS));
                float3 vDir = normalize(UnityWorldSpaceViewDir(i.posWS));
                float3 rDir = reflect(-lDir, nDir);

                float shadow = LIGHT_ATTENUATION(i);
                float diffuse = dot(nDir, lDir) * 0.5 + 0.5;
                float3 diffuseCol = diffuse * _BaseColor * _LightCol;
                float specular = pow(dot(rDir, vDir) * 0.5 + 0.5, _SpecPow);
                float3 specularCol = specular * _LightCol;
                float3 directLight = (diffuseCol + specularCol); // * shadow;

                float upMask = max(0, nDir.y);
                float downMask = max(0, -nDir.y);
                float sideMask = 1 - upMask - downMask;
                float3 ambient = upMask * _EnvUpColor + downMask * _EnvDownColor + sideMask * _EnvSideColor;
                float3 ambientCol = ambient * _BaseColor * _EnvIntensity;

                float3 ambientColor = tex2D(_MainTex, i.uv).xyz * ambientCol;
                return float4(directLight + ambientColor, 1);
            }
            ENDCG
        }
    }
}

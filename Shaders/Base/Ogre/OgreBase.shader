Shader "Unlit/OgreBase"
{
    Properties
    {
        _BaseColorTex ("BaseColorTex", 2D) = "white" {}
        _NormalTex ("NormalTex", 2D) = "bump" {}
        _Cubemap ("Cubemap", cube) = "_Skybox" {}
        _SpecularTex ("SpecularTex", 2D) = "gray" {}
        _SpecularMask ("SpecularMask", 2D) = "gray" {}
        _OcculusionMask ("OcculusionMask", 2D) = "gray" {}
        _EmitTex ("EmitTex", 2D) = "balck" {}
        _BaseMask ("BaseMask", 2D) = "black" {}
        [PowerSlider(2)] _SpecularPow ("SpecularPow", Range(0, 90)) = 10
        _SpecInt ("SpecInt", Range(0, 10)) = 1
        [PowerSlider(2)] _FresnelPow ("FresnelPow", Range(0, 10)) = 10
        _CubemapMip ("CubemapMip", Range(0, 7)) = 0
        _EmitStrength ("EmitStrength", Range(0, 10)) = 1
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
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

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
                float3 nDirWS: TEXCOORD1;
                float3 tDirWS: TEXCOORD2;
                float3 bDirWS: TEXCOORD3;
                float3 posWS: TEXCOORD4;

            };

            sampler2D _BaseColorTex;
            sampler2D _NormalTex;
            samplerCUBE _Cubemap;
            sampler2D _SpecularTex;
            sampler2D _SpecularMask;
            sampler2D _OcculusionMask;
            sampler2D _EmitTex;
            sampler2D _BaseMask;

            float _SpecularPow;
            float _FresnelPow;
            float _CubemapMip;
            float _EmitStrength;
            float _EnvSpec;
            float _SpecInt;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.nDirWS = normalize(UnityObjectToWorldNormal(v.normal));
                o.tDirWS = normalize(mul(unity_ObjectToWorld, v.tangent));
                o.bDirWS = normalize(cross(o.nDirWS, o.tDirWS));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 rUV = float2(i.uv.x, 1 - i.uv.y);
                float3 n = UnpackNormal(tex2D(_NormalTex, i.uv)) * float3(1, -1, 1);
                float3x3 TBN = float3x3(i.tDirWS, i.bDirWS, i.nDirWS);
                float3 nDirWS = normalize(mul(n, TBN));
                fixed4 baseCol = tex2D(_BaseColorTex, i.uv);
                float3 lDirWS = normalize(UnityWorldSpaceLightDir(i.posWS));
                float3 lambert = dot(nDirWS, lDirWS) * 0.5 + 0.5;
                float3 diffuse = baseCol * lambert * _LightColor0;

                float3 rlDirWS = normalize(reflect(-lDirWS, nDirWS));
                float3 vDirWS = normalize(UnityWorldSpaceViewDir(i.posWS));
                float3 phong = dot(rlDirWS, vDirWS) * 0.5 + 0.5;
                float3 specCol = tex2D(_SpecularTex, i.uv);
                float specMask = tex2D(_SpecularMask, rUV).r;
                float specularPow = lerp(1, _SpecularPow, specMask);
                float3 spec = pow(phong, specularPow);
                float baseMask = tex2D(_BaseMask, rUV).r;
                float3 maskCol = lerp(_LightColor0, baseCol, specCol);
                float3 specular = spec * maskCol * _SpecInt;

                float occulusion = tex2D(_OcculusionMask, rUV).r;
                float fresnel = pow(1 - (dot(vDirWS, nDirWS) * 0.5 + 0.5), _FresnelPow);
                float3 rvDirWS = normalize(reflect(-vDirWS, nDirWS));
                float mip = lerp(_CubemapMip, 0, specMask);
                float3 cubemapCol = texCUBElod(_Cubemap, float4(rvDirWS, mip));
                float3 envSpecular = cubemapCol * fresnel * _EnvSpec * occulusion;

                float3 emit = tex2D(_EmitTex, rUV).r * baseCol * _EmitStrength;

                return float4(diffuse + specular + envSpecular + emit, 1);
            }
            ENDCG
        }
    }
}

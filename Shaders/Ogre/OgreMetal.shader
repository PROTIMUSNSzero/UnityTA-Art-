Shader "Unlit/OgreMetal"
{
    Properties
    {
        _BaseColorTex ("BaseColorTex", 2D) = "white" {}
        _NormalTex ("NormalTex", 2D) = "bump" {}
        _Cubemap ("Cubemap", cube) = "_Skybox" {}
        _SpecularTex ("SpecularTex", 2D) = "gray" {}
        _SpecExponentMask ("高光次幂mask", 2D) = "gray" {}
        _RimLightMask ("边缘光mask", 2D) = "gray" {}
        _TintByBaseMask ("高光染色mask", 2D) = "black" {}
        _EmitTex ("EmitTex", 2D) = "balck" {}
        _MetalTex ("MetalTex", 2D) = "gray" {}
        [PowerSlider(2)] _SpecularPow ("SpecularPow", Range(0, 90)) = 10
        _SpecInt ("SpecInt", Range(0, 10)) = 1
        [PowerSlider(2)] _FresnelPow ("FresnelPow", Range(0, 10)) = 10
        _CubemapMip ("CubemapMip", Range(0, 7)) = 0
        _EnvSpec ("EnvSpec", Range(0, 10)) = 1
        _EmitStrength ("EmitStrength", Range(0, 10)) = 1

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
            sampler2D _SpecExponentMask;
            sampler2D _RimLightMask;
            sampler2D _EmitTex;
            sampler2D _TintByBaseMask;
            sampler2D _MetalTex;

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
                float3 specCol = tex2D(_SpecularTex, rUV);
                float specPowCol = tex2D(_SpecExponentMask, rUV).r;
                float specularPow = lerp(1, _SpecularPow, specPowCol);
                float3 spec = pow(phong, specularPow);
                float TintByBaseMask = tex2D(_TintByBaseMask, rUV).r;
                float3 maskCol = lerp(baseCol, _LightColor0, specCol);
                float metalCol = tex2D(_MetalTex, rUV).r;
                float3 specular = spec * maskCol * metalCol * _SpecInt;

                float occulusion = tex2D(_RimLightMask, rUV).r;
                float fresnel = pow(1 - (dot(vDirWS, nDirWS) * 0.5 + 0.5), _FresnelPow);
                float3 rvDirWS = normalize(reflect(-vDirWS, nDirWS));
                float mip = lerp(_CubemapMip, 0, specPowCol);
                float3 cubemapCol = texCUBElod(_Cubemap, float4(rvDirWS, mip));
                float3 envSpecular = cubemapCol * fresnel * _EnvSpec * occulusion;

                float3 emit = tex2D(_EmitTex, rUV).r * baseCol * _EmitStrength;

                return float4(diffuse + specular + envSpecular + emit, 1);
            }
            ENDCG
        }
    }
}

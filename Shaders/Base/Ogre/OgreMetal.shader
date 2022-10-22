Shader "Unlit/OgreMetal"
{
    Properties
    {
        _MainTex ("MainTex", 2D) = "white" {}
        _MaskTex ("MaskTex(高光强度、边缘光遮罩、染色遮罩、高光次幂(光滑度))", 2D) = "white" {}
        _NormalTex ("NormalTex", 2D) = "bump" {}
        _Cubemap ("Cubemap", cube) = "_Skybox" {}
        _EmitTex ("EmitTex", 2D) = "balck" {}
        _MetalTex ("MetalTex", 2D) = "black" {}
        _DiffuseWarp ("漫反射rampTex", 2D) = "white" {}
        _WarpTex ("WarpTex(菲涅尔颜色、边缘光、高光)", 2D) = "white" {}

        [PowerSlider(2)] _SpecularPow ("SpecularPow", Range(0, 90)) = 10
        _SpecInt ("SpecInt", Range(0, 10)) = 1
        _EmitStrength ("EmitStrength", Range(0, 10)) = 1
        _EnvCol ("EnvColor", Color) = (1, 1, 1, 1)
        _EnvSpecInt ("Env Specular Intensity", Range(0, 30)) = 1
        [HDR] _RimCol ("Rim Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="TransparentCutout" 
            "ForceNoShadowCasting" = "True" 
            "IgnoreProjector" = "True"
        }
        LOD 100

        Pass
        {
            Cull Off
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
                float4 tangent: TANGENT;
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

            sampler2D _MainTex;
            sampler2D _MaskTex;
            sampler2D _NormalTex;
            samplerCUBE _Cubemap;
            sampler2D _EmitTex;
            sampler2D _MetalTex;
            sampler2D _DiffuseWarp;
            sampler2D _WarpTex;

            float _SpecularPow;
            float _EmitStrength;
            float _SpecInt;
            float4 _EnvCol;
            float _EnvSpecInt;
            float4 _RimCol;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.nDirWS = normalize(UnityObjectToWorldNormal(v.normal));
                o.tDirWS = normalize(mul(unity_ObjectToWorld, v.tangent.xyz));
                o.bDirWS = normalize(cross(o.nDirWS, o.tDirWS) * v.tangent.w);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 n = UnpackNormal(tex2D(_NormalTex, i.uv));
                float3x3 TBN = float3x3(i.tDirWS, i.bDirWS, i.nDirWS);
                float3 nDirWS = normalize(mul(n, TBN));
                float3 lDirWS = normalize(UnityWorldSpaceLightDir(i.posWS));
                float3 rlDirWS = normalize(reflect(-lDirWS, nDirWS));
                float3 vDirWS = normalize(UnityWorldSpaceViewDir(i.posWS));
                float3 rvDirWS = normalize(reflect(-vDirWS, nDirWS));

                float nDotv = (dot(vDirWS, nDirWS));
                float halfLambert = dot(nDirWS, lDirWS) * 0.5 + 0.5;

                fixed4 mainTex = tex2D(_MainTex, i.uv);
                float4 maskCol = tex2D(_MaskTex, i.uv);
                float metallic = tex2D(_MetalTex, i.uv).r;
                // lerp用于削弱金属的菲涅尔效果
                float3 warpCol = lerp(tex2D(_WarpTex, nDotv), 0, metallic);
                float diffWarp = tex2D(_DiffuseWarp, float2(halfLambert, 0.2));
                float emitCol = tex2D(_EmitTex, i.uv).r;

                float3 baseCol = mainTex.rgb;
                float opaque = mainTex.a;
                float specInt = maskCol.r;
                float rimInt = maskCol.g;
                float tintCol = maskCol.b;
                float specPow = maskCol.a;
                float fresnelRim = warpCol.g;
                float fresnelSpec = warpCol.b;

                clip(opaque - 0.5);
                
                // 金属的漫反射效果弱
                float3 diff = lerp(baseCol, half3(0, 0, 0), metallic);
                float3 diffuse = diff * diffWarp * _LightColor0;

                float3 phong = dot(rlDirWS, vDirWS) * 0.5 + 0.5;
                float spec = pow(phong, specPow * _SpecularPow);
                // 结合环境高光的frenelSpecWarp一同计算
                spec = max(spec, fresnelSpec) * _SpecInt;
                // 染色值越大，高光越趋向黑灰色（非金属，0.3为经验值，配合specInt使用），否则趋向基础颜色（金属）
                float3 specTintCol = lerp(baseCol, half3(0.3, 0.3, 0.3), tintCol) * specInt;
                float3 specular = spec * specTintCol * _LightColor0;
                
                float3 envDiffuse = diff * _EnvCol;

                float mip = lerp(8, 0, specPow);
                float3 cubemapCol = texCUBElod(_Cubemap, float4(rvDirWS * float3(1, -1, 1), mip));
                // 反射度：金属部分metallic较大，非金属部分fresnelSpec较大
                half reflectInt = max(fresnelSpec, metallic) * specInt;
                half3 envSpecular = cubemapCol * reflectInt * _EnvSpecInt * specTintCol;
                // nDirWS.g 只保留朝上的轮廓光
                float3 rimLight = _RimCol * fresnelRim * rimInt * max(0, nDirWS.g);
          
                float3 emit = emitCol * baseCol * _EmitStrength;

                return float4(diffuse + specular + envDiffuse + envSpecular + rimLight + emit, 1);
            }
            ENDCG
        }
    }
    fallback "Diffuse"
}

// 主光带投影，环境光带AO，AO用rimMask代替实现
// 漫反射：主光（halfLambert + warp）、环境光（单色环境光简化）；用染色贴图处理
// 镜面反射：主光（phong）、环境光（cubemap + fresnelSpecWarp）；用金属度贴图处理
// 轮廓光（fresnelRimWarp）
// 自发光
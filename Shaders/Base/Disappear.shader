Shader "Unlit/Disappear"
{
    Properties
    {
        [Header(Textures)]
        _MainTex ("MainTex", 2D) = "white" {}
        [Normal] _NormalTex ("Normal", 2D) = "bump" {}
        _SpecTex ("SpecTex", 2D) = "gray" {}
        // 自发光
        _EmitTex ("EmitTex", 2D) = "black" {}
        _Cubemap ("Cubemap", cube) = "_Skybox" {}
        [Header(Diffuse)]
        _MainColor ("MainColor", Color) = (1, 1, 1, 1)
        _EnvDiffuse ("EnvDiffuse", Range(0, 1)) = 0.2
        [HDR] _EnvUpCol ("EnvUpCol", Color) = (1, 1, 1, 1)
        _EnvSideCol ("EnvSideCol", Color) = (1, 1, 1, 1)
        _EnvDownCol ("EnvDownCol", Color) = (1, 1, 1, 1)
        [Header(Specular)]
        [PowerSlider(2)] _SpecPow ("SpecPow", Range(0, 90)) = 1
        _EnvSpec ("EnvSpec", Range(0, 10)) = 1
        _FresnelPow ("FresnelPow", Range(0, 10)) = 1
        _CubemapMip ("CubemapMip", Range(0, 7)) = 0
        [Header(Emission)]
        _Emit ("Emit", Range(0, 10)) = 1

        [Header(Effect)]
        _EftMap0 ("特效纹理0", 2D) = "gray" {}
        // x：网格高亮 y：消散透明度mask（强随机） z：消散透明度mask（面坡度）
        _EftMap1 ("特效纹理1", 2D) = "gray" {}
        [HDR] _EftCol ("特效颜色", Color) = (0, 0, 0, 0)
        _EftPars ("波密度 波速度 混乱度 消散强度", Vector) = (1, 1, 1, 1)

    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "RenderType"="Transparent"
        }
        LOD 100

        Pass
        {
            Name "FORWARD"
            Tags 
            {
                "LightMode"="ForwardBase"
            }
            Blend one OneMinusSrcAlpha
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float2 uv1: TEXCOORD1;
                float3 normal: NORMAL;
                float4 tangent: TANGENT; 
                float3 color: COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 posWS: TEXCOORD1;
                float3 tangent: TEXCOORD2;
                float3 bitangent: TEXCOORD3;
                float3 normal: TEXCOORD4;
                float2 uv1: TEXCOOR5;
                // LIGHTING_COORDS(5, 6)
                float4 effectMask: TEXCOORD6;
            };

            // Textures
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalTex;
            sampler2D _SpecTex;
            // 自发光
            sampler2D  _EmitTex;
            samplerCUBE _Cubemap;
            // Diffuse
            float4 _MainColor;
            float _EnvDiffuse;
            float4 _EnvUpCol;
            float4 _EnvSideCol;
            float4 _EnvDownCol;
            // Specular
            float _SpecPow;
            float _EnvSpec;
            float _FresnelPow;
            float _CubemapMip;
            // Emission
            float _Emit;

            //Eft
            sampler2D _EftMap0;
            sampler2D _EftMap1;
            float4 _EftCol;
            float4 _EftPars;

            float4 disappearAnim(float noise, float mask, float3 normal, inout float3 vertex)
            {
                // 0 - 1, 0 - 1 ...
                // float baseMask = frac(vertex.y);
                // -0.5 - 0.5, -0.5 - 0.5 ...
                // baseMask -= 0.5;
                // 波形 0 - 1 - 0 - 1 ...
                // baseMask = abs(baseMask) * 2;
                float baseMask = abs(frac(vertex.y * _EftPars.x - _Time.x * _EftPars.y) - 0.5) * 2;
                // 梯型波
                baseMask = min(1, baseMask * 2);
                // 偏移
                baseMask += (noise - 0.5) * _EftPars.z;

                float4 effectMask = float4(0, 0, 0, mask);
                // 生成0-1的平滑过渡，3rd参数小于1st参数时返回0，大于2nd参数时返回1，否则返回（0-1）之间的平滑值
                effectMask.x = smoothstep(0, 0.9, baseMask);
                effectMask.y = smoothstep(0.2, 0.7, baseMask);
                effectMask.z = smoothstep(0.4, 0.5, baseMask);

                // 顶点动画 透明位置带动不透明位置横向扩散，不透明位置不动
                vertex.xz += normal.xz * (1 - effectMask.y) * _EftPars.w * mask;

                return effectMask;
            }

            v2f vert (appdata v)
            {
                // 顶点shader内采样，tex2Dlod也可采样mipmap
                float noise = tex2Dlod(_EftMap1, float4(v.uv1, 0, 0)).r;
                v2f o;
                o.effectMask = disappearAnim(noise, v.color.r, v.normal.xyz, v.vertex.xyz);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv1 = v.uv1;
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.tangent = normalize(mul(unity_ObjectToWorld, v.tangent.xyz));
                o.normal = normalize(UnityObjectToWorldNormal(v.normal));
                o.bitangent = normalize(cross(o.normal, o.tangent) * v.tangent.w);
                // TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3x3 TBN = float3x3(i.tangent, i.bitangent, i.normal);
                float3 nDirWS = normalize(mul(UnpackNormal(tex2D(_NormalTex, i.uv)), TBN));
                float3 lDirWS = normalize(UnityWorldSpaceLightDir(i.posWS));
                // diffuse
                float nDotl = dot(nDirWS, lDirWS) * 0.5 + 0.5;
                float4 mainCol = tex2D(_MainTex, i.uv);
                float3 diffuse = nDotl * mainCol.rgb * _MainColor;
                // specular
                float3 rlDirWS = normalize(reflect(-lDirWS, nDirWS));
                float3 vDirWS = normalize(UnityWorldSpaceViewDir(i.posWS));
                float4 specCol = tex2D(_SpecTex, i.uv);
                // a通道值越大，次幂越接近给定值（越光滑）
                float specPow = lerp(1, _SpecPow, specCol.a);
                float spec = pow(dot(rlDirWS, vDirWS) * 0.5 + 0.5, specPow);
                float3 specular = spec * specCol.rgb ; 

                float3 directLight = (diffuse + specular) * _LightColor0;

                // env diffuse
                float3 envUp = max(nDirWS.y, 0);
                float3 envDown = max(-nDirWS.y, 0);
                float3 envUpColor = _EnvUpCol * envUp;
                float3 envDownColor = _EnvDownCol * envDown;
                float3 envSideColor = _EnvSideCol * max(1 - envUp - envDown, 0);
                float occulusion = mainCol.a;
                float3 ambient = (envUpColor + envDownColor + envSideColor) * mainCol.rgb * _MainColor * _EnvDiffuse;
                // env specular
                float vDotn = dot(vDirWS, nDirWS) * 0.5 + 0.5;
                float fresnel = pow(1 - vDotn, _FresnelPow); 
                float3 rvDirWS = normalize(reflect(-vDirWS, nDirWS));
                // a通道值越大，代表材质越光滑，插值结果越接近0，否则越粗糙，插值越接近指定的mip值
                float cubemapMip = lerp(_CubemapMip, 0, specCol.a);
                float3 cubemapCol = texCUBElod(_Cubemap, float4(rvDirWS, cubemapMip)) * _EnvSpec * fresnel * specCol.a;

                float3 envLight = (ambient + cubemapCol) * occulusion;

                // emission
                float3 emission = tex2D(_EmitTex, i.uv) * _Emit * (sin(_Time.z) * 0.5 + 0.5);

                //Eft
                float3 eftCol0 = tex2D(_EftMap0, i.uv1).xyz;
                //eftCol0提供随机性，eftMask提供周期性
                // 值保持为0或1
                float bigOpacity = saturate(floor(min(eftCol0.y, 0.9999) + i.effectMask.y));
                // 网格从边缘向中心消散
                float midOpacity = saturate(floor(min(eftCol0.z, 0.9999) + i.effectMask.z));
                float opacity = lerp(1.0, min(bigOpacity, midOpacity), i.effectMask.w);
                
                // 半透明部分网格自发光 
                float meshEmit = (i.effectMask.z - i.effectMask.x)  * eftCol0.x;
                // 亮度集中
                meshEmit *= meshEmit;
                float3 meshEmission = _EftCol.xyz * meshEmit * i.effectMask.w;
                emission += meshEmission;

                float3 finalCol = directLight + envLight + emission;

                return float4(finalCol * opacity, opacity);
            }
            ENDCG
        }
    }
    Fallback "Diffuse"
}

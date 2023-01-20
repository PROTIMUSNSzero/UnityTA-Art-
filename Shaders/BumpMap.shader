Shader "Unlit/BumpMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _HeightMap ("HeightMap", 2D) = "gray" {}
        _NormalMap ("NormalMap", 2D) = "blue" {}
        _SpecPow ("SpecPow", Range(0, 10)) = 0.5
        _BumpScale ("BumpScale", Range(0, 0.2)) = 0.05
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
                float3 vDirTS: TEXCOORD1;
                float3 lDirTS: TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _HeightMap;
            sampler2D _NormalMap;
            float _SpecPow;
            float _BumpScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float3 posWS = mul(unity_ObjectToWorld, v.vertex);
                // 模型空间下的法线、切线、副切线转到时间空间，即世界空间下的法线、切线、副切线
                float3 normal = normalize(UnityObjectToWorldNormal(v.normal));
                float3 tangent = normalize(UnityObjectToWorldDir(v.tangent.xyz));
                float3 bitangent = normalize(cross(normal, tangent) * v.tangent.w);
                // 向量从A空间转换到B空间的矩阵，即A空间下B空间的基向量组成的矩阵。世界空间到切线空间的转换矩阵，即世界空间下的切线空间基向量矩阵
                // 转换矩阵按行填充（Unity Shader默认），待转换向量左乘转换矩阵；或者转换矩阵按列填充，待转换向量右乘转换矩阵
                float3x3 W2T = float3x3(tangent, bitangent, normal);

                float3 vDirWS = normalize(UnityWorldSpaceViewDir(posWS));
                o.vDirTS = normalize(mul(W2T, vDirWS));
                float3 lDirWS = normalize(UnityWorldSpaceLightDir(posWS));
                o.lDirTS = normalize(mul(W2T, lDirWS));
                return o;
            }

            float2 normalParallexMapping(float2 uv, float3 vDirTS)
            {
                float depth = tex2D(_HeightMap, uv).r;
                float2 offset = depth * vDirTS.xy / vDirTS.z * _BumpScale;
                return uv - offset;
            }

            float2 steepParallexMapping(float2 uv, float3 vDirTS)
            {
                const float minLayer = 15;
                const float maxLayer = 30;
                float layerNum = lerp(maxLayer, minLayer, abs(dot(normalize(vDirTS), float3(0, 0, 1))));
                // 必须用1除，深度贴图最多可表示的高度为1
                float depthDelta = 1.0 / layerNum;
                float2 uvDelta = _BumpScale * depthDelta * vDirTS.xy / vDirTS.z;
                float curDepth = 0;
                float2 curUV = uv;
                float curMapDepth = tex2D(_HeightMap, curUV).r;
                for (int i = 0; i < layerNum; i++)
                {
                    if (curMapDepth <= curDepth)
                    {
                        return curUV;
                    }
                    curUV -= uvDelta;
                    curMapDepth = tex2D(_HeightMap, float4(curUV, 0, 0)).r;
                    curDepth += depthDelta;
                }
                return curUV;
            }

            // 计算阴影系数（系数越小越暗）
            float2 reliefParallexMapping(float2 uv, float3 vDirTS)
            {
                const int bisectionLimit = 5;
                const float minLayer = 15;
                const float maxLayer = 30;
                float layerNum = lerp(maxLayer, minLayer, abs(dot(normalize(vDirTS), float3(0, 0, 1))));
                float depthDelta = 1.0 / layerNum;
                float2 uvDelta = _BumpScale * depthDelta * vDirTS.xy / vDirTS.z;
                float curDepth = 0;
                float2 curUV = uv;
                float2 lastUV = curUV;
                float curMapDepth = tex2D(_HeightMap, curUV).r;
                float lastDepth = curDepth;
                for (int i = 0; i < layerNum; i++)
                {
                    if (curMapDepth <= curDepth)
                    {
                        break;
                    }
                    lastUV = curUV;
                    lastDepth = curDepth;
                    curUV -= uvDelta;
                    curMapDepth = tex2Dlod(_HeightMap, float4(curUV, 0, 0)).r;
                    curDepth += depthDelta;
                }
                float biDepth = 0;
                float2 biUV = float2(0, 0);
                int bisectionNum = bisectionLimit;
                float mapDepth = 0;
                while (bisectionNum > 0)
                {
                    bisectionNum--;
                    biUV = 0.5 * (curUV + lastUV);
                    mapDepth = tex2D(_HeightMap, biUV);
                    biDepth = (curDepth + lastDepth) * 0.5;
                    if (mapDepth < biDepth)
                    {
                        curDepth = biDepth;
                        curUV = biUV;
                    } 
                    else if (mapDepth > biDepth)
                    {
                        lastDepth = biDepth;
                        lastUV = biUV;
                    }
                    else 
                    {
                        return biUV;
                    }
                }

                return biUV;
            }

            float2 parallexOcculusionMapping (float2 uv, float3 vDirTS)
            {
                const float minLayer = 15;
                const float maxLayer = 30;
                float layerNum = lerp(maxLayer, minLayer, abs(dot(normalize(vDirTS), float3(0, 0, 1))));
                float depthDelta = 1.0 / layerNum;
                float2 uvDelta = _BumpScale * depthDelta * vDirTS.xy / vDirTS.z;
                float curDepth = 0;
                float lastDepth = curDepth;
                float2 curUV = uv + uvDelta;
                float2 lastUV = curUV;
                float curMapDepth = tex2D(_HeightMap, curUV).r;
                float lastMapDepth = curMapDepth;
                bool firstIter = true;
                for (int i = 0; i < layerNum; i++)
                {
                    if (curMapDepth <= curDepth)
                    {
                        break;
                    }
                    lastUV = curUV;
                    lastDepth = curDepth;
                    lastMapDepth = curMapDepth;
                    curUV -= uvDelta;
                    curMapDepth = tex2Dlod(_HeightMap, float4(curUV, 0, 0)).r;
                    curDepth += depthDelta;
                }

                float curH = curMapDepth - curDepth;
                float lastH = lastMapDepth - lastDepth;
                if (curH == lastH)
                {
                    curH += 1e-10;
                }
                float weight = curH / (curH - lastH);
                float2 finalUV = lastUV * weight + curUV * (1.0 - weight);
                return finalUV;
            }

            float parallexSoftShadowMultiplier (float3 lDirTS, float2 uv, float height)
            {
                const float minLayers = 10;
                const float maxLayers = 20;
                float upDotL = dot(float3(0, 0, 1), normalize(lDirTS));
                if (upDotL > 0)
                {
                    float layers = lerp(maxLayers, minLayers, upDotL);
                    float depthDelta = height / layers;
                    float2 uvDelta = depthDelta * _BumpScale * lDirTS.xy / lDirTS.z;
                    float2 curUV = uv + uvDelta;
                    float curHeight = height - depthDelta;
                    float shadowMul = 0;
                    float stepIndex = 1;
                    int shadowNum = 0;
                    float curMapHeight = tex2D(_HeightMap, curUV).r;
                    // tex2D确定lod层需要遍历，增加迭代次数从而导致roll次数过多报错，可使用tex2Dlod禁止迭代
                    while (curHeight > 0)
                    {
                        if (curMapHeight < curHeight)
                        {
                            shadowNum += 1;
                            float curShadowMul = (curHeight - curMapHeight) * (1.0 - stepIndex / layers);
                            shadowMul = max(curShadowMul, shadowMul);
                        }
                        stepIndex += 1;
                        curHeight -= 1;
                        curUV += uvDelta;
                        curMapHeight = tex2Dlod(_HeightMap, float4(curUV, 0, 0)).r;
                    }
                    if (shadowNum > 0)
                    {
                        return 1.0 - shadowMul;
                    }
                    return 1;
                }
                return 1;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // float2 uv = normalParallexMapping(i.uv, i.vDirTS);
                // float2 uv = steepParallexMapping(i.uv, i.vDirTS);
                // float2 uv = reliefParallexMapping(i.uv, i.vDirTS);
                float2 uv = parallexOcculusionMapping(i.uv, i.vDirTS);
                float3 normal = UnpackNormal(tex2D(_NormalMap, uv));
                float shadowMul = parallexSoftShadowMultiplier(i.lDirTS, uv, tex2D(_HeightMap, uv).r);

                fixed3 col = tex2D(_MainTex, uv).rgb;
                float3 diffuse = dot(normal, i.lDirTS) * 0.5 + 0.5;
                float3 rDirTS = reflect(-i.lDirTS, normal);
                float3 specular = max(0, pow(dot(rDirTS, i.vDirTS), _SpecPow));
                float3 finalCol = (diffuse  + 0.1)* col * shadowMul;
            
                return float4(finalCol, 1);
            }
            ENDCG
        }
    }
}

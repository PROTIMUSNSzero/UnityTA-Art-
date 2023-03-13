Shader "Unlit/DOF2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    
    CGINCLUDE
    #include "UnityCG.cginc"

    struct appdata
    {
        float4 vertex : POSITION;
        float2 uv : TEXCOORD0;
    };

    struct v2f
    {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };

    static const int SampleCount = 16;
    static const float2 Kernel[SampleCount] = 
    {
        float2(0, 0),
        float2(0.54545456, 0),
        float2(0.16855472, 0.5187581),
        float2(-0.44128203, 0.3206101),
        float2(-0.44128197, -0.3206102),
        float2(0.1685548, -0.5187581),
        float2(1, 0),
        float2(0.809017, 0.58778524),
        float2(0.30901697, 0.95105654),
        float2(-0.30901703, 0.9510565),
        float2(-0.80901706, 0.5877852),
        float2(-1, 0),
        float2(-0.80901694, -0.58778536),
        float2(-0.30901664, -0.9510566),
        float2(0.30901712, -0.9510565),
        float2(0.80901694, -0.5877853),
    };

    sampler2D _MainTex;
    float4 _MainTex_ST;
    float4 _MainTex_TexelSize;
    sampler2D _CameraDepthTexture;
    sampler2D _CoCTex;
    float _FocusDistance;
    float _FocusRange;
    float _BokehRadius;
    sampler2D _DOFTex;

    v2f vert (appdata v)
    {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        return o;
    }

    ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100     
        // Circle of Confusion Pass
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragCoC

            half fragCoC (v2f i) : SV_Target
            {
                fixed depthCol = tex2D(_CameraDepthTexture, i.uv).r;
                float depth = LinearEyeDepth(depthCol);
                float col = clamp((depth - _FocusDistance) / _FocusRange, -1, 1) * _BokehRadius;
                return col;
            }
            
            ENDCG
        }
        // CoC filter，将coc图降至半分辨率（graphics.blit平均化相邻像素以实现分辨率减半，不适用于深度图）
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragCoCFilter

            fixed4 fragCoCFilter (v2f i) : SV_TARGET
            {
                float2 uv = i.uv;
                // 下采样coc，高斯模糊
                float4 offset = _MainTex_TexelSize.xyxy * float2(0.5, -0.5).xxyy;
                float3 col0 = tex2D(_MainTex, uv + offset.xy).rgb;
                float3 col1 = tex2D(_MainTex, uv + offset.xw).rgb;
                float3 col2 = tex2D(_MainTex, uv + offset.zy).rgb;
                float3 col3 = tex2D(_MainTex, uv + offset.zw).rgb;
                float coc0 = tex2D(_CoCTex, uv + offset.xy).r;
                float coc1 = tex2D(_CoCTex, uv + offset.xw).r;
                float coc2 = tex2D(_CoCTex, uv + offset.zy).r;
                float coc3 = tex2D(_CoCTex, uv + offset.zw).r;
                float cocMin = min(min(min(coc0, coc1), coc2), coc3);
                float cocMax = max(max(max(coc0, coc1), coc2), coc3);
                // 取coc绝对值最大的点
                float coc = cocMax >= -cocMin ? cocMax : cocMin;
                return float4(tex2D(_MainTex, uv).rgb, coc);
            }
            ENDCG
        }
        // bokeh blur
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragBokeh

            half weigh(half coc, half radius)
            {
                return saturate((coc - radius + 2) / 2.0);
            }

            fixed4 fragBokeh (v2f i) : SV_TARGET
            {
                float4 bgColor = 0, fgColor = 0;
                float2 uv = i.uv;
                float2 delta;
                half bgWeight = 0, fgWeight = 0;
                float coc = tex2D(_MainTex, i.uv).a;
                for (int i = 0; i < SampleCount; i++)
                {
                    delta = Kernel[i] * _BokehRadius;
                    float radius = length(delta);
                    delta *= _MainTex_TexelSize.xy;
                    float4 s = tex2D(_MainTex, uv + delta);
                    // max()只取背景不取前景，避免背景采样时采到前景
                    // min()减少前景采到背景的情况
                    half curWeight = weigh(max(0, min(coc, s.a)), radius);
                    bgColor += s * curWeight;
                    bgWeight += curWeight;
                    // 前景权重
                    curWeight = weigh(-s.a, radius);
                    fgColor += s * curWeight;
                    fgWeight += curWeight;
                }
                bgColor *= 1.0 / (bgWeight + (bgWeight == 0));
                fgColor *= 1.0 / (fgWeight + (fgWeight == 0));
                float bgfg = min(1.0, fgWeight * 3.14159265359 / SampleCount);  
                float3 color = lerp(bgColor, fgColor, bgfg).rgb;
                return float4(color, bgfg);
            }
            ENDCG
        }
        // post filter
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragFilter

            fixed4 fragFilter (v2f i) : SV_TARGET
            {
                float2 uv = i.uv;
                // 高斯模糊，将离散的散景效果连接起来，3x3区域粗略采样，中心点采样4次，上下左右点共采样8次（每个点2次），角落点共采样4次（每个点1次）
                float4 offset = _MainTex_TexelSize.xyxy * float2(0.5, -0.5).xxyy;
                float4 col = tex2D(_MainTex, uv + offset.xy)
                    + tex2D(_MainTex, uv + offset.xw)
                    + tex2D(_MainTex, uv + offset.zy)
                    + tex2D(_MainTex, uv + offset.zw);
                col *= 0.25;
                return col;
            }
            ENDCG
        }
        // blend
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragBlend

            fixed4 fragBlend(v2f i) : SV_TARGET
            {
                float4 src = tex2D(_MainTex, i.uv);
                float4 dof = tex2D(_DOFTex, i.uv);
                float coc = tex2D(_CoCTex, i.uv).r;
                // 先用coc插值取背景
                float smooth = smoothstep(0.1, 1, abs(coc));
                // 再用dof.a插值取前景
                // C0=a+(b-a)x, C1=C0+(b-C0)y, C1=a+(b-a)(x+y-xy)
                float4 col = lerp(src, dof, smooth + dof.a - smooth * dof.a);
                return col; 
            }
            ENDCG
        }
    }
    
}

Shader "Unlit/Flame"
{
    Properties
    {
        _MaskTex ("R:外焰 G:内焰 B:扰动遮罩 A:透贴", 2D) = "blue" {}
        _NoiseTex ("R:噪声1 G:噪声2", 2D) = "gray" {}
        _NoiseParams1 ("噪声1 大小，流速，强度", Vector) = (1, 0.2, 0.2, 1)
        _NoiseParams2 ("噪声2 大小，流速，强度", Vector) = (1, 0.2, 0.2, 1)
        [HDR] _OuterCol ("外焰颜色", Color) = (1, 0, 0, 1)
        [HDR] _InnerCol ("内焰颜色", Color) = (1, 0, 1, 1)
    }
    SubShader
    {
        Tags 
        { 
            "Queue" = "Transparent"
            "RenderType"="Transparent"
            "ForceNoShadowCasting" = "True"
            "IgnoreProjector" = "True" 
        }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MaskTex;
            float4 _MaskTex_ST;
            sampler2D _NoiseTex;
            float3 _NoiseParams1;
            float3 _NoiseParams2;
            float4 _OuterCol;
            float4 _InnerCol;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv0 = TRANSFORM_TEX(v.uv, _MaskTex);
                // u、v同倍率缩放
                o.uv1 = v.uv * _NoiseParams1.x;
                o.uv1.y -= frac(_Time.x * _NoiseParams1.y);
                o.uv2 = v.uv * _NoiseParams2.x;
                o.uv2.y -= frac(_Time.x * _NoiseParams2.y);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 扰动遮罩 （火焰底部不做扰动）
                float opacity = tex2D(_MaskTex, i.uv0).b;
                // 采样2张noise并叠加，增加随机性
                half noise1 = tex2D(_NoiseTex, i.uv1).r;
                half noise2 = tex2D(_NoiseTex, i.uv2).g;
                half noise = noise1 * _NoiseParams1.z + noise2 * _NoiseParams2.z;
                // 只在y方向扰动
                float2 warpUV = i.uv0 + half2(0, -noise) * opacity;
                fixed3 col = tex2D(_MaskTex, warpUV);
                float3 flameCol = col.r * _OuterCol.rgb + col.g * _InnerCol.rgb;
                return float4(flameCol, col.r + col.g);
            }
            ENDCG
        }
    }
}

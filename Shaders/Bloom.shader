Shader "Unlit/Bloom"
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

    struct v2fBlur
    {
        float4 vertex : POSITION;
        float2 uv: TEXCOORD0;
        float4 uv1: TEXCOORD1;
        float4 uv2: TEXCOORD2;
    };

    struct v2f
    {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };

    sampler2D _MainTex;
    float4 _MainTex_ST;
    float4 _MainTex_TexelSize;
    float _BlurSize;
    float _LuminanceThreshold;
    sampler2D _BlurTex;

    v2f vert (appdata v)
    {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        return o;
    }

    v2fBlur vertBlurH (appdata v)
    {
        v2fBlur o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        float2 delta = _MainTex_TexelSize.xy;
        float2 offset0 = float2(1, 0);
        float2 offset1 = float2(2, 0);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        float2 uv = o.uv;
        o.uv1.xy = uv + delta * offset0 * _BlurSize;
        o.uv2.xy = uv + delta * offset1 * _BlurSize;
        o.uv1.zw = uv - delta * offset0 * _BlurSize;
        o.uv2.zw = uv - delta * offset1 * _BlurSize;
        return o; 
    }

    v2fBlur vertBlurV (appdata v)
    {
        v2fBlur o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        float2 delta = _MainTex_TexelSize.xy;
        float2 offset0 = float2(0, 1);
        float2 offset1 = float2(0, 2);
        o.uv = TRANSFORM_TEX(v.uv, _MainTex);
        float2 uv = o.uv;
        o.uv1.xy = uv + delta * offset0;
        o.uv2.xy = uv + delta * offset1;
        o.uv1.zw = uv - delta * offset0;
        o.uv2.zw = uv - delta * offset1;
        return o; 
    }

    fixed4 fragBlur (v2fBlur i) : SV_TARGET
    {
        float4 blurCol = tex2D(_MainTex, i.uv) * 0.4026 
            + tex2D(_MainTex, i.uv1.xy) * 0.2442
            + tex2D(_MainTex, i.uv1.zw) * 0.2442
            + tex2D(_MainTex, i.uv2.xy) * 0.0545
            + tex2D(_MainTex, i.uv2.zw) * 0.0545;
        return blurCol;
    }

    ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragFilter

            // 灰度
            float Luminance(float4 color)
            {
                return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
            }

            fixed4 fragFilter (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                float val = clamp(Luminance(col) - _LuminanceThreshold, 0, 1);
                return val * col;
            }
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vertBlurH
            #pragma fragment fragBlur
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vertBlurV
            #pragma fragment fragBlur
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragBlend

            fixed4 fragBlend (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                float4 blurCol = tex2D(_BlurTex, i.uv);
                return blurCol + col;
            }
            ENDCG
        }
    }
}
        
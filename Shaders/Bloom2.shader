Shader "Unlit/Bloom2"
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
    sampler2D _BlurTex;
    float4 _Filter;

    // contrib1 = (bright - threshold) / bright, contrib > 0 when bright > threshold
    fixed3 preFilter (fixed3 c)
    {
        fixed brightness = max(c.r, max(c.g, c.b));
        fixed contrib1 = max(0, brightness - _Filter.x);
        half soft = brightness - _Filter.y;
        soft = clamp(soft, 0, _Filter.z);
        soft = soft * soft * _Filter.w;
        half contrib = max(soft, contrib1);
        contrib /= max(brightness, 0.00001);
        return c * contrib;
    }

    half3 Sample (float2 uv) 
    {
        return tex2D(_MainTex, uv).rgb;
    }

    half3 SampleBox (float2 uv, float delta) 
    {
        float4 o = _MainTex_TexelSize.xyxy * float2(-delta, delta).xxyy;
        half3 s =
            Sample(uv + o.xy) + Sample(uv + o.zy) +
            Sample(uv + o.xw) + Sample(uv + o.zw);
        return s * 0.25f;
    }

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
        Pass  //0
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 frag (v2f i) : SV_Target
            {
                return float4(preFilter(SampleBox(i.uv, 1)), 1);
            }
            ENDCG
        }

        Pass //1
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 frag (v2f i) : SV_TARGET
            {
                return float4(SampleBox(i.uv, 1), 1);
            }
            ENDCG
        }

        Pass //2
        {
            Blend One One
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 frag (v2f i) : SV_TARGET
            {
                return float4(SampleBox(i.uv, 0.5), 1);
            }
            ENDCG
        }

        Pass //3
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_BlurTex, i.uv);
                col.rgb += SampleBox(i.uv, 0.5).rgb;
                return col;
            }
            ENDCG
        }
    }
}
        
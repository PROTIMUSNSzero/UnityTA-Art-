Shader "Unlit/Warp"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WarpTex ("WarpTex", 2D) = "gray" {}
        _WarpStrength ("WarpStrength", Range(0, 1)) = 0.1
        _FlowStrength ("FlowStrength", Range(0, 5)) = 1
        _FlowSpeed ("FlowSpeed", Range(0, 10)) = 1
        _Opacity ("Opacity", Range(0, 1)) = 1
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
                float2 uv : TEXCOORD0;
                float2 uv1: TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _WarpTex;
            float4 _WarpTex_ST;
            float _Opacity;
            float _WarpStrength;
            float _FlowStrength;
            float _FlowSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv1 = TRANSFORM_TEX(v.uv, _WarpTex);
                o.uv1.y -= frac(_Time.x * _FlowSpeed);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 warp = tex2D(_WarpTex, i.uv1).rgb;
                float2 uvBias = (warp.xy - 0.5) * _WarpStrength;
                float2 mainUV = i.uv + uvBias;
                fixed4 col = tex2D(_MainTex, mainUV);
                float flowStrength = max(0, lerp(1, warp.b * 2, _FlowStrength));
                float opacity = col.a * flowStrength * _Opacity; 
                return float4(col.rgb, opacity);
            }
            ENDCG
        }
    }
}

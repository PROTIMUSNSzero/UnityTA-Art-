Shader "Unlit/Flow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Opacity ("Opacity（不透明度）", Range(0, 1)) = 1
        _FlowTex ("FlowTex", 2D) = "gray" {}
        _FlowSpeed ("FlowSpeed", Range(0, 10)) = 1
        _FlowStrength ("FlowStrength", Range(0, 1)) = 1
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
            // 贴图未预乘
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
            sampler2D _FlowTex;
            float4 _FlowTex_ST;
            float _Opacity;
            float _FlowSpeed;
            float _FlowStrength;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv1 = TRANSFORM_TEX(v.uv, _FlowTex);
                // frac取余数，只保留小数部分
                o.uv1.y += frac(-_Time.y * _FlowSpeed);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                // 噪声图只取单通道
                float noise = tex2D(_FlowTex, i.uv1).r;
                // 强度值为0时，无噪声图叠加效果，强度值为1时，噪声图效果提亮1倍
                // 若强度超过1，颜色会出现负值；默认灰度图lerp后为无叠加效果（0.5 * 2）
                noise = max(0, lerp(1, noise * 2, _FlowStrength));
                float opacity = col.a * _Opacity * noise;
                return float4(col.rgb, opacity);
            }
            ENDCG
        }
    }
}

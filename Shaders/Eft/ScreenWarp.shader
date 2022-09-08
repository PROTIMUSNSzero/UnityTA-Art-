Shader "Unlit/ScreenWarp"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WarpScale ("WarpScale", Range(0, 10)) = 1
        _WarpMid ("扭曲中间值", Range(0, 1)) = 0.5
        _Opacity ("Opacity", Range(0, 10)) = 1
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

        GrabPass
        {
            // 在渲染之前，将背景渲染成一张图
            "_BGTex"
        }
        LOD 100

        Pass
        {
            Blend One OneMinusSrcAlpha

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
                float4 vertex : SV_POSITION;
                float4 grabPos: TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _WarpScale;
            float _WarpMid;
            float _Opacity;
            // 获取背景纹理
            sampler2D _BGTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // 获取背景纹理的采样坐标
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                // 用b通道作为扰动源
                i.grabPos.xy += (col.b - _WarpMid) * _WarpScale;
                half3 bgCol = tex2Dproj(_BGTex, i.grabPos).rgb;
                // col * bgCol 叠底效果，类似透明玻璃
                half3 color = lerp(1, col.rgb, _Opacity) * bgCol;
                half opacity = col.a;
                return float4(color * opacity, opacity);
            }
            ENDCG
        }
    }
}

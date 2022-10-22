Shader "Unlit/ScreenUV"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ScreenTex ("ScreenTex", 2D) = "white" {}
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
                float2 screenUV: TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _ScreenTex;
            float4 _ScreenTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                float3 posVS = UnityObjectToViewPos(v.vertex).xyz;
                // 模型原点（中心）距离
                float originDist = UnityObjectToViewPos(float3(0, 0, 0)).z;
                // 消除畸变（距离不同的顶点，映射贴图大小也不同）
                o.screenUV = posVS.xy / posVS.z;
                // 根据距离调整总体大小（靠近放大，远离缩小）
                o.screenUV *= originDist;
                // zw分量控制流速
                o.screenUV = o.screenUV * _ScreenTex_ST.xy - frac(_Time.x * _ScreenTex_ST.zw);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                half screenCol = tex2D(_ScreenTex, i.screenUV).r;
                half opacity = col.a * screenCol;
                return float4(col.rgb * opacity, opacity);
            }
            ENDCG
        }
    }
}

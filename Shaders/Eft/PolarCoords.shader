Shader "Unlit/PolarCoords"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Speed ("Speed", Int) = 1
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="TransparentCutout" 
            "ForceNoShadowCasting" = "True"  
            "IgnoreProjector" = "True"  
        }
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Speed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.uv -= 0.5;
                float theta = atan2(i.uv.y, i.uv.x);
                // 极坐标角度（0 - PI）
                theta = theta / 3.1415 * 0.5 + 0.5;
                // 极坐标半径
                float r = length(i.uv) + frac(_Time * _Speed);
                i.uv = float2(theta, r);
                fixed4 col = tex2D(_MainTex, i.uv);
                clip(1 - col.r - 0.1);
                return col;
            }
            ENDCG
        }
    }
}

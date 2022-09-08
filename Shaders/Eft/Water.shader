Shader "Unlit/Water"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _WarpTex ("WarpTex", 2D) = "gray" {}
        _FlowSpeed ("FlowSpeed", Vector) = (1, 1, 1, 1)
        _FlowPar1 ("大小、流速X、流速Y、强度", Vector) = (1, 1, 1, 1)
        _FlowPar2 ("大小、流速X、流速Y、强度", Vector) = (1, 1, 1, 1)
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 uv1: TEXCOORD1;
                float2 uv2: TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _WarpTex;
            float4 _WarpTex_ST;
            float2 _FlowSpeed;
            float4 _FlowPar1;
            float4 _FlowPar2;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv -= frac(_Time.x * _FlowSpeed);
                o.uv1 = v.uv * _FlowPar1.x - frac(_Time.x * _FlowPar1.yz);
                o.uv2 = v.uv * _FlowPar2.x - frac(_Time.x * _FlowPar2.yz);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 noise1 = tex2D(_WarpTex, i.uv1).rg;
                float2 noise2 = tex2D(_WarpTex, i.uv2).rg;
                float2 warpBias1 = (noise1 - 0.5) * _FlowPar1.w;
                float2 warpBias2 = (noise2 - 0.5) * _FlowPar2.w;
                float2 waterUV = i.uv + warpBias1 + warpBias2;
                fixed4 col = tex2D(_MainTex, waterUV);
                return col;
            }
            ENDCG
        }
    }
}

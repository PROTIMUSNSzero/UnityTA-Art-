Shader "Unlit/FlowMap"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FlowTex ("FlowTex", 2D) = "gray" {}
        _FlowSpeed ("FlowSpeed", Range(0, 10)) = 1
        _TimeSpeed ("TimeSpeed", Range(0, 10)) = 1
        [Toggle] _FlipY ("Flip Y", int) = 0
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
                float2 flowUV: TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _FlowTex;
            float4 _FlowTex_ST;
            float _FlowScale;
            float _FlowSpeed;
            float _TimeSpeed;
            int _FlipY;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.flowUV = TRANSFORM_TEX(v.uv, _FlowTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 flowUV = i.flowUV;
                if (_FlipY)
                {
                    flowUV.y = 1 - flowUV.y;
                }
                float2 flowDir = (tex2D(_FlowTex, flowUV).rg * 2 - 1) * _FlowSpeed;
                float2 phase0 = frac(_Time.x * _TimeSpeed);
                float2 phase1 = frac(_Time.x * _TimeSpeed + 0.5);
                float lerpVal = abs(0.5 - phase0) / 0.5;
                float4 tex0 = tex2D(_MainTex, i.uv + flowDir * phase0);
                float4 tex1 = tex2D(_MainTex, i.uv + flowDir * phase1);
                float4 col = lerp(tex0, tex1, lerpVal);
                return col;
            }
            ENDCG
        }
    }
}
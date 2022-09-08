Shader "Unlit/Sequence"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Sequence ("Sequence", 2D) = "black" {}
        _Row ("序列帧行数", Int) = 1
        _Col ("序列帧列数", Int) = 1
        _Speed ("播放速度", Int) = 1
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
            Name "Forward_AB"
            Tags
            {
                "LightMode" = "ForwardBase"
            }
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
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                return fixed4(col.rgb * col.a, col.a);
            }
            ENDCG
        }

        pass
        {
            Name "Forward_AD"
            Tags
            {
                "LightMode" = "ForwardBase"
            }
            Blend SrcAlpha One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal: TEXCOORD1;
            };

            sampler2D _Sequence;
            float4 _Sequence_ST;
            half _Row;
            half _Col;
            half _Speed;

            v2f vert (appdata v)
            {
                v2f o;
                v.vertex.xyz += v.normal * 0.00005;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _Sequence) * float2(v.uv.x / _Col, v.uv.y / _Row);
                half index = floor(_Time.y * _Speed);
                half stepU = 1.0 / _Col;
                half stepV = 1.0 / _Row;
                o.uv += float2(stepU * floor(index % _Col), 1 - stepV * floor(index / _Col));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_Sequence, i.uv);
                return float4(col.xyz * col.a, col.a);
            }
            ENDCG
        }
    }
}

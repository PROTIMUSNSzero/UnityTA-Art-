Shader "Unlit/VertexAnim"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Scale ("缩放 强度、速度、校正", Vector) = (1, 1, 1, 0)
        _SwingX ("扭动 强度、速度、波长", Vector) = (1, 3, 1, 0)
        _SwingZ ("扭动 强度、速度、波长", Vector) = (1, 3, 1, 0)
        _SwingY ("起伏 强度、速度、滞后", Vector) = (1, 3, 1, 0)
        _Shake ("摇头 强度、速度、滞后", Vector) = (20, 2, 1, 0)
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
                // 模型顶点色
                float4 color: COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color: COLOR;
            };

            #define TWO_PI 6.283185

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Scale;
            float4 _SwingX;
            float4 _SwingY;
            float4 _SwingZ;
            float4 _Shake;

            void Anim(inout float4 vertex, inout float4 color)
            {
                float scale = _Scale.x * color.g * sin(frac(_Time.y * _Scale.y) * TWO_PI);
                vertex.xyz *= 1 + scale;
                // 缩放时将y高度拉回
                vertex.y -= _Scale.z * scale;  

                // 利用y值实现s型摆动，即不同高度的顶点摆动幅度不同
                float swingX = _SwingX.x * sin(frac(_Time.y * _SwingX.y + vertex.y * _SwingX.z) * TWO_PI);
                float swingZ = _SwingZ.x * sin(frac(_Time.y * _SwingZ.y + vertex.y * _SwingZ.z) * TWO_PI);
                vertex.xz += float2(swingX,swingZ) * color.r;

                // shake.z提供天使圈旋转的惯性滞后感
                float radY = radians(_Shake.x) * sin(frac(_Time.y * _Shake.y - color.g * _Shake.z) * TWO_PI) * (1 - color.r);
                float sinY, cosY = 0;
                sincos(radY, sinY, cosY);
                vertex.xz = float2(vertex.x * cosY - vertex.z * sinY, vertex.x * sinY + vertex.z * cosY);

                 float swingY = _SwingY.x * sin(frac(_Time.y * _SwingY.y - color.g * _SwingY.z) * TWO_PI);
                 vertex.y += swingY;

                // 天使环提亮
                 float lightness = 1 + color.g * (1 + scale * 2);
                 color = float4(lightness, lightness, lightness, 1);
            }

            v2f vert (appdata v)
            {
                v2f o;
                Anim(v.vertex, v.color); 
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.color = v.color;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                // 顶点色
                return float4(col.xyz * i.color.xyz * col.a, col.a);
            }
            ENDCG
        }
    }
}

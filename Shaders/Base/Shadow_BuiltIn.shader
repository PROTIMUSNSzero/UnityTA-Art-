Shader "Unlit/Shadow_BuiltIn"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags {
                "LightMode"="ForwardBase"
            }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            // 内置投影必须包含的库文件
            #include "AutoLight.cginc" 
            #include "Lighting.cginc"
            
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                LIGHTING_COORDS(0, 1) // 封装的坐标信息，保证作为参数的2个TEXCOORDS未被使用
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float shadow = LIGHT_ATTENUATION(i); // 获取投影信息
                return float4(shadow, shadow, shadow, 1);
            }
            ENDCG
        }
    }
}

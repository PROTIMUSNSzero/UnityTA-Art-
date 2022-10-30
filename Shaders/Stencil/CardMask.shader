Shader "Unlit/CardMask"
{
    Properties
    {
        _Mask ("StencilMask", int) = 1
    }
    SubShader
    {
        Tags 
        {
             "RenderType"="Opaque"
            "Queue"="Geometry+1" 
        }
        LOD 100

        Pass
        {
            // 若不关闭深度写入，后面的物体无法通过深度测试，仍然不会渲染
            ZWrite off
            Stencil 
            {
                Ref [_Mask]
                Comp always
                Pass replace
            }
            ColorMask 0

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return half4(1, 1, 1, 1);
            }
            ENDCG
        }
    }
}

Shader "Unlit/CardObj"
{
    Properties
    {
        _Color ("Color", color) = (0, 0, 1)
        _Mask ("StencilMask", int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("StencilCompareFunc", float) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilOp ("StencilOp", float) = 2
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
            "Queue"="Geometry+2"
        }
        LOD 100

        Pass
        {
            Stencil
            {
                Ref [_Mask]
                Comp [_StencilComp]
            }
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

            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _Color;
            }
            ENDCG
        }
    }
}

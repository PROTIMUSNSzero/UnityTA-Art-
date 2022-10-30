Shader "Unlit/ZTest1"
{
    Properties
    {
        [Enum(Off,0, On,1)] _ZTest ("ZTest", int) = 1
        [Enum(UnityEngine.Rendering.CompareFunction)] _ZTestComp ("ZTestComp", int) = 4
        _Color ("Color", color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque"
            // 渲染顺序，先按照渲染队列排序，同一队列的，不透明物体从前往后依次渲染，半透明物体从后往前依次渲染
            "Queue"="Geometry+1"    
        }
        LOD 100

        Pass
        {
            ZTest [_ZTestComp]
            ZWrite [_ZTest]
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

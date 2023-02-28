Shader "Unlit/DOF"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    CGINCLUDE
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
        float4 uv1: TEXCOORD1;
        float4 uv2: TEXCOORD2;
    };

    sampler2D _MainTex;
    sampler2D _CameraDepthTexture;
    float4 _MainTex_TexelSize; // (1.0 / scrW, 1.0 / scrH, scrW, scrH)
    float _dofNear;
    float _dofFar;

    v2f vert (appdata v)
    {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = v.uv;
        // #if UNITY_UV_STARTS_AT_TOP //处于DX
        // 	if(_MainTex_TexelSize.y < 0)
        // 		o.uv = float2(v.uv.x, 1-v.uv.y);
        // #else
        // 	o.uv = v.uv;
        // #endif
        return o;
    }

    fixed4 frag (v2f i) : SV_Target
    {
        float depth = tex2D(_CameraDepthTexture, i.uv).r;
        depth = Linear01Depth(depth);
        float focus = 1;
        if (depth > _dofFar || depth < _dofNear)
        {
            focus = 0;
        }
        return fixed4(depth, focus, focus, 1);
    }

    v2f vertH (appdata v)
    {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = v.uv;
        float texDeltaV = _MainTex_TexelSize.x;
        fixed2 v1 = (1, 0);
        fixed2 v2 = (2, 0);
        o.uv1.xy = o.uv + _MainTex_TexelSize.x * v1;
        o.uv2.xy = o.uv + _MainTex_TexelSize.x * v2;
        o.uv1.zw = o.uv - _MainTex_TexelSize.x * v1;
        o.uv2.zw = o.uv - _MainTex_TexelSize.x * v2;
        return o;
    }

    v2f vertV (appdata v)
    {
        v2f o;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.uv = v.uv;
        float texDeltaH = _MainTex_TexelSize.y;
        fixed2 v1 = (0, 1);
        fixed2 v2 = (0, 2);
        o.uv1.xy = o.uv + texDeltaH * v1;
        o.uv2.xy = o.uv + texDeltaH * v2;
        o.uv1.zw = o.uv - texDeltaH * v1;
        o.uv2.zw = o.uv - texDeltaH * v2;
        return o;
    }

    fixed4 fragBlur (v2f i) : SV_Target
    {
        float depth = tex2D(_CameraDepthTexture, i.uv).r;
        depth = Linear01Depth(depth);
        float4 col = tex2D(_MainTex, i.uv);
        if (depth > _dofFar || depth < _dofNear)
        {
            float4 col = col * 0.4026 
                + tex2D(_MainTex, i.uv1.xy) * 0.2442
                + tex2D(_MainTex, i.uv1.zw) * 0.2442
                + tex2D(_MainTex, i.uv2.xy) * 0.0545
                + tex2D(_MainTex, i.uv2.zw) * 0.0545;
        }
        return col;
    }
    ENDCG 
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Pass
        {
            CGPROGRAM
            #pragma vertex vertH
            #pragma fragment fragBlur
            ENDCG
        }
        Pass
        {
            CGPROGRAM
            #pragma vertex vertV
            #pragma fragment fragBlur
            ENDCG
        }
    }
}

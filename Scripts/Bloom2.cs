using System;
using System.Collections;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class Bloom2 : MonoBehaviour
{
    [Range(0f, 10f)]
    public float luminanceThreshold;
    [Range(0f, 1f)] 
    public float softThreshold;
    [Range(1, 10)] 
    public int downSampleIterations;
    [Range(0f, 1f)] 
    public float intensity;
    public Shader shader;

    private Material _mat;
    private int[] _shaderProps = new int[3];
    private RenderTexture[] _texs = new RenderTexture[16];
    
    void OnEnable()
    {
        _mat = new Material(shader);
        _shaderProps[0] = Shader.PropertyToID("_Filter");
        _shaderProps[1] = Shader.PropertyToID("_BlurTex");
        _shaderProps[2] = Shader.PropertyToID("_Intensity");
    }    

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        var scrW = src.width / 2;
        var scrH = src.height / 2;
        var format = src.format;
        var filterMode = FilterMode.Bilinear;
        Vector4 filter;
        float knee = luminanceThreshold * softThreshold;
        filter.x = luminanceThreshold;
        filter.y = luminanceThreshold - knee;
        filter.z = 2 * knee;
        filter.w = 0.25f / (knee + 0.00001f);
        _mat.SetVector(_shaderProps[0], filter);
        _mat.SetFloat(_shaderProps[2], intensity);
        RenderTexture destRT = _texs[0] = RenderTexture.GetTemporary(scrW, scrH, 0, format);
        RenderTexture curRT = src;
        Graphics.Blit(curRT, destRT, _mat, 0);
        for (var i = 1; i < downSampleIterations; i++)
        {
            scrW /= 2;
            scrH /= 2;
            if (scrH < 2 || scrW < 2)
            {
                break;
            }
            _texs[i] = destRT = RenderTexture.GetTemporary(scrW, scrH, 0, format);
            destRT.filterMode = filterMode;
            Graphics.Blit(curRT, destRT, _mat, 1);
            curRT = destRT;
        }

        for (int i = downSampleIterations - 2; i >= 0; i--)
        {
            var rt = _texs[i];
            _texs[i] = null;
            Graphics.Blit(curRT, rt, _mat, 2);
            RenderTexture.ReleaseTemporary(curRT);
            curRT = rt;
        }
        _mat.SetTexture(_shaderProps[1], src);
        Graphics.Blit(curRT, dest, _mat, 3);
        RenderTexture.ReleaseTemporary(curRT);
    }
}
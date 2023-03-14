using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class Bloom : MonoBehaviour
{
    [Range(1, 4)]
    public int downSamples = 1;
    [Range(0f, 5f)]
    public float luminanceThreshold;
    [Range(1, 10)] 
    public int blurIterations;
    [Range(1f, 10f)] 
    public float blurSize;
    public Shader shader;

    private Material _mat;
    private int[] _shaderProps = new int[3];
    
    void Start()
    {
        _mat = new Material(shader);
        _shaderProps[0] = Shader.PropertyToID("_BlurSize");
        _shaderProps[1] = Shader.PropertyToID("_BlurTex");
        _shaderProps[2] = Shader.PropertyToID("_LuminanceThreshold");
    }    

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        var scrW = Screen.width;
        var scrH = Screen.height;
        _mat.SetFloat(_shaderProps[0], blurSize);
        _mat.SetFloat(_shaderProps[2], luminanceThreshold);
        var rt0 = RenderTexture.GetTemporary(scrW, scrH);
        Graphics.Blit(src, rt0, _mat, 0);
        for (var i = 0; i < blurIterations; i++)
        {
            var rt1 = RenderTexture.GetTemporary(scrW / downSamples, scrH / downSamples);
            Graphics.Blit(rt0, rt1, _mat, 1);
            RenderTexture.ReleaseTemporary(rt0);
            rt0 = RenderTexture.GetTemporary(scrW / downSamples, scrH / downSamples);
            Graphics.Blit(rt1, rt0, _mat, 2);
            RenderTexture.ReleaseTemporary(rt1);
        }
        _mat.SetTexture(_shaderProps[1], rt0);
        Graphics.Blit(src, dest, _mat, 3);
        RenderTexture.ReleaseTemporary(rt0);
    }
}

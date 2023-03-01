using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Pixelation : MonoBehaviour
{
    public Shader pixelationShader;
    [Range(1, 100)] 
    public int pixelSize;

    private Material _mat;
    private int shaderProp;
    
    void Start()
    {
        if (!_mat)
        {
            _mat = new Material(pixelationShader);
        }

        shaderProp = Shader.PropertyToID("_PixelSize");
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        _mat.SetFloat(shaderProp, pixelSize);
        Graphics.Blit(src, dest, _mat);
    }
}

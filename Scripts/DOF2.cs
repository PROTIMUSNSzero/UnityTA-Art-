using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class DOF2 : MonoBehaviour
{
    [Range(0.1f, 100)] 
    public float FocusDistance;
    [Range(0.1f, 50)] 
    public float FocusRange;
    [Range(1, 8)] 
    public float BokehRadius;

    public Shader dofShader;

    private Material _mat;
    private int[] shaderProps = new int[5];

    void Start()
    {
        if (!_mat)
        {
            _mat = new Material(dofShader);
        }

        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
        shaderProps[0] = Shader.PropertyToID("_FocusDistance");    
        shaderProps[1] = Shader.PropertyToID("_FocusRange");
        shaderProps[2] = Shader.PropertyToID("_BokehRadius");
        shaderProps[3] = Shader.PropertyToID("_CoCTex");
        shaderProps[4] = Shader.PropertyToID("_DOFTex");
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        var width = Screen.width;
        var height = Screen.height;
        RenderTextureFormat format = src.format;
        
        _mat.SetFloat(shaderProps[0], FocusDistance);
        _mat.SetFloat(shaderProps[1], FocusRange);
        _mat.SetFloat(shaderProps[2], BokehRadius);
        var coc = RenderTexture.GetTemporary(width, height, 0, RenderTextureFormat.RHalf,
            RenderTextureReadWrite.Linear);
        // 半分辨率下实现模糊，coc半径、高斯偏移同样减半
        var dof0 = RenderTexture.GetTemporary(width / 2, height / 2, 0, format);
        var dof1 = RenderTexture.GetTemporary(width / 2, height / 2, 0, format);
        
        Graphics.Blit(src, coc, _mat, 0);
        _mat.SetTexture(shaderProps[3], coc);
        Graphics.Blit(src, dof0, _mat, 1);
        Graphics.Blit(dof0, dof1, _mat, 2);
        Graphics.Blit(dof1, dof0, _mat, 3);
        _mat.SetTexture(shaderProps[4], dof0);
        Graphics.Blit(src, dest, _mat, 4);
        
        RenderTexture.ReleaseTemporary(coc);
        RenderTexture.ReleaseTemporary(dof0);
        RenderTexture.ReleaseTemporary(dof1);

    }
}

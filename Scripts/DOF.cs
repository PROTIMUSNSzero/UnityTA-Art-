using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class DOF : MonoBehaviour
{
    public Shader dofShader;
    [Header("FOV")]
    [Range(0.01f, 100f)] 
    public float focusDistance = 10;
    [Range(0.1f, 50f)] 
    public float depthOfField = 10;
    [Range(0.1f, 50f)] 
    public float focusSphereSize;
    [Range(1, 20)]
    public int blurIteration = 2;
    [Range(0.2f, 3)]
    public float blurSpread = 1;
    [Range(0, 10)]
    public float blurSmoothRange;
    public bool showDepth = false;
    private Material _mat;
    
    private Camera _camera;
    private int[] _shaderProps = new int[4];


    private void Start()
    {
        if (!_camera)
        {
            _camera = GetComponent<Camera>();
        }
        _camera.depthTextureMode |= DepthTextureMode.Depth;
        if (!_mat)
        {
            _mat = new Material(dofShader);
        }
        _shaderProps[0] = Shader.PropertyToID("_DofNear");
        _shaderProps[1] = Shader.PropertyToID("_DofFar");
        _shaderProps[2] = Shader.PropertyToID("_BlurSize");
        _shaderProps[3] = Shader.PropertyToID("_SmoothRange");
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (!_mat)
        {
            Graphics.Blit(src, dest);
            return;
        }
        _mat = new Material(_mat.shader);
        var nearDist = _camera.nearClipPlane;
        var clipDist = _camera.farClipPlane - nearDist;
        _mat.SetFloat(_shaderProps[0], (focusDistance - depthOfField - nearDist) / clipDist);
        _mat.SetFloat(_shaderProps[1], (focusDistance + depthOfField - nearDist) / clipDist);
        
        if (showDepth)
        {
            Graphics.Blit(src, dest, _mat, 2);
            return;
        }
        
        //blur
        var scrW = Screen.width;
        var scrH = Screen.height;
        _mat.SetFloat(_shaderProps[3], blurSmoothRange);
        var rt0 = RenderTexture.GetTemporary(scrW, scrH);
        Graphics.Blit(src, rt0);
        for (int i = 0; i < blurIteration; i++)
        {
            _mat.SetFloat(_shaderProps[2], 1 + i * blurSpread);
            var rt1 = RenderTexture.GetTemporary(scrW, scrH);
            Graphics.Blit(rt0, rt1, _mat, 0);
            RenderTexture.ReleaseTemporary(rt0);
            rt0 = RenderTexture.GetTemporary(scrW, scrH);
            Graphics.Blit(rt1, rt0, _mat, 1);
            RenderTexture.ReleaseTemporary(rt1);
        }
        Graphics.Blit(rt0, dest);
        RenderTexture.ReleaseTemporary(rt0);
    }

    private void OnDrawGizmos()
    {
        if (!_camera)
        {
            _camera = GetComponent<Camera>();
        }
        Gizmos.color = Color.green;
        Matrix4x4 temp = Gizmos.matrix;
        Gizmos.matrix = Matrix4x4.TRS(transform.position, transform.rotation, transform.localScale);
        var n = focusDistance - depthOfField;
        var f = focusDistance + depthOfField;
        Gizmos.DrawFrustum(Vector3.zero, _camera.fieldOfView, f, n, _camera.aspect);
        Gizmos.matrix = temp;
        Gizmos.color = Color.red;
        Gizmos.DrawWireSphere(transform.position + transform.forward * focusDistance, focusSphereSize);
        Gizmos.color = Color.cyan;
        Gizmos.DrawLine(transform.position, transform.position + transform.forward * focusDistance);
    }
}

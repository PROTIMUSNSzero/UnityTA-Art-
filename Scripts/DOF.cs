using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class DOF : MonoBehaviour
{
    [Header("FOV")]
    [Range(0.01f, 100f)] 
    public float focusDistance = 10;
    [Range(0.1f, 50f)] 
    public float depthOfField = 10;
    [Range(0.1f, 50f)] 
    public float focusSphereSize;
    [Range(1, 10)] 
    public int downSample = 1;
    [Range(1, 4)]
    public int blurIteration = 2;

    public Material mat;
    
    private Camera _camera;
    private int[] _shaderProps = new int[2];


    private void Start()
    {
        if (!_camera)
        {
            _camera = GetComponent<Camera>();
        }
        _camera.depthTextureMode |= DepthTextureMode.Depth;
        if (mat)
        {
            _shaderProps[0] = Shader.PropertyToID("_dofNear");
            _shaderProps[1] = Shader.PropertyToID("_dofFar");
        }
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (!mat)
        {
            Graphics.Blit(src, dest);
            return;
        }
        
        var nearDist = _camera.nearClipPlane;
        var clipDist = _camera.farClipPlane - nearDist;
        mat.SetFloat(_shaderProps[0], (focusDistance - depthOfField - nearDist) / clipDist);
        mat.SetFloat(_shaderProps[1], (focusDistance + depthOfField - nearDist) / clipDist);

        var scrW = Screen.width;
        var scrH = Screen.height;
        var rt0 = RenderTexture.GetTemporary(scrW / downSample, scrH / downSample);
        Graphics.Blit(src, rt0);
        for (int i = 0; i < blurIteration; i++)
        {
            var rt1 = RenderTexture.GetTemporary(scrW / downSample, scrH / downSample);
            Graphics.Blit(rt0, rt1, mat, 0);
            RenderTexture.ReleaseTemporary(rt0);
            rt0 = RenderTexture.GetTemporary(scrW / downSample, scrH / downSample);
            Graphics.Blit(rt1, rt0, mat, 1);
            RenderTexture.ReleaseTemporary(rt1);
        }
        Graphics.Blit(rt0, dest);
        RenderTexture.ReleaseTemporary(rt0);
        
//        Graphics.Blit(src, dest, mat);
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

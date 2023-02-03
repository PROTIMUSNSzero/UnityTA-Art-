using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FOV : MonoBehaviour
{
    [Header("FOV")]
    [Range(0.01f, 100f)] 
    public float focusDistance = 10;
    [Range(0.1f, 50f)] 
    public float depthOfField = 10;
    [Range(0.1f, 50f)] 
    public float focusSphereSize;

    private Camera _camera;
    
    void Start()
    {
        
    }

    void Update()
    {
        
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

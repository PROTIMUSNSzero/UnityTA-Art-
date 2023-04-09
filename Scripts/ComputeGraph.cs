using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class ComputeGraph : MonoBehaviour
{
    public const int maxResolution = 1000;
    [Range(10, maxResolution)]
    public int resolution = 100;
    [Range(0.1f, 5f)] 
    public float transitionDuration = 1f;

    [SerializeField]
    public Mesh mesh;
    public Material mat;
    [SerializeField]
    public ComputeShader computeShader;

    private static readonly int
        positionsId = Shader.PropertyToID("_Positions"),
        resolutionid = Shader.PropertyToID("_Resolution"),
        stepId = Shader.PropertyToID("_Step"),
        timeId = Shader.PropertyToID("_Time"),
        transitionProgressId = Shader.PropertyToID("_TransitionProgress"),
        scaleId = Shader.PropertyToID("_Scale");
    
    private ComputeBuffer _positionBuffer;
    private float _dt;
    
    void OnEnable()
    {
        // 3个元素，每个元素32位（4字节）
        _positionBuffer = new ComputeBuffer(maxResolution * maxResolution, 3 * 4);
    }

    private void OnDisable()
    {
        _positionBuffer.Release();
        _positionBuffer = null;
    }

    void Update()
    {
        _dt += Time.deltaTime;
        
        UpdateOnGPU();
    }

    void UpdateOnGPU()
    {
        float step = 2f / resolution;
        computeShader.SetInt(resolutionid, resolution);
        computeShader.SetFloat(stepId, step);
        computeShader.SetFloat(timeId, _dt);
        computeShader.SetFloat(transitionProgressId, Mathf.SmoothStep(0f, 1f, _dt % transitionDuration));
        
        computeShader.SetBuffer(0, positionsId, _positionBuffer);

        int groupNum = Mathf.CeilToInt(resolution / 8f);
        // 调用compute shader中的计算函数并分配线程组（三维，共groupNum * groupNum * 1个线程组）
        computeShader.Dispatch(0, groupNum, groupNum, 1);
        
        mat.SetBuffer(positionsId, _positionBuffer);
        mat.SetFloat(stepId, step);
        mat.SetVector(scaleId, new Vector4(step, 1.0f / step));
        var bounds = new Bounds(Vector3.zero, Vector3.one * (2 + step));
        Graphics.DrawMeshInstancedProcedural(mesh, 0, mat, bounds, resolution * resolution);
    }
    
}

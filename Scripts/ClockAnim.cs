using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ClockAnim : MonoBehaviour
{
    public Material clockMat;

    private int hourPropId;
    private int minPropId;
    private int secPropId;

    private bool valid;
    
    void Start()
    {
        if (!clockMat)
        {
            return;
        }

        hourPropId = Shader.PropertyToID("_HourAngle");
        minPropId = Shader.PropertyToID("_MinAngle");
        secPropId = Shader.PropertyToID("_SecAngle");

        if (clockMat.HasProperty(hourPropId) && clockMat.HasProperty(minPropId) && clockMat.HasProperty(secPropId))
        {
            valid = true;
        }
    }

    void Update()
    {
        if (!valid)
        {
            return;
        }
    }
}

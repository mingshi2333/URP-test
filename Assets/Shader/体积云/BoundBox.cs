using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class BoundBox : MonoBehaviour
{
    public bool IsShowLine = true;
    public Color LineColor = Color.green;

    void OnDrawGizmos()
    {
        //绘画边框
        if (IsShowLine)
        {
            Gizmos.color = LineColor;
            Gizmos.DrawWireCube(transform.position, transform.localScale);
        }
    }


}
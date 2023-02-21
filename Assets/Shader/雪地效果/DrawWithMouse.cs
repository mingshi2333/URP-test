using System;
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class DrawWithMouse : MonoBehaviour
{
    public Camera _Camera;

    public Shader _drawshader;
    [Range(1,500)]
    public float _brushSize=1;
    [Range(0,1f)]
    public float _brushStrength = 1;
    private RenderTexture _splatmap;
    private Material _snowMaterial, _drawMaterial;
    private RaycastHit _hit;
    // Start is called before the first frame update
    void Start()
    {
        _drawMaterial = new Material(_drawshader);
        _drawMaterial.SetVector("_Color",Color.red);
        _snowMaterial = GetComponent<MeshRenderer>().material;
        _splatmap = new RenderTexture(1024, 1024, 0, RenderTextureFormat.ARGBFloat);
        _snowMaterial.SetTexture("_Splat",_splatmap);
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKey(KeyCode.Mouse0))
        {
            if (Physics.Raycast(_Camera.ScreenPointToRay(Input.mousePosition), out _hit))
            {
                _drawMaterial.SetVector("_Coordinate",new Vector4(_hit.textureCoord.x,_hit.textureCoord.y,0,0));
                _drawMaterial.SetFloat("_Size",_brushSize);
                _drawMaterial.SetFloat("_Strength",_brushStrength);
                RenderTexture temp = RenderTexture.GetTemporary(_splatmap.width,_splatmap.height,0,RenderTextureFormat.ARGBFloat);
                Graphics.Blit(_splatmap,temp);
                Graphics.Blit(temp,_splatmap,_drawMaterial,0);
                RenderTexture.ReleaseTemporary(temp);
            }
        }
        
    }

    private void OnGUI()
    {
        GUI.DrawTexture(new Rect(0,0,256,256),_splatmap,scaleMode:ScaleMode.ScaleToFit,false,1);
    }
}

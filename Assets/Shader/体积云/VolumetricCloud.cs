using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[System.Serializable]
[VolumeComponentMenuForRenderPipeline("Custom/VolumetricCloud", typeof(UniversalRenderPipeline))]
public class VolumetricCloud: VolumeComponent, IPostProcessComponent{

    [Tooltip("Base Color")]
    public ColorParameter baseColor = new ColorParameter(new Color(1, 1, 1, 1));
    [Tooltip("Density Noise")]
    public Texture3DParameter densityNoise = new Texture3DParameter(null);
    [Tooltip("Density Noise Scale")]
    public Vector3Parameter densityNoiseScale = new Vector3Parameter(Vector3.one);
    [Tooltip("Density Noise Offset")]
    public Vector3Parameter densityNoiseOffset = new Vector3Parameter(Vector3.zero);
    [Tooltip("Absorption")] public FloatParameter Absorption = new FloatParameter(1.0f);
    
    
    [Tooltip("Absorption")] public Vector3Parameter Min = new Vector3Parameter(new Vector3(-10,-10,-10));
    [Tooltip("Absorption")] public Vector3Parameter Max = new Vector3Parameter(new Vector3(10,10,10));
    
    
    

    public bool IsActive() => true;
    public bool IsTileCompatible() => false;
    public void load(Material material, ref RenderingData data){
        /* 将所有的参数载入目标材质 */

        material.SetColor("_BaseColor", baseColor.value);
        if(densityNoise != null){
            material.SetTexture("_DensityNoiseTex", densityNoise.value);
        }
        material.SetVector("_DensityNoiseScale", densityNoiseScale.value);
        material.SetVector("_DensityNoiseOffset", densityNoiseOffset.value);
        material.SetFloat("_Absorption", Absorption.value);
        material.SetVector("_BoundBoxMin",Min.value);
        material.SetVector("_BoundBoxMax",Max.value);
    }
}
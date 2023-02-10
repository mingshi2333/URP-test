using System.Collections.Concurrent;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

[System.Serializable]
[VolumeComponentMenuForRenderPipeline("Custom/VolumetricCloud", typeof(UniversalRenderPipeline))]
public class VolumetricCloud: VolumeComponent, IPostProcessComponent{
    
    
    [Tooltip("云的颜色")]
    public ColorParameter baseColor = new ColorParameter(new Color(1, 1, 1, 1));
    [Tooltip("3d纹理")]
    public Texture3DParameter densityNoise = new Texture3DParameter(null);
    [Tooltip("纹理缩放")]
    public Vector3Parameter densityNoiseScale = new Vector3Parameter(Vector3.one);
    [Tooltip("整体缩放")]
    public FloatParameter densityNoiseAllScale = new FloatParameter(1f);
    [Tooltip("纹理偏移")]
    public Vector3Parameter densityNoiseOffset = new Vector3Parameter(Vector3.zero);
    [Tooltip("Blue")]
    public Texture2DParameter blueNoise = new Texture2DParameter(null);
    [Tooltip("消光系数")] public FloatParameter Absorption = new FloatParameter(1.0f);
    [Tooltip("光的消光系数")] public FloatParameter LightAbsorption = new FloatParameter(1.0f);
    [Tooltip("包围盒最小值")] public Vector3Parameter Min = new Vector3Parameter(new Vector3(-10,-10,-10));
    [Tooltip("包围盒最大值")] public Vector3Parameter Max = new Vector3Parameter(new Vector3(10,10,10));
    
    [Tooltip("最大采样")]  public MinIntParameter RaymaychingCount = new MinIntParameter(1,1);




    public bool IsActive() => true;
    public bool IsTileCompatible() => false;
    public void load(Material material, ref RenderingData data){
        /* 将所有的参数载入目标材质 */

        material.SetColor("_BaseColor", baseColor.value);
        if(densityNoise != null){
            material.SetTexture("_DensityNoiseTex", densityNoise.value);
        }
        if(blueNoise != null){
            material.SetTexture("_Bluenoise", densityNoise.value);
        }
        material.SetInt("_MaxRaymarchingcount",RaymaychingCount.value);
        material.SetVector("_DensityNoiseScale", densityNoiseScale.value);
        material.SetVector("_DensityNoiseOffset", densityNoiseOffset.value);
        material.SetFloat("_Absorption", Absorption.value);
        material.SetFloat("_LightAbsorption", LightAbsorption.value);
        material.SetVector("_BoundBoxMin",Min.value);
        material.SetVector("_BoundBoxMax",Max.value);
        material.SetFloat("_DensityNoiseAllScale",densityNoiseAllScale.value);
    }
}
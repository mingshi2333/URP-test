Shader "RedSaw/VolumetricCloud"{
    
    Properties{
        // 着色器输入
        _MainTex("Main Texture", 2D) = "white"{}
        _BaseColor("Base Color", Color) = (1, 1, 1, 1)
    }
    SubShader{
        Tags{
            "RenderPipeline" = "UniversalRenderPipeline"
        }
        pass{

            Cull Off
            ZTest Always
            ZWrite Off
            
            HLSLPROGRAM

                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
                #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
                #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

            

                #pragma vertex Vertex
                #pragma fragment Pixel

                Texture2D _MainTex;
                SAMPLER(sampler_MainTex);

                Texture3D _DensityNoiseTex;
                SAMPLER(sampler_DensityNoiseTex);
                float3 _DensityNoiseScale;
                float3 _DensityNoiseOffset;
                float _Absorption;

                float3 _BoundBoxMin;
                float3 _BoundBoxMax;
            
                half4 _BaseColor;

                struct vertexInput{
                    float4 vertex: POSITION;
                    float2 uv: TEXCOORD0;
                };
                struct vertexOutput{
                    float4 pos: SV_POSITION;
                    float2 uv: TEXCOORD0;
                };

                vertexOutput Vertex(vertexInput v){

                    vertexOutput o;
                    o.pos = TransformObjectToHClip(v.vertex);
                    o.uv = v.uv;
                    return o;
                }
                float3 GetWorldPosition(float3 positionHCS){
                        /* get world space position from clip position */

                        float2 UV = positionHCS.xy / _ScaledScreenParams.xy;
                        #if UNITY_REVERSED_Z
                        real depth = SampleSceneDepth(UV);
                        #else
                        real depth = lerp(UNITY_NEAR_CLIP_VALUE, 1, SampleSceneDepth(UV));
                        #endif
                        return ComputeWorldSpacePosition(UV, depth, UNITY_MATRIX_I_VP);
                    
                }
                float2 rayBoxDst(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 rayDir){
                    /*  通过boundsMin和boundsMax锚定一个长方体包围盒
                        从rayOrigin朝rayDir发射一条射线，计算从rayOrigin到包围盒表面的距离，以及射线在包围盒内部的距离
                        关于更多该算法可以参考：https://jcgt.org/published/0007/03/04/ 
	                */

                    float3 t0 = (boundsMin - rayOrigin) / rayDir;
                    float3 t1 = (boundsMax - rayOrigin) / rayDir;
                    float3 tmin = min(t0, t1);
                    float3 tmax = max(t0, t1);

                    float dstA = max(max(tmin.x, tmin.y), tmin.z);
                    float dstB = min(tmax.x, min(tmax.y, tmax.z));

                    float dstToBox = max(0, dstA);
                    float dstInsideBox = max(0, dstB - dstToBox);
                    return float2(dstToBox, dstInsideBox);
                }
                float sampleDensity(float3 position){
                    /* sample density accordding to world position */
                    
                    float3 uvw = position * _DensityNoiseScale + _DensityNoiseOffset+float3(0,0,1)*_Time.x*0.2;
                    return SAMPLE_TEXTURE3D(_DensityNoiseTex,sampler_DensityNoiseTex ,uvw).r;
                }
            float lightMarching(float3 position, int stepCount){
                    /* sample density from given point to light 
                       within target step count */

                    // URP的主光源位置的定义名字换了一下
                    float3 dirToLight = _MainLightPosition.xyz;

                    /* 这里的给传入的方向反向了一下是因为，rayBoxDst的计算是要从
                       目标点到体积，而采样时，则是反过来，从position出发到主光源*/
                    float dstInsideBox = rayBoxDst(_BoundBoxMin, _BoundBoxMax, position, 1/dirToLight).y;

                    // 采样
                    float stepSize = dstInsideBox / stepCount;
                    float totalDensity = 0;
                    float3 stepVec = dirToLight * stepSize;
                    for(int i = 0; i < stepCount; i ++){
                        position += stepVec;
                        totalDensity += max(0, sampleDensity(position) * stepSize);
                    }
                    return totalDensity;
                }

            
                half4 Pixel(vertexOutput  IN): SV_TARGET{

                    half4 albedo = _MainTex.Sample(sampler_MainTex, IN.uv);

                    // 重建世界坐标
                    float3 worldPosition = GetWorldPosition(IN.pos);
                    float3 rayPosition = _WorldSpaceCameraPos.xyz;
                    float3 worldViewVector = worldPosition - rayPosition;
                    float3 rayDir = normalize(worldViewVector);

                    
                    float2 rayBoxInfo = rayBoxDst(_BoundBoxMin, _BoundBoxMax, rayPosition, rayDir);
                    float dstToBox = rayBoxInfo.x;
                    float dstInsideBox = rayBoxInfo.y;
                    float dstToOpaque = length(worldViewVector);
                    float dstLimit = min(dstToOpaque - dstToBox, dstInsideBox);
                    float lightIntensity = 0;

                    
                    int stepCount = 32;                                         // 采样的次数
                    float stepSize = dstInsideBox / stepCount;                  // 步进的长度
                    float3 stepVec = rayDir * stepSize;                         // 步进向量
                    float3 currentPoint = rayPosition + dstToBox * rayDir;      // 采样起点
                    float totalDensity = 0;
                    float dstTravelled = 0;
                    for(int i = 0; i < stepCount; i ++){
                        if(dstTravelled < dstLimit){
                            float Dx = sampleDensity(currentPoint) * stepSize;
                            totalDensity += Dx;
                            float lightPathDensity  = lightMarching(currentPoint, 8);
                            lightIntensity += exp(-(lightPathDensity + totalDensity * _Absorption)) * Dx;
                            currentPoint += stepVec;
                            dstTravelled += stepSize;
                            continue;
                        }
                        break;

                        
                    }
                    float3 cloudColor = _MainLightColor.xyz * lightIntensity * _BaseColor.xyz;
                    return half4(albedo * exp(-totalDensity * _Absorption) + cloudColor, 1);
                    
                    

                    

                    
                }
            ENDHLSL
        }
    }
}
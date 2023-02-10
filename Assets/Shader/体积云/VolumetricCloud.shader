Shader "RedSaw/VolumetricCloud"{
    
    Properties{
        // 着色器输入
        [HideInInspector]_MainTex("Main Texture", 2D) = "white"{}
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
            #include "Helper.hlsl"
            

            #pragma vertex Vertex
            #pragma fragment Pixel

            Texture2D _MainTex;
            SAMPLER(sampler_MainTex);



            
            Texture3D _DensityNoiseTex;
            SAMPLER(sampler_DensityNoiseTex);
            Texture2D _Bluenoise;
            SAMPLER(sampler_Bluenoise);
            float3 _DensityNoiseScale;
            float3 _DensityNoiseOffset;
            float _DensityNoiseAllScale;
            int _MaxRaymarchingcount;

            
            float _Absorption;
            float _LightAbsorption;

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
                float3 uvw = position * _DensityNoiseScale*_DensityNoiseAllScale + _DensityNoiseOffset;
                float blue = SAMPLE_TEXTURE2D(_Bluenoise,sampler_Bluenoise,uvw.xz);
                return SAMPLE_TEXTURE3D(_DensityNoiseTex,sampler_DensityNoiseTex ,uvw).r*blue;
            }
            float GetCurrentPositionLum(float3 currentPos)
            {
                float3 lightdir = normalize(_MainLightPosition);
                float dstInsideBox = rayBoxDst(_BoundBoxMin, _BoundBoxMax, currentPos, lightdir).y;
                //float dstInsideBox = RayCloudLayerDst(float3(0,0,0),6371,1500,4500,currentPos,lightdir);
                float marchLength = 0;
                float totalDensity = 0;
                float marchNumber = 20;

                float l = dstInsideBox/marchNumber;//临时长度
                for(int march =0;march<=marchNumber;march++)
                {
                    marchLength+=l;
                    float3 pos = currentPos-lightdir*marchLength;
                    if(marchLength>dstInsideBox)
                        break;
                    float density = sampleDensity(pos);
                    totalDensity+=density*l;
                    
                    
                }
                float transmittance = BeerPowder(totalDensity,_LightAbsorption);
                return transmittance;
            }

            
            half4 Pixel(vertexOutput  IN): SV_TARGET{

                half4 backColor = _MainTex.Sample(sampler_MainTex, IN.uv);

                // 重建世界坐标
                float3 worldPosition = GetWorldPosition(IN.pos);
                float3 rayPosition = _WorldSpaceCameraPos.xyz;
                float3 worldViewVector = worldPosition - rayPosition;
                float3 rayDir = normalize(worldViewVector);

                
                float2 rayBoxInfo = rayBoxDst(_BoundBoxMin, _BoundBoxMax, rayPosition, rayDir);
                //float2 rayBoxInfo = RayCloudLayerDst(float3(0,0,0),6371,1500,4500,rayPosition,rayDir);
                float dstToBox = rayBoxInfo.x;
                float dstInsideBox = rayBoxInfo.y;
                //float marchingNumber = 16;
                float marchingLength = 0;
                float totalLum=0;
                float totalDensity = 0;
                float transmittance =1;//光照衰减
                float l = dstInsideBox/20;
                float3 lightDir = normalize(_MainLightPosition);
                //TODO:暴露参数
                float phase = HenyeyGreenstein(dot(rayDir,lightDir),0);
                float3 starpos = rayPosition+rayDir*dstToBox;
                for(int march = 0;march<=20;march++)
                {
                    marchingLength+=l;
                    float3 currentPos = starpos+rayDir*marchingLength;
                    if(marchingLength>dstInsideBox)
                        break;
                    float density = sampleDensity(currentPos);
                    if(density>0)
                    {
                        float lum = GetCurrentPositionLum(currentPos);
                        lum*=density*l;
                        totalLum += transmittance*Beer(totalDensity,_Absorption)*lum*phase*10;
                        transmittance *= exp(-density*l);
                        totalDensity+=density*l;
                       
                        
                    }
                }
                float3 CloudColor = _BaseColor*totalLum;
                return half4(backColor.xyz*transmittance+CloudColor,1);
    
            }
            ENDHLSL
        }
    }
}
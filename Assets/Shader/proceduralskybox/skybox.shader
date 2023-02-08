Shader "CasualAtmosphere/skybox"
{
    Properties
    {
        [Header(sun and moon)]
        _SunRadius ("太阳大小", Range(0,0.5)) = 0.5
        _SunFilling("太阳内部填充",Range(0,15)) = 1
        _MoonRadius("月亮大小",Range(0,0.5)) = 0.5
        _MoonFilling("月亮内部填充",Range(0,50)) = 1
        _MoonOffset("控制月牙的偏移",Range(-1,1)) = 0
        _DayBottonClolor("白天底部颜色",Color) = (1, 1, 1, 1)
        _DayTopClolor("白天顶部颜色",Color)= (1, 1, 1, 1)
        _NightBottonClolor("夜晚底部颜色",Color) = (1, 1, 1, 1)
        _NightTopClolor("夜晚顶部颜色",Color) = (1,1,1,1)
        [HDR]_SUN("太阳的颜色",Color) =(1,1,1,1)
        
        
        [Header(clouduv)]
        _Noise("基础扰动噪声",2D) ="white"{}
        _Distort("第一层噪音",2D) = "white"{}
        _Distortion("distort影响系数",Range(0,1)) = 1
        _SecNoise("第二层噪音",2D) ="white" {}
        [Toggle(FUZZY)] _FUZZY ("基础云朵是否扭曲", Float) = 1
        _CloudSpeed("云的移动速度",Float) = 1
        _CloudCutoff("cutoff参数",Range(0,2)) = 0
        _Fuzziness("fuzziness",Range(0,2)) = 1
        _FuzzinessUnder("_FuzzinessUnder",Range(0,2)) = 1
        
        [Header(colorofcloud)]
        _DayCloudEdge("白天云边缘",Color) = (1,1,1,1)
        _DayCloudMain("白天云朵主要",Color) = (1,1,1,1)
        _DayCloudNoMain("白天云朵次要",Color) = (1,1,1,1)
        
        _NightCloudEdge("夜晚云边缘",Color) = (1,1,1,1)
        _NightCloudMain("夜晚云朵主要",Color) = (1,1,1,1)
        _NightCloudNoMain("夜晚云朵次要",Color) = (1,1,1,1)
        _Brightness("云的亮度控制",Range(0,2)) = 1
        
        _Star("星星",2D) ="white" {}
        
        _HorizonColorDay("地平线颜色",Color) = (1,1,1,1)
        _HorizonIntensity("地平线强度",Range(0,10)) = 1
        _HorizonHeight("地平线偏移",Range(0,5)) = 0
        _HorizonColorNight("朝霞",Color)=(1,1,1,1)
        
        
        
        
        
        

    }
    SubShader
    {
        Cull Off 
        ZWrite Off 
        ZTest Always

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature FUZZY



            
            float _SunRadius;
            float _SunFilling;
            float _MoonRadius;
            float _MoonFilling;
            float _MoonOffset;
            float4 _SUN;

            
            float3 _DayBottonClolor;
            float3 _DayTopClolor;
            float3 _NightBottonClolor;
            float3 _NightTopClolor;

            
            float2 _Noise_ST;
            float2 _Distort_ST;
            float2 _SecNoise_ST;

            
            float _CloudSpeed;
            float _Distortion;

            float _CloudCutoff;
            float _Fuzziness;
            float _FuzzinessUnder;

            float4 _DayCloudEdge;
            float4 _DayCloudMain;
            float4 _DayCloudNoMain;

            float4 _NightCloudEdge;
            float4 _NightCloudMain;
            float4 _NightCloudNoMain;

            float _Brightness;

            float4 _HorizonColorDay;
            float _HorizonIntensity;
            float4 _HorizonColorNight;
            float _HorizonHeight;


            float2 _Star_ST;

            
            
            
            
            

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


            Texture2D _Noise;
            SAMPLER(sampler_Noise);
            Texture2D _Distort;
            SAMPLER(sampler_Distort);
            Texture2D _SecNoise;
            SAMPLER(sampler_SecNoise);
            Texture2D _Star;
            SAMPLER(sampler_Star);

            SAMPLER(sampler_LinearClamp);
            struct appdata
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
            };

            struct v2f
            {
                float3 uv : TEXCOORD0;
                float3 worldposition:TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.worldposition = TransformObjectToWorld(v.vertex);
                o.uv = v.uv;
                return o;
            }


            float4 frag (v2f i) : SV_Target
            {
                Light light = GetMainLight();

                float horizon = abs(i.uv.y*_HorizonIntensity-_HorizonHeight);
                float3 horizonGlow = saturate((1 - horizon * 5) * saturate(light.direction.y * 10)) * _HorizonColorDay;// 
                float3 horizonGlowNight = saturate((1 - horizon * 5) * saturate(-light.direction.y * 10)) * _HorizonColorNight;//
                horizonGlow += horizonGlowNight;

                
                float2 skyUV = i.uv.xz/i.uv.y;
                

                float3 gradientDay = lerp(_DayBottonClolor, _DayTopClolor, saturate(i.uv.y));
                float3 gradientNight =lerp(_NightBottonClolor, _NightTopClolor, saturate(i.uv.y));
                float3 skyGradients = lerp(gradientNight, gradientDay, saturate(_MainLightPosition.y));

                float baseNoise  = SAMPLE_TEXTURE2D(_Noise,sampler_Noise,(skyUV-_Time.x)*_Noise_ST.xy);
                float noise1 = SAMPLE_TEXTURE2D(_Distort,sampler_Distort,((skyUV+baseNoise)-(_Time.x*_CloudSpeed))*_Distort_ST.xy);
                float noise2 = SAMPLE_TEXTURE2D(_SecNoise,sampler_SecNoise,((skyUV+noise1*_Distortion)-(_Time.x*(_CloudSpeed*0.5)))*_SecNoise_ST.xy);


                

                float finalNoise = saturate(noise1*noise2)*3*saturate(i.uv.y);
                #if FUZZY
				        float clouds = saturate(smoothstep(_CloudCutoff * baseNoise, _CloudCutoff * baseNoise + _Fuzziness, finalNoise));
				        float cloudsunder = saturate(smoothstep(_CloudCutoff* baseNoise, _CloudCutoff * baseNoise + _FuzzinessUnder, noise2) * clouds);

                #else
                        float clouds = saturate(smoothstep(_CloudCutoff, _CloudCutoff + _Fuzziness, finalNoise));
                        float cloudsunder = saturate(smoothstep(_CloudCutoff, _CloudCutoff  + _FuzzinessUnder , noise2) * clouds);

                #endif

                float star = SAMPLE_TEXTURE2D(_Star,sampler_Star,skyUV);
                star*=saturate(i.uv.y);
                star*=saturate(-light.direction.y);
                star*=(1-clouds)*10;
                
                float4 DaycloudsColored = lerp(_DayCloudEdge,lerp( _DayCloudNoMain,_DayCloudMain,cloudsunder),clouds)*clouds;
                float4 NightcloudsColored = lerp(_NightCloudEdge,lerp(_NightCloudNoMain,_NightCloudMain,cloudsunder),clouds)*clouds;
                NightcloudsColored*=horizon;

                float4 cloudsColored = lerp(NightcloudsColored, DaycloudsColored, saturate(light.direction.y));
                cloudsColored += (_Brightness * cloudsColored * horizon);


                
                float4 sun = distance(i.uv.xyz, _MainLightPosition);
                float4 sunDisc = 1-(sun/_SunRadius);
                sunDisc = saturate(sunDisc*_SunFilling)*_SUN;

                float4 moon = distance(i.uv.xyz,-_MainLightPosition);
                float4 MoonDisc = 1-(moon/_MoonRadius);
                
                MoonDisc = saturate(MoonDisc*_MoonFilling);
                float offsetmoon = distance(float3(i.uv.x+_MoonOffset,i.uv.yz),-_MainLightPosition);
                float othermoonDisc = 1-(offsetmoon/_MoonRadius);
                othermoonDisc=saturate(othermoonDisc*_MoonFilling);
                MoonDisc = saturate(MoonDisc-othermoonDisc);

                float sunandmoon = (sunDisc+MoonDisc)*saturate(i.uv.y);
                sunandmoon *=(1-clouds);
                
                                
                
                return float4(smoothstep(0,1,cloudsColored+sunandmoon.xxx+skyGradients+star.xxx+horizonGlow),1);
            }
            ENDHLSL
        }
    }
}

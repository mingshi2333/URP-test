Shader "URP/water"
{
    Properties
    {
       [NoScaleOffset] _Foam ("基础贴图(R通道深度对应的颜色衰减GB通道为浪花)",2D) = "white" {}
       [NoScaleOffset] _WaterNormal("NormalTex",2D) = "bump"{}
        _DeepColor ("深处颜色",COLOR)=(1,1,1,1)
        _ShalowColor("浅出颜色",COLOR)=(1,1,1,1)
        _WaveParams("两个水流速",Float) = (0,0,0,0)
       _WaterSpecular("水的高光",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(0,100)) = 50
        _NormalScale("法线强度",Float) = 1
        _rimIntensity("菲涅尔强度",Float) =1
        _RimPower("菲涅尔系数",Float) = 1
    }
    SubShader {

        HLSLINCLUDE
        //#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        

        CBUFFER_START(UnityPerMaterial)
            float4 _Foam_ST;
            float4 _WaterNormal_ST;
            half3 _ShalowColor;
            half3 _DeepColor;
            float4 _WaveParams;
            float _NormalScale;
            float4 _WaterSpecular;
            float _Gloss;
            float _RimPower;
            float _rimIntensity;
            float4 _ZBufferParam;
        CBUFFER_END

        TEXTURE2D(_Foam);
        TEXTURE2D(_CameraDepthTexture);
        SAMPLER(sampler_CameraDepthTexture);
        SAMPLER(sampler_Foam);
        TEXTURE2D(_WaterNormal);
        SAMPLER(sampler_WaterNormal);
        struct a2v
        {
            float4 position:POSITION;
            float4 normalOS:NORMAL;
            float4 tangentOS:TANGENT;
            float2 uv:TEXCOORD0;
        };
        struct v2f
        {
            float4 pos:SV_POSITION;
            float2 uv:TEXCOORD0;
            float4 screenPos:TEXCOORD05;
            float4 normalWS: TEXCOORD1;
			float4 tangentWS: TEXCOORD2;
			float4 bitangentWS: TEXCOORD3;
            float3 normal:NORMAL;
            float3 worldPos:TEXCOORD4;

        };
        ENDHLSL

        pass
        {
            Tags{
                "LightMode" ="UniversalForward"
                "Queue" = "Transparent"
            }
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            HLSLPROGRAM
            #pragma vertex vert 
            #pragma fragment frag 
            v2f vert(a2v i)
            {
                v2f o;
                o.pos = TransformObjectToHClip(i.position);
                o.uv = TRANSFORM_TEX(i.uv,_Foam);
                o.worldPos = TransformObjectToWorld(i.position);
                o.normal = TransformObjectToWorldNormal(i.normalOS);
                o.normalWS = float4(TransformObjectToWorldNormal(i.normalOS).xyz, o.worldPos.z);
				o.tangentWS = float4(TransformObjectToWorldDir(i.tangentOS).xyz, o.worldPos.x);
				o.bitangentWS = float4(cross(o.tangentWS.xyz, o.normalWS.xyz).xyz, o.worldPos.y);
                o.screenPos = ComputeScreenPos(o.pos);

    
                return o;
            
            }
            real4 frag(v2f i) :SV_TARGET
            {
                Light light = GetMainLight();
                real4 lightColor = real4(light.color,1);
                float3 lightDir = light.direction;
                float3 viewdir = normalize(_WorldSpaceCameraPos-i.worldPos);
                float3 h = normalize(viewdir+lightDir);
                float3x3 TBN = {normalize(i.tangentWS.xyz), normalize(i.bitangentWS.xyz), normalize(i.normalWS.xyz)};
                half2 panner1 = ( _Time.y * _WaveParams.xy + i.uv);
                half2 panner2 = ( _Time.y * _WaveParams.zw + i.uv);
                real degree = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,i.uv).r;//深度
                half3 worldNormal = BlendNormal(UnpackNormal(SAMPLE_TEXTURE2D(_WaterNormal,sampler_WaterNormal,panner1)),UnpackNormal(SAMPLE_TEXTURE2D(_WaterNormal,sampler_WaterNormal,panner2)));
                worldNormal = lerp(half3(0, 0, 1), worldNormal, _NormalScale);
                worldNormal = mul(worldNormal,TBN);
                


                real4 screenPos = i.screenPos;
                real4 screenPosNDC = screenPos/screenPos.w;
                real depth = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,screenPosNDC.xy).r;
                real cameradepth = LinearEyeDepth(depth,_ZBufferParam);
                real wathe_depth = screenPos.w;
                real eyedepth = abs( cameradepth - wathe_depth );
                half depthMask = 1-eyedepth;
                
                half3 diffuse = lerp(_ShalowColor, _DeepColor, degree);
                real NdotV = saturate(dot(worldNormal,viewdir));
                real3 specular = lightColor.rgb*_WaterSpecular*pow(max(0, dot(worldNormal, h)), _Gloss);
                real3 rim = pow(1-saturate(NdotV),_RimPower)*lightColor*_rimIntensity;
                //return real4(_ShalowColor*NdotV+specular,1);
                return real4(rim+(_ShalowColor*NdotV+specular),0.5);
                //return real4(wathe_depth.rrr,1);
                

            }
            
            ENDHLSL

        }
    }
}
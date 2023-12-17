Shader "Unlit/FOG"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FogColor("FogColor",color) = (1,1,1,1)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        float3 _FogColor;

        float _FogGlobalDensity;//全局密度
        float _FogFallOff;
        float _FogHeight;//雾效高度
        float _FogStartDis;
        float _FogInscatteringExp;
        float _FogGradientDis;

        half3 ExponentialHeightFog(half3 col, half3 posWorld)
        {
            half heightFallOff = _FogFallOff * 0.01;
            half falloff = heightFallOff * ( posWorld.y -  _WorldSpaceCameraPos.y- _FogHeight);
            half fogDensity = _FogGlobalDensity * exp2(-falloff);
            half fogFactor = (1 - exp2(-falloff))/falloff;
            half3 viewDir = _WorldSpaceCameraPos - posWorld;
            half rayLength = length(viewDir);
            half distanceFactor = max((rayLength - _FogStartDis)/ _FogGradientDis, 0);
            half fog = fogFactor * fogDensity * distanceFactor;
            half inscatterFactor = pow(saturate(dot(-normalize(viewDir), _MainLightPosition.xyz)), _FogInscatteringExp);
            inscatterFactor *= 1-saturate(exp2(falloff));
            inscatterFactor *= distanceFactor;
            half3 finalFogColor = lerp(_FogColor, _MainLightColor, saturate(inscatterFactor));
            return lerp(col, finalFogColor, saturate(fog));
        }    
        
        ENDHLSL



        Pass
        {
            Tags{"LightMode"="UniversalForward"}
            ZTest Always
            ZWrite Off
            Cull Off

            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/core.hlsl"
		    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float4 ssTexcoord : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_CameraDepthTexture);
            SAMPLER(sampler_CameraDepthTexture);
            float4 _MainTex_ST;


            v2f vert (appdata v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.ssTexcoord = ComputeScreenPos(o.positionCS);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float2 ssuv = i.ssTexcoord.xy/i.ssTexcoord.w; //uv
                float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,ssuv);//深度图采样
                float ssdepth = LinearEyeDepth(depth,_ZBufferParams);//线性深度
                float3 postionWS = ComputeWorldSpacePosition(ssuv,depth,unity_MatrixInvVP);
                

                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex,ssuv) ;
                //half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex,i.uv) + step(_FogDistance,ssdepth) * _FogIntensity * ssdepth * _FogColor;
                //half3 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex,i.uv).xyz + pow(ssdepth,_FogDistance) * _FogIntensity * _FogColor;
                half3 fogColor = ExponentialHeightFog(col, postionWS);
                
                
                return half4(fogColor,1);

                

            }
            ENDHLSL
        }
    }
}
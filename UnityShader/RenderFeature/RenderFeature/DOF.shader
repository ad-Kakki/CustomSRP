Shader "Unlit/DOF"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"}
        LOD 100

        HLSLINCLUDE
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/core.hlsl"
		    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            
 
            struct appdata
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct v2f
            {
                float2 uv0 : TEXCOORD0;
                float4 positionCS : SV_POSITION;
                float4 ssTexcoord : TEXCOORD1;
                float2 uv[5] : TEXCOORD2;
                float offset : COLOR0;
            }; 

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_CocTex);
            SAMPLER(sampler_CocTex);
            TEXTURE2D(_BlurTex);
            SAMPLER(sampler_BlurTex);

            float4 _MainTex_ST;

            float _FocusDistance;
            float _BokehRadius;
            float _BlurSize;
            float4 _MainTex_TexelSize;


            v2f blurVerty(appdata v){
                v2f o;
                o.positionCS = TransformWorldToHClip(v.positionOS);
                o.uv0 = TRANSFORM_TEX(v.uv, _MainTex);

                o.uv[0] = o.uv0;
                o.uv[1] = o.uv0 + float2(0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
                o.uv[2] = o.uv0 - float2(0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
                o.uv[3] = o.uv0 + float2(0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
                o.uv[4] = o.uv0 - float2(0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
                return o;
            }
            v2f blurVertx(appdata v){
                v2f o;
                o.positionCS = TransformWorldToHClip(v.positionOS);
                o.uv0 = TRANSFORM_TEX(v.uv, _MainTex);

                o.uv[0] = o.uv0;
                o.uv[1] = o.uv0 + float2( _MainTex_TexelSize.x * 1.0, 0) * _BlurSize;
                o.uv[2] = o.uv0 - float2( _MainTex_TexelSize.x * 1.0, 0) * _BlurSize;
                o.uv[3] = o.uv0 + float2( _MainTex_TexelSize.x * 2.0, 0) * _BlurSize;
                o.uv[4] = o.uv0 - float2( _MainTex_TexelSize.x * 2.0, 0) * _BlurSize;
                return o;

            }

            float4 blurFrag(v2f i) : SV_Target{
                float weight[3] = {0.4026, 0.2442 ,0.0545};
                float3 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[0]).rgb * weight[0];
                for (int j = 1; j < 3; j++){
                    col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[j*2-1]).rgb * weight[j];
                    col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[j*2]).rgb * weight[j];

                }
                return float4(col,1);
            }



        ENDHLSL



        Pass
        {
            Name "Pass1"
            Tags{"LightMode"="UniversalForward"}
            ZTest Always
            ZWrite Off
            Cull Off  
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //TEXTURE2D(_CameraDepthTexture);
            //SAMPLER(sampler_CameraDepthTexture);

            v2f vert (appdata v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.uv0 = TRANSFORM_TEX(v.uv, _MainTex);
                o.ssTexcoord = ComputeScreenPos(o.positionCS);
                
                return o;
            }
float2 Polar(float2 UV)
{
    //0~1的1象限转-0.5~0.5的四象限
    float2 uv = UV-0.5;

    //d为各个象限坐标到0点距离,数值为0~0.5
    float distance=length(uv);

    //0~0.5放大到0~1
    distance *=2;

    //4象限坐标求弧度范围是 [-pi,+pi]
    float angle=atan2(uv.x,uv.y);
				
    //把 [-pi,+pi]转换为0~1
    float angle01=angle/3.14159/2+0.5;

    //输出角度与距离
    return float2(angle01,distance);
}
            float4 frag (v2f i) : SV_Target
            {
                float2 ssuv = i.ssTexcoord.xy/i.ssTexcoord.w; //uv
                float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture,sampler_CameraDepthTexture,ssuv);//深度图采样
                float ssdepth = LinearEyeDepth(depth,_ZBufferParams);//线性深度                
                float coc = saturate( 0.0001 * _BokehRadius * (1 - ssdepth - _FocusDistance) * (1 - ssdepth - _FocusDistance));
            
                return float4(coc,coc,coc,1);
            }
            ENDHLSL
        }
        Pass{
            Name "Pass2"
            Tags{"LightMode"="UniversalForward"}
            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex blurVertx
            #pragma fragment blurFrag

            ENDHLSL
        }

        Pass{
            Name "Pass3"
            Tags{"LightMode"="UniversalForward"}
            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex blurVerty
            #pragma fragment blurFrag

            ENDHLSL
        }

        Pass
        {
            Name "Pass4"
            Tags{"LightMode"="UniversalForward"}
            ZTest Always
            ZWrite Off
            Cull Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            v2f vert (appdata v)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(v.positionOS);
                o.uv0 = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex,i.uv0).rgb ;
                float3 coc = SAMPLE_TEXTURE2D(_CocTex, sampler_CocTex,i.uv0).rgb ;
                float3 dof = SAMPLE_TEXTURE2D(_BlurTex, sampler_BlurTex,i.uv0).rgb ;
                float dofStrength = smoothstep(0.1, 1, abs(coc));
                float3 color = lerp(col.rgb, dof.rgb, dofStrength);
                
                return float4(color,1);
            }
            ENDHLSL
        }
    }
}
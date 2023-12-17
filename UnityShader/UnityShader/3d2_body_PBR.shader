Shader "Custom/3d2_body_PBR"
{
    Properties
    {
        [Header(Texture)]
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _AmbientScale("AmbientScale", Range(0, 1)) = 0.1

        [Space][Header(__________ Roughness __________)][Space]
        _RoughnessTex ("_RoughnessTex", 2D) = "white" {}
        _Roughness ("_Roughness", Range(0,1)) = 0     
       
        [Space][Header(__________ Metallic __________)][Space]
        _MetalTex ("_MetalTex", 2D) = "white" {}
        _Metal ("_Metal", Range(0,1)) = 0

        [Header(Custom Lighting)]
        _ShadowColor("ShadowColor", Color) = (1,1,1,1)
        _BaseColor("BaseColor", Color) = (1,1,1,1)        
        _LightSmooth("LightSmooth", Range(0, 1)) = 0.1
        _RampTex("RampTex", 2D) = "white" {}
        _RampMapYRange("RampMapYRange", Range(0, 1)) = 0.1
        _RampSide("DarkSide", Range(0, 1)) = 0.5
        _BrightSide ("BrightSide", Range(0, 1)) = 0.5
        _RampSmoothScale ("RampSmoothScale", Range(0, 3)) = 2

        [Header(Custom SpaceLighting)]
        _SpaceColor("SpaceColor", Color) = (1,1,1,1)
        _SpaceSmoothWidth ("SpaceSmoothWidth", Range(0, 0.1)) = 0.05
        _SpaceThreshold ("SpaceThreshold", Range(0, 1)) = 1

        [Header(ILMTex)]
        _ILMTex("ILMTex", 2D) = "white" {}
        _GradientTex("GradientTex", 2D) = "white" {}
        _specularScale("specularScale", Range(0, 1)) = 0.1

        [Header(SSRim)]
        _RimLightColor("RimLightColor", Color) = (1,1,1,1)
        _Threshold("Threshold", Range(0, 5)) = 0.1
        _RimOffect("RimOffect", Range(-5, 5)) = 4.5

        [Header(Line)]
        _OutlineWidth ("Outline Width", Range(0.0, 0.08)) = 0
        _OutlineColor ("Outline Color", color) = (0, 0, 0, 1)
        _InnerStrokeIntensity ("Inner Stroke Intensity", Range(0.0, 3)) = 1

    }
    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"
        // #include "commonPBR.cginc"
        #include "AutoLight.cginc"
        #include "Lighting.cginc"

        sampler2D _MainTex;
        float3 _MainColor;
        sampler2D _ILMTex;
        float _specularScale;
        sampler2D _GradientTex;
        //Light
        float3 _ShadowColor;
        float3 _BaseColor;
        float _LightSmooth;
        float _RampMapYRange;
        sampler2D _RampTex;
        float _RampSide;
        float _BrightSide;
        float _RampSmoothScale;
        float3 _SpaceColor;
        float _SpaceSmoothWidth;
        float _SpaceThreshold;
        //Hair
        sampler2D _MaskTexture;
        float _AnisoHairFresnelPow;
        float _AnisoHairFresnelIntensity;
        float _AnisoScale;
        //SSrim
        sampler2D _CameraDepthTexture;
        float3 _RimLightColor;
        float _Threshold;
        float _RimOffect;
        float _AmbientScale;

        //PBR
        float _Roughness,_Metal;
        sampler2D _RoughnessTex,_MetalTex;


        float depthRim(float4 pos, float3 nDirWS){
            //depthRim
            float3 nDirVS = normalize(mul((float3x3)UNITY_MATRIX_V, nDirWS));
            float2 screenParams01 = float2(pos.x/_ScreenParams.x,pos.y/_ScreenParams.y);
            // float2 offectSamplePos = screenParams01-float2(_RimOffect*dot(nDirWS,lDirWS)/i.pos.w/_ScreenParams.x,0);
            float2 offectSamplePos = screenParams01+nDirVS*_RimOffect/pos.w/_ScreenParams.x;
            float offcetDepth = tex2D(_CameraDepthTexture, offectSamplePos);
            float trueDepth   = tex2D(_CameraDepthTexture, screenParams01);
            float linearEyeOffectDepth = LinearEyeDepth(offcetDepth);
            float linearEyeTrueDepth = LinearEyeDepth(trueDepth);
            float depthDiffer = linearEyeOffectDepth-linearEyeTrueDepth;
            float rimIntensity = step(_Threshold,depthDiffer);
            return rimIntensity;
        }
        float3 RampShaodw(float NdotL){
            float halfLambertRamp = smoothstep(0.0, _RampSmoothScale, NdotL * 0.5 + 0.5);
            float3 var_rampTex = tex2D(_RampTex, float2(halfLambertRamp,_RampSide));
            return var_rampTex;
        }
        float NDF(float NdotH , float rough){
            float a = rough * rough;
            float a2 = a *a ;
            float NdotH2 = NdotH * NdotH;
            float denom = (NdotH2 * (a2 - 1) + 1);
            denom = UNITY_PI * denom * denom;
            return a2/denom;
        }
        float GF(float NdotV,float NdotL,float rough){
            float r = (rough + 1);
            float k = (r*r)/8;
            
            float ggx1 = NdotV /lerp(k,1,NdotV);
            float ggx2 = NdotL /lerp(k,1,NdotL);
            return ggx1 * ggx2;
        }
        float3 Fresnel(float NdotV,float3 F0){
            return lerp(F0,1,pow(1 - NdotV , 5));
        }
        float3 PBR(float3 pos,float3 normal,float3 albedo,float rough,float metal,float ao, float shadow){
            float3 viewDir = normalize(_WorldSpaceCameraPos - pos);
            float3 lightDir = UnityWorldSpaceLightDir(pos);
            float3 halfDir = normalize(normal+lightDir);
            half NdotL = saturate(dot(normal,lightDir));
            half NdotH = saturate(dot(normal,halfDir));
            half NdotV = saturate(dot(normal,viewDir));
            float3 F0 = 0.04;
            F0 = lerp(F0,albedo,metal);
            float D = NDF(NdotH,rough);
            float G = GF(NdotV,NdotL,rough);
            float F = Fresnel(NdotV , F0);
            D = min(D,10);
            float3 kD = 1- F;
            kD *= 1-metal;
            float3 specular = (D * G * F) / (4*NdotV*NdotL + 0.00001);
            float3 diffuse = kD * albedo /UNITY_PI;
            float3 finalCol = (diffuse + specular) * _LightColor0 * shadow;
            //env col
            float3 irradiance = ShadeSH9(float4(normal,1));
            float3 diffuseEnvCol = irradiance * albedo;
            float4 color_cubemap = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0,reflect(-viewDir , normal), 6* rough);
            float3 specularEnvCol = DecodeHDR(color_cubemap,unity_SpecCube0_HDR);
            specularEnvCol *= F;
            float3 envCol = (kD * diffuseEnvCol + specularEnvCol);
            envCol *= ao;
            
            return finalCol+envCol;
        }
        float3 PBR_Direct(float3 pos,float3 normal,float3 albedo,float rough,float metal,float ao, float shadow){
            float3 viewDir = normalize(_WorldSpaceCameraPos - pos);
            float3 lightDir = UnityWorldSpaceLightDir(pos);
            float3 halfDir = normalize(normal+lightDir);
            half NdotL = saturate(dot(normal,lightDir));
            half NdotH = saturate(dot(normal,halfDir));
            half NdotV = saturate(dot(normal,viewDir));
            float3 F0 = 0.04;
            F0 = lerp(F0,albedo,metal);
            float D = NDF(NdotH,rough);
            float G = GF(NdotV,NdotL,rough);
            float F = Fresnel(NdotV , F0);
            D = min(D,10);
            float3 kD = 1- F;
            kD *= 1-metal;
            float3 specular = (D * G * F) / (4*NdotV*NdotL + 0.00001);
            float3 diffuse = kD * albedo /UNITY_PI;
            float3 finalCol = (diffuse + specular) * _LightColor0 * shadow;
            return finalCol;
        }



        ENDCG
        ////////不透明物体渲染pass////////
        Pass{
            Name "FORWARDBASE"

            Tags{"LightMode" = "ForwardBase" "RenderType" = "Opaque"}
            Cull Off

            //Zwrite On
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdbase_fullshadows

            struct VertexInput{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;

            };
            struct VertexOutput{
                float4 pos : SV_POSITION;
                float3 nDirWS : TEXCOORD0;
                float2 uv0 : TEXCOORD1;
                float3 posWS : TEXCOORD2;
                float3 posVS : TEXCOORD3;
                float4 tDirWS : TEXCOORD4;
                LIGHTING_COORDS(5,6)                
            };
            VertexOutput vert(VertexInput v){
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                o.posVS = UnityObjectToViewPos(v.vertex);

                return o;
            }

            float4 frag(VertexOutput i) : SV_Target{
                float4 var_MianTex = tex2D(_MainTex, i.uv0);
                fixed3 vDirWS = UnityWorldSpaceViewDir(i.posWS);
                float3 nDirWS = i.nDirWS;
                float3 lDirWS = UnityWorldSpaceLightDir(i.posWS);
                float3 hDirWS = normalize(vDirWS + lDirWS);

                float NdotL = saturate(dot(nDirWS,lDirWS));
                float3 NdotH = dot(nDirWS, hDirWS);

                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * _AmbientScale;
                //获取阴影
                float atten = LIGHT_ATTENUATION(i);
                
                float3 var_rampTex = RampShaodw(NdotL);
                float lSmooth = smoothstep(0.01, _LightSmooth, NdotL*0.5+0.5);
                float3 lLerp = lerp(var_rampTex, var_MianTex.rgb, lSmooth) ;

                
                // float space = NdotH*0.5+0.5;
                // space = lerp(0, 1, smoothstep(-_SpaceSmoothWidth, _SpaceSmoothWidth, space - _SpaceThreshold) * step(0.0001,_SpaceThreshold));
                // float3 spcaeColor = space * _SpaceColor;

                //metallic
                // float H = normalize(vDirWS + lDirWS);
                // float4 ilmTex = tex2D(_ILMTex, i.uv0);
                // float metallicMask = ilmTex.r;
                // float cloth = ilmTex.g;
                // float metallicAo = ilmTex.b;
                // float spceularLight = lerp(var_rampTex,metallicMask*metallicAo, lSmooth);
                float rough = tex2D(_RoughnessTex, i.uv0) * _Roughness;
                float metal = tex2D(_MetalTex, i.uv0) * _Metal;
                float3 pbrColor = PBR(i.posWS, nDirWS, lLerp * var_MianTex.rgb, rough, metal, 1,atten);

                float3 Color = ambient + pbrColor;//+ spceularLight*cloth*_specularScale;
                float rimIntensity = depthRim(i.pos, nDirWS);
                Color = lerp(Color,_RimLightColor,rimIntensity);
                return float4(Color,1);
            }
            ENDCG
        }
        Pass{
            Name "FORWARDADD"

            Tags{"LightMode" = "ForwardAdd" "RenderType" = "Opaque"}
            Blend One One
            // Cull Off
            //Zwrite On
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdadd_fullshadows

            struct VertexInput{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;

            };
            struct VertexOutput{
                float4 pos : SV_POSITION;
                float3 nDirWS : TEXCOORD0;
                float2 uv0 : TEXCOORD1;
                float3 posWS : TEXCOORD2;
                float3 posVS : TEXCOORD3;
                float4 tDirWS : TEXCOORD4;

                LIGHTING_COORDS(5,6)                
            };
            VertexOutput vert(VertexInput v){
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.posWS = mul(unity_ObjectToWorld, v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);
                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                o.posVS = UnityObjectToViewPos(v.vertex);

                return o;
            }
            float4 frag(VertexOutput i) : SV_Target{
                float4 var_MianTex = tex2D(_MainTex, i.uv0);
                fixed3 vDirWS = UnityWorldSpaceViewDir(i.posWS);
                float3 nDirWS = i.nDirWS;
                float3 lDirWS = UnityWorldSpaceLightDir(i.posWS);
                float3 hDirWS = normalize(vDirWS + lDirWS);

                float NdotL = saturate(dot(nDirWS,lDirWS));
                float3 NdotH = dot(nDirWS, hDirWS);

                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * _AmbientScale;
                //获取阴影
                float atten = LIGHT_ATTENUATION(i);
                
                float3 var_rampTex = RampShaodw(NdotL);
                float lSmooth = smoothstep(0.01, _LightSmooth, NdotL*0.5+0.5);
                float3 lLerp = lerp(var_rampTex, var_MianTex.rgb, lSmooth) ;
                
                //metallic
                // float H = normalize(vDirWS + lDirWS);
                // float4 ilmTex = tex2D(_ILMTex, i.uv0);
                // float metallicMask = ilmTex.r;
                // float cloth = ilmTex.g;
                // float metallicAo = ilmTex.b;
                // float spceularLight = lerp(var_rampTex,metallicMask*metallicAo, lSmooth);
                float rough = tex2D(_RoughnessTex, i.uv0) * _Roughness;
                float metal = tex2D(_MetalTex, i.uv0) * _Metal;
                float3 pbrColor = PBR_Direct(i.posWS, nDirWS, lLerp * var_MianTex.rgb, rough, metal, 1,atten);
                float3 Color = pbrColor;//+ spceularLight*cloth*_specularScale;
                float rimIntensity = depthRim(i.pos, nDirWS);
                Color = lerp(Color,_RimLightColor,rimIntensity);
                return float4(Color, 1);
            }
            ENDCG
        }
        ////////阴影pass//////
        Pass{
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            CGPROGRAM 

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f{
                V2F_SHADOW_CASTER;
            };
            v2f vert(appdata_base v){
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
                return o;
            }
            float4 frag(v2f i):SV_Target{
                SHADOW_CASTER_FRAGMENT(i);
            }
            ENDCG
        }
        // UsePass "Custom/Depth/DEPTHPASS"
        //OUTLine
        pass
        {
            CULL Front
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"
            
            struct a2v
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
            };
            struct v2f
            {
                float4 pos: SV_POSITION;
            };
            
            fixed _OutlineWidth;
            fixed4 _OutlineColor;
            
            v2f vert(a2v v)
            {
                v2f o;
                // float3 viewPos = UnityObjectToViewPos(v.vertex);
                // float3 viewNormal = mul(UNITY_MATRIX_IT_MV, v.normal);
                // viewNormal.z = -0.5f;
                // viewPos += normalize(viewNormal) * _OutlineWidth;
                // o.pos = UnityViewToClipPos(viewPos);
                
                float4 pos = UnityObjectToClipPos(v.vertex);
                float3 viewNormal = mul(UNITY_MATRIX_IT_MV, v.normal);
                float3 proNormal = normalize(TransformViewToProjection(viewNormal)) * pos.w;
                float4 nearUpperRight = mul(unity_CameraInvProjection, _ProjectionParams.y * float4(1, 1, -1, 1));
                proNormal.x *= abs(nearUpperRight.y / nearUpperRight.x);
                pos.xy += proNormal.xy * _OutlineWidth * 0.1f;
                o.pos = pos;
                
                return o;
            }
            fixed4 frag(v2f i): SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }
    }
}

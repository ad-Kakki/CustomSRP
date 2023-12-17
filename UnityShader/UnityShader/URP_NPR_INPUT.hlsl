#ifndef CUSTOM_NPR_INPUT_INCLUDED
#define CUSTOM_NPR_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);
TEXTURE2D(_SkinMask);
SAMPLER(sampler_SkinMask);
TEXTURE2D(_RampMap);
SAMPLER(sampler_RampMap);
TEXTURE2D(_SdfFaceMap);
SAMPLER(sampler_SdfFaceMap);
TEXTURE2D(_HairMask);
SAMPLER(sampler_HairMask);
TEXTURE2D(_RoughnessTex);
SAMPLER(sampler_RoughnessTex);
TEXTURE2D(_MetalTex);
SAMPLER(sampler_MetalTex);
TEXTURE2D(_AOTex);
SAMPLER(sampler_AOTex);
TEXTURE2D(_NormalDisTex);
SAMPLER(sampler_NormalDisTex);



CBUFFER_START(UnityPerMaterial)
    float4 _Params;
    float _Roughness;
    float _Metal;
    float _AO;
    float _NormalDis;
	//
	float4 _MainTex_ST;
	//RampMap
   	float _RampShadowRange;
	float _RampMapXRange;
	float _RampMapYRange;
	//Rim
	float _RimThreshold;
	float4 _RimLightColor;
	float _RimOffect;
    //Silk
    float4 _SkilCentre;
    float4 _SkilEdge;
    float _SkilCentreRange;

	//SDF
	float _LightSmooth;
	//AnisoHairFresnel
	float4 _spaceExp;
	float3 _SPColor1;
	float3 _SPColor2;
    float _AnisoScale;
	//Emission
	float _EmissionIntensity;
    
CBUFFER_END
//-----------------test-----------------//
//GetNormal
//GetWorldSpaceViewDir
//GetWorldSpaceNormalDir
//GetWorldSpaceLightDir


//-----------------universal-----------------//
//Fresnel
float3 GetFresnel(float NdotV,float3 F0){
    return lerp(F0,1,pow(1 - NdotV , 5));
}
//RampMapShadow
float3 GetRampShaodw(float NdotL){
    float halfLambert =max(0,NdotL)*0.5+0.5;
    float3 var_rampTex = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, 
        float2(halfLambert* (1.0 / _RampShadowRange - 0.003), _RampMapYRange)).rgb;
    // float3 var_rampTex = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, 
    //    float2(_RampMapXRange, LambertRamp* (1.0 / _RampMapYRange - 0.003)));

    return var_rampTex;
}
//DepthRim
float GetDepthRim(float4 screenPos, float3 nDirWS){
    //depthRim
    float3 nDirVS = normalize(mul((float3x3)UNITY_MATRIX_V, nDirWS));
    float2 screenParams01 = float2(screenPos.x / _ScreenParams.x, screenPos.y / _ScreenParams.y);
    float2 offectSamplePos = screenParams01+nDirVS*_RimOffect;
    float offcetDepth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, offectSamplePos);
    float trueDepth   = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenParams01);
    float linearEyeOffectDepth = LinearEyeDepth(offcetDepth, _ZBufferParams);
    float linearEyeTrueDepth = LinearEyeDepth(trueDepth, _ZBufferParams);
    float depthDiffer = linearEyeOffectDepth-linearEyeTrueDepth;
    float rimIntensity = step(_RimThreshold * 0.1, depthDiffer);
    
	return rimIntensity;
}
//MetalMap
float GetMetal(float3 nDirWS){

	float MetalDir = normalize(mul((float3x3)UNITY_MATRIX_V,nDirWS));
	float MetalRadius = saturate(1 - MetalDir) * saturate(1 + MetalDir);
	float MetalFactor = saturate(step(0.5,MetalRadius)+0.25) * 0.5 * saturate(step(0.15,MetalRadius) + 0.25);

	return MetalFactor;
}
//GetEmission
float3 GetEmission(float4 Color, float EmissionMask){
	return Color.a * Color * _EmissionIntensity * abs((frac(_Time.y * 0.5) - 0.5) * 2) * EmissionMask ;
}
//OutLine



//-----------------hair-----------------//
float StrandSpecular(float3 T,float3 V,float3 L,float exponent)
{
    float3 H = normalize(L+V);
    float dotTH = dot(T,H);
    float sinTH = sqrt(1- dotTH * dotTH);
    float dirAtten = smoothstep(-1,0,dotTH);
    return dirAtten*pow(sinTH,exponent);
}
float3 AnisoHair(float2 uv, float3 nDirWS, float3 vDirWS, float3 lDirWS, float NdotL, float3 bDirWS, float anisoHairMask){
    //anisoHairFresnel
    // float AnisoMask = tex2D(_MaskTexture, uv).r;
    // float anisoHairFresnel = pow((1.0 - saturate(dot(nDirWS, vDirWS))),
    //                         _AnisoHairFresnelPow) * _AnisoHairFresnelIntensity;
    // float anisoHair = saturate(1-anisoHairFresnel) * saturate(AnisoMask*NdotL);
    // return anisoHair;

    float3 T1 = normalize(nDirWS * anisoHairMask + bDirWS );
    float3 T2 = normalize(nDirWS * anisoHairMask + bDirWS);
    float3 anisoHairSpecular1 = StrandSpecular(T1,vDirWS,lDirWS, _spaceExp.x );
    float3 anisoHairSpecular2 = StrandSpecular(T2,vDirWS,lDirWS, _spaceExp.y );
    float3 anisoSpecular = anisoHairSpecular1*_SPColor1+anisoHairSpecular2*_SPColor2;
    return anisoSpecular * _MainLightColor ;

    // float anisoHairFresnel = pow((1.0-saturate(dot(normalize(nDirWS), normalize(vDirWS)))),2)*0.5;
    // float anisoHair = saturate(1 - anisoHairFresnel);
    // return anisoHair;   
}

//-----------------face-----------------//
//FaceShadow_SDF
float GetFaceShadow(float2 uv, float3 lDirWS){
    //face Shadow
    // float4 shadowTex = tex2D(_ShadowTex, i.uv0);
    // float dotF = dot(_HeadForward.xz, lDirWS.xz);
    // float dotR = dot(_HeadRight.xz, lDirWS.xz);
    // float dotFStep = step(0, dotF);
    // float dotRAcos = (acos(dotR)/PI) * 2;
    // float dotRAcosDir = (dotR < 0) ? 1 - dotRAcos : dotRAcos - 1;
    // float texShadowDir = (dotR < 0) ? shadowTex.g : shadowTex.r;
    // float shdowDir = step(dotRAcosDir, texShadowDir) * dotFStep;                
    //SDF_FACESHADOW
    float3 frontDir = (TransformObjectToWorldDir(float3(0.0,0.0,1.0)));                                  //拿到模型的向前方向
    float3 rightDir = (TransformWorldToObjectDir(float3(1.0,0.0,0.0)));                                 //拿到模型的向右方向
    float FLambert = dot(lDirWS.xz,frontDir.xz)*0.7+0.3;                                                 //用来得到类似半兰伯特效果的阈值
    float FLambert2 = dot(lDirWS.xz,rightDir.xz);                                                       //光照方向与x轴正方向点乘，正值为右脸阴影，负值为左脸阴影
    float shadowUVx = lerp(-uv.x,uv.x,step(FLambert2,0));                                               //判断该采样哪边的阴影
    float ver_Faceshadow = SAMPLE_TEXTURE2D(_SdfFaceMap, sampler_SdfFaceMap, float2(shadowUVx,uv.y));   //采样阴影
    float face = FLambert<ver_Faceshadow?1.0:0.0;                                                       //最后将阈值和贴图的值比较
    // float faceSmooth = smoothstep(_FaceSmooth,1 ,face ); 
    return face;
}


//-----------------body-----------------//
//SSS




//-----------------eyes-----------------//

//-----------------light-----------------//
//获取光线反射方向
inline half3 DecodeHDR(half4 data, half4 decodeInstructions, int colorspaceIsGamma)
{
    // Take into account texture alpha if decodeInstructions.w is true(the alpha value affects the RGB channels)
    half alpha = decodeInstructions.w * (data.a - 1.0) + 1.0;

    // If Linear mode is not supported we can skip exponent part
    if(colorspaceIsGamma)
        return (decodeInstructions.x * alpha) * data.rgb;

#   if defined(UNITY_USE_NATIVE_HDR)
    return decodeInstructions.x * data.rgb; // Multiplier for future HDRI relative to absolute conversion.
#   else
    return (decodeInstructions.x * pow(alpha, decodeInstructions.y)) * data.rgb;
#   endif
}

// Decodes HDR textures
// handles dLDR, RGBM formats
inline half3 DecodeHDR (half4 data, half4 decodeInstructions)
{
    #if defined(UNITY_COLORSPACE_GAMMA)
    return DecodeHDR(data, decodeInstructions, 1);
    #else
    return DecodeHDR(data, decodeInstructions, 0);
    #endif
}
float3 GetReflectDir(float3 worldPos, float3 worldNormal)
{
	Light light = GetMainLight();
	float3 lightDir = normalize(light.direction);
	float3 reflectDir = normalize(reflect((lightDir * -1.0), worldNormal));
	return reflectDir;
}
//-----------------PBR-----------------//
float NDF(float NdotH , float rough){
    float a = rough * rough;
    float a2 = a * a ;
    float NdotH2 = NdotH * NdotH;
    float denom = (NdotH2 * (a2 - 1) + 1);
    denom = denom * denom;
    return a2/denom;
}
float GF(float NdotV,float NdotL,float rough){
    float r = (rough);
    float k = (r*r)/2;
    
    float ggx1 = NdotV /lerp(k,1,NdotV);
    float ggx2 = NdotL /lerp(k,1,NdotL);
    return ggx1 * ggx2 / (4*NdotV*NdotL + 0.001);

    // float r = rough+0.5;
    // return 1/(NdotV*NdotV*r);

    // float r = rough;
    // float k = (r*r)/2;
    
    // float ggx = NdotL*NdotV / ((NdotV*(1-k) + k)*(NdotL*(1-k) + k));
    // return ggx;
}
float3 Fresnel(float NdotV,float3 F0){
    return lerp(F0,1,pow(1 - NdotV , 5));
}
float3 PBR(float3 pos, float3 normal,float3 albedo,float rough,float metal,float ao, float shadow){
    float3 viewDir = normalize(_WorldSpaceCameraPos.xyz-pos.xyz);
    float3 lightDir = normalize(_MainLightPosition.xyz);
    // float3 lightDir = normalize(light.direction);
    float3 halfDir = normalize(viewDir+lightDir);
    
    half NdotL = saturate(dot(normal,lightDir));
    half NdotH = saturate(dot(normal,halfDir));
    half NdotV = saturate(dot(normal,viewDir));
    half LdotH = saturate(dot(lightDir,halfDir));
    half HdotV = saturate(dot(halfDir,viewDir));


    float3 F0 = 0.03;
    F0 = lerp(F0,albedo,metal);
    float D = NDF(NdotH,rough);
    float G = GF(NdotV,NdotL,rough);
    float F = Fresnel(NdotV , F0);
    // D = min(D,10);
    float3 kD = 1- F;
    kD *= 1-metal;
    float3 specular = (D * G * F);
    float Fd90 = 0.5 + 2 * rough * (LdotH*LdotH);
    float Disney = (1+(Fd90-1)*pow(1-NdotL,5))*(1+(Fd90-1)*pow(1-NdotV,5));
    float3 diffuse = albedo * 3.1415926/2;
    float3 finalCol = (diffuse + specular)* (NdotL*0.5+0.5) * _MainLightColor.rgb * shadow;
    //env col
    float3 irradiance = SampleSH(float4(normal,1));
    float3 diffuseEnvCol = irradiance * albedo;
    float4 color_cubemap = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,sampler_MainTex, reflect(-viewDir , normal), 6*rough);
    float3 specularEnvCol = DecodeHDR(color_cubemap,unity_SpecCube0_HDR);
    specularEnvCol *= F;
    float3 envCol = (kD * diffuseEnvCol + specularEnvCol);
    // float3 envCol = (kD * diffuseEnvCol);

    envCol *= ao;
    
    return finalCol;
    // return specular;
    // return float3(F,0,0);
}
float3 PBR_Direct(float3 pos,float3 normal,float3 albedo,float rough,float metal,float ao, float shadow){
    float3 viewDir = GetWorldSpaceViewDir(pos);
    float3 lightDir = _MainLightPosition.xyz;
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
    float3 diffuse = kD * albedo /3.141592654;
    float3 finalCol = (diffuse + specular) * _MainLightColor * shadow;
    return finalCol;
}
#endif
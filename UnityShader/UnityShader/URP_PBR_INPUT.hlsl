#ifndef CUSTOM_PBR_INPUT_INCLUDED
#define CUSTOM_PBR_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

TEXTURE2D(_MainTex);
SAMPLER(sampler_MainTex);


TEXTURE2D(_RoughnessTex);
SAMPLER(sampler_RoughnessTex);
TEXTURE2D(_MetalTex);
SAMPLER(sampler_MetalTex);
TEXTURE2D(_AOTex);
SAMPLER(sampler_AOTex);
TEXTURE2D(_NormalTex);
SAMPLER(sampler_NormalTex);



CBUFFER_START(UnityPerMaterial)
    float _Roughness;
    float _Metal;
    float _AO;
    float _Normal;
	//
	float4 _MainTex_ST;
    float _F0;

    
CBUFFER_END
//-----------------test-----------------//
//GetNormal
//GetWorldSpaceViewDir
//GetWorldSpaceNormalDir
//GetWorldSpaceLightDir


//-----------------universal-----------------//




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
    // return lerp(F0,1,pow(1 - NdotV , 5));
    // return F0 + (1-F0)*pow(1 - NdotV, 5);
    return F0 + (1-F0)*pow(2, (-5.55473*NdotV - 6.98316)*NdotV);
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


    float3 F0 = _F0;
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
    float3 diffuse = albedo;
    float3 finalCol = (diffuse + specular)* NdotL * _MainLightColor.rgb * shadow;
    //env col
    float3 irradiance = SampleSH(float4(normal,1));
    float3 diffuseEnvCol = irradiance * albedo;
    float4 color_cubemap = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0,sampler_MainTex, reflect(-viewDir , normal), 6*rough);
    float3 specularEnvCol = DecodeHDR(color_cubemap,unity_SpecCube0_HDR);
    specularEnvCol *= F;
    float3 envCol = (kD * diffuseEnvCol + specularEnvCol);
    // float3 envCol = (kD * diffuseEnvCol);

    envCol *= ao;
    
    return finalCol+envCol;
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
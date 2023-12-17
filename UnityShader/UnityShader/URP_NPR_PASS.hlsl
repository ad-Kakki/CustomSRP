#ifndef CUSTOM_NPR_PASS_INCLUDED
#define CUSTOM_NPR_PASS_INCLUDED
//
struct appdata
{
    float4 vertex : POSITION;
    float2 uv0 : TEXCOORD;
    float4 uv7 : TEXCOORD7; //平滑法线
    float3 normal : NORMAL;
    float4 tangent : TANGENT;  
};
struct v2f
{
    float2 uv0 : TEXCOORD0;
    float4 vertex : SV_POSITION;
    float3 posWS : TEXCOORD2;
    float3 nDirWS : TEXCOORD3;
    float3 lDirWS : TEXCOORD4;
    float4 tDirWS: TEXCOORD5;
    float4 screenPos : TEXCOORD6;
    float4 shadowCoord : TEXCOORD8;

};


v2f vert (appdata v)
{
    v2f o;
    o.vertex = TransformObjectToHClip(v.vertex.xyz);
    // o.posWS = mul((float4x4)UNITY_MATRIX_V, v.vertex);
    o.posWS = TransformObjectToWorld(v.vertex.xyz);
    
    o.uv0 = TRANSFORM_TEX(v.uv0, _MainTex);
    o.nDirWS = TransformObjectToWorldNormal(v.normal);
    o.screenPos = ComputeScreenPos(o.vertex);
    o.lDirWS = (_MainLightPosition.xyz);
    o.tDirWS = float4(TransformObjectToWorld(v.tangent.xyz),v.tangent.w);
    // float3 posws = TransformObjectToWorld(v.vertex.xyz);
    o.shadowCoord = TransformWorldToShadowCoord(o.posWS);
    return o;
}
float4 frag (v2f i) : SV_Target
{
    // i.shadowCoord = ComputeScreenPos(i.vertex);
    i.shadowCoord = TransformWorldToShadowCoord(i.posWS);
    Light mainLight = GetMainLight(i.shadowCoord);
    // float shadow = MainLightRealtimeShadow(i.shadowCoord); 
    float shadow = mainLight.shadowAttenuation*mainLight.distanceAttenuation;
    float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz-i.posWS.xyz);
    float3 nDirWS = normalize(i.nDirWS);
    float3 lDirWS = normalize(i.lDirWS);
    float3 hDirWS = normalize(vDirWS + lDirWS);
    float3 tDirWS = normalize(i.tDirWS.xyz);
    float3 bDirWS = normalize(cross(nDirWS, tDirWS));
    float NdotL = (dot(nDirWS, lDirWS));
    float NdotH = (dot(nDirWS, hDirWS));
    float NdotV = (dot(nDirWS, vDirWS))*0.5+0.5;
    float halfLambert = NdotL * 0.5 + 0.5;
    float3x3 tbn = float3x3(tDirWS, bDirWS, nDirWS);

    float4 mianTex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv0);
    float3 color = mianTex.rgb;
    float skinMask = SAMPLE_TEXTURE2D(_SkinMask, sampler_SkinMask, i.uv0).x;

    // #if defined(_EMISSION)
    // float emissionMask = SAMPLE_TEXTURE2D(_EmissionMask, sampler_EmissionMask, i.uv0).x;
    // float3 emission = GetEmission(color,emissionMask);

    // #endif

    float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
    //RampMap
    float3 rampTex = GetRampShaodw(NdotL);
    // float rampLerp = step(_RampShadowRange, max(0,NdotL)*0.5+0.5);
    color = lerp(rampTex * color, color, rampTex);  



    #if defined(_ONLY_SHADOW)
        return float4(rampTex, 1);
    #endif
    //DepthRim
    float depthRim = GetDepthRim(i.vertex, i.nDirWS)*(NdotL*0.5+0.5);
    #if defined(_ONLY_RIM)
        return depthRim;
	#endif
    color = lerp(color, color + 0.1*_RimLightColor, depthRim);
    
    #if defined(_NPRandPBR)
    float rough = (1-SAMPLE_TEXTURE2D(_RoughnessTex, sampler_RoughnessTex, i.uv0)) * _Roughness;
    float metal = SAMPLE_TEXTURE2D(_MetalTex, sampler_MetalTex, i.uv0) * _Metal;
    float ao = SAMPLE_TEXTURE2D(_AOTex, sampler_AOTex, i.uv0) * _AO;
    
    float3 normalMap = UnpackNormal(SAMPLE_TEXTURE2D(_NormalDisTex, sampler_NormalDisTex, i.uv0));
    float3 normalDis = mul(normalMap, tbn) * _NormalDis;
    float3 pbrColor = PBR(i.posWS, normalDis, color, rough, metal,1,1);
    color = lerp(color, pbrColor, 1-skinMask);
    return float4(color,1);

    #endif

    #if defined(_METAL)
    float metaln = GetMetal(nDirWS);
    // return float4(metal,0,0,1);
    color += metaln*0.3;
    #endif


    #if defined(_FACE)
        color = mianTex.rgb;
        float faceShadow = GetFaceShadow(i.uv0, lDirWS);
        color = lerp(rampTex * color, color, faceShadow*0.5+0.5);
        // return float4(faceShadow,0,0,1);
    #endif



    #if defined(_HAIR)
    float hairMask = SAMPLE_TEXTURE2D(_HairMask, sampler_HairMask, i.uv0).x;
    float3 anisoHair = AnisoHair(i.uv0, nDirWS, vDirWS, lDirWS, NdotL, bDirWS, hairMask) * _AnisoScale;
    color += anisoHair*(max(NdotL,0)*0.5+0.5);
    // return float4(anisoHair*hairMask, 1);
    #endif
    
    //Silk
    #if defined(_SILK)
		//面比率范围调节 获得中心颜色渐变
		float Ramp_Centre  = pow(NdotV,_SkilCentreRange);
		//面比率着色
		float3 col = lerp(color,_SkilCentre.xyz*(NdotL*0.5+1),abs(Ramp_Centre));
        color = lerp(color, col, (0.9-skinMask));
        // return float4(anisoHair, 1); //*(0.9-skinMask)
    #endif

    // color *= mainLight.shadowAttenuation;

    // return float4(mainLight.shadowAttenuation*mainLight.distanceAttenuation,0,0,1);
    return float4(color, 1);
}

//OutLine






#endif
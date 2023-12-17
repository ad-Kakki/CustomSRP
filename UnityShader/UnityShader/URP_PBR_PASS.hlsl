#ifndef CUSTOM_PBR_PASS_INCLUDED
#define CUSTOM_PBR_PASS_INCLUDED
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

    float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;
    float3 color = mianTex.rgb+ambient;



    float rough =(1- SAMPLE_TEXTURE2D(_RoughnessTex, sampler_RoughnessTex, i.uv0)) * _Roughness;
    float metal = SAMPLE_TEXTURE2D(_MetalTex, sampler_MetalTex, i.uv0) * _Metal;
    float ao = SAMPLE_TEXTURE2D(_AOTex, sampler_AOTex, i.uv0) * _AO;
    
    float3 normalMap = UnpackNormal(SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv0));
    float3 normal = (mul(normalMap, tbn) * _Normal);
    // float3 normal = SAMPLE_TEXTURE2D(_NormalTex, sampler_NormalTex, i.uv0);
    float3 pbrColor = PBR(i.posWS, normal, color, rough, metal,1,shadow);
    return float4(pbrColor,1);

}

//OutLine






#endif
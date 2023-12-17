// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
Shader "Custom/tess_fft_ocean"
{
    Properties
    {

        _BubblesColor ("Bubbles Color", Color) = (1, 1, 1, 1)
        _Displace ("Displace", 2D) = "white" { }
        _Normal ("Normal", 2D) = "white" { }
        _Bubbles ("Bubbles", 2D) = "white" { }
        _Roughness("_Roughness", Range(0,1)) = 1
        _Metal("_Metal", Range(0,1)) = 1
        _F0("_F0", Range(0,1)) = 0.2
        _SSSColor ("SSSColor", Color) = (1, 1, 1, 1)
        _SSSAttenuation("SSSAttenuation",Range(1,50)) = 1
        _SSSscale ("SSSscale", Range(0,5)) = 1

        _GrabBlurTexture ("GrabBlurTexture", 2D) = "white" { }

        _MinDist("MinDist",Range(1,5000)) = 1
        _MaxDist("MaxDist",Range(2000,50000)) = 5000   
        _TessellationUniform("TessellationUniform",Range(1,200)) = 1
        _DepthLUTTex("DepthLUTTex", 2D) = "white" { }
        _DepthMaxDistance("_DepthMaxDistance",Range(1,1000)) = 1
        _FoamNoiseTex("FoamNoiseTex", 2D) = "white" { }
        _FoamNoiseDis("FoamNoiseDis",Range(0,100)) = 1
        _Transparent("FoamNoiseDis",Range(0,100)) = 1

    }
    SubShader
    {        
        Tags { "RenderType" = "Opaque" "LightMode" = "ForwardBase" }
        LOD 100
        Pass
        {
            Zwrite On
            //  ZTest Less
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha
            CGPROGRAM
            // #pragma enable_d3d11_debug_symbols
            #pragma vertex tessvert
            #pragma fragment frag
            #pragma hull hs
            #pragma domain ds
            #pragma shader_feature _FOG_OFF _FOG_ON
            #pragma target 5.0
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            #include "HLSLSupport.cginc"
            #include "FogHeader.cginc"
            #include "Tessellation.cginc"

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;

            };
            
            struct v2f
            {
                float4 pos: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 worldPos: TEXCOORD1;
                float4 scrPos : TEXCOORD2;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                // LIGHTING_COORDS(5,6)                

            };
            fixed _F0;
            fixed4 _BubblesColor;
            fixed4 _Specular;
            fixed _Gloss;
            sampler2D _Displace;
            sampler2D _Normal;
            sampler2D _Bubbles;
            float4 _Displace_ST;
		    sampler2D _GrabBlurTexture;
            sampler2D _BlurTexture;

            //追加sss
            fixed _SSSscale;
            fixed4 _SSSColor;
            fixed _Distortion;

            float _Roughness,_Metal;
            float _MinDist;
            float _MaxDist;
            sampler2D _DepthLUTTex;
            sampler2D _CameraDepthTexture;
            float _DepthMaxDistance;

            float _SSSAttenuation;
            float _Thickness;
            sampler2D _FoamNoiseTex;
            float _FoamNoiseDis;
            float _Transparent;

float NDF(float NdotH , float rough){
    float a = rough * rough;
    float a2 = a * a ;
    float NdotH2 = NdotH * NdotH;
    float denom = (NdotH2 * (a2 - 1) + 1);
    denom = denom * denom;
    return a2/denom;
}
float GF(float NdotV,float NdotL,float rough){
    float r = (rough+1);
    float k = (r*r)/8;
    
    float ggx1 = NdotV /lerp(k,1,NdotV);
    float ggx2 = NdotL /lerp(k,1,NdotL);
    return ggx1 * ggx2 / (4*NdotV*NdotL + 0.00001);

    // float r = rough+0.5;
    // return 1/(NdotV*NdotV*r);

    // float r = rough;
    // float k = (r*r)/2;
    
    // float ggx = NdotL*NdotV / ((NdotV*(1-k) + k)*(NdotL*(1-k) + k));
    // return ggx;
}
float3 Fresnel(float NdotV,float3 F0){
    return lerp(F0,1,pow(1 - NdotV , 5));

    // return F0 + (1-F0)*pow(1 - NdotV, 5);
    // return F0 + (1-F0)*pow(2, (-5.55473*NdotV - 6.98316)*NdotV);
}
            float3 PBR(float3 pos,float3 normal,float3 albedo,float rough,float metal,float ao, float shadow){
                // float3 viewDir = normalize(_WorldSpaceCameraPos - pos);
                float3 viewDir = normalize(UnityWorldSpaceViewDir(pos));

                float3 lightDir = normalize(UnityWorldSpaceLightDir(pos));
    float3 halfDir = normalize(viewDir+lightDir);
    half NdotL = saturate(dot(normal,lightDir));
    half NdotH = saturate(dot(normal,halfDir));
    half NdotV = saturate(dot(normal,viewDir));
    half LdotH = saturate(dot(lightDir,halfDir));
    half HdotV = saturate(dot(halfDir,viewDir));
                float3 F0 = _F0;
                // F0 = lerp(F0,albedo,metal);
                float D = NDF(NdotH,rough);
                float G = GF(NdotV,NdotL,rough);
                float F = Fresnel(NdotV , F0);
                // D = min(D,10);
                float3 kD = F;
                // kD *= 1-metal;
                float3 specular = (D * G * F);
                float Fd90 = 0.5 + 2 * rough * (LdotH*LdotH);
                float Disney = (1+(Fd90-1)*pow(1-NdotV,5));
                float3 diffuse =  kD*albedo ;
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
                // return kD;
                // return float3(F,F,F);
                // return float3(NdotL,0,0);
            }

            float3 SSSColor(float3 col, float3 lightDir, float3 viewDir, float3 normal,float waveHeight)
            {
                float v = abs(viewDir.y-0.5);
                float towardsSun = pow(max(0, dot(lightDir, -viewDir)), _SSSscale);
                float3 subSurface = (col + _SSSAttenuation * towardsSun) * _SSSColor * _LightColor0;
                subSurface *= ( 1-pow(v,3)) * waveHeight;
                return col + subSurface;
                // return subSurface;
                // return float3(towardsSun,0,0);

                // float3 h = normalize(lightDir + normal*_FoamNoiseDis);
                // float VdotH = saturate(dot(-h, viewDir));
                // subSurface += pow(VdotH, 3)*_SSSscale;
                // return col + subSurface;





            }

            struct InternalTessInterp_appdata {
                float4 vertex : INTERNALTESSPOS;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 texcoord : TEXCOORD0;
            };
               
            InternalTessInterp_appdata tessvert (appdata v) {
                InternalTessInterp_appdata o;
                o.vertex = v.vertex;
                o.tangent = v.tangent;
                o.texcoord = TRANSFORM_TEX(v.uv, _Displace);
                o.normal = tex2Dlod(_Normal, float4(o.texcoord, 0, 0)).rgb;
                return o;
            }
            
            v2f vert(appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _Displace);
                float4 displcae = tex2Dlod(_Displace, float4(o.uv, 0, 0));
                v.vertex += float4(displcae.xyz, 0);
                o.pos = UnityObjectToClipPos(v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = v.normal;

                o.scrPos = ComputeScreenPos(o.pos);
                // COMPUTE_EYEDEPTH(o.scrPos.z);
                return o;
            }

            float UnityCalcDistanceTessFactor1 (float4 vertex, float minDist, float maxDist, float tess)
            {
                float3 wpos = mul(unity_ObjectToWorld,vertex).xyz;
                float dist = distance (wpos, _WorldSpaceCameraPos);
                // float f = clamp(1 - (dist - minDist) / (maxDist - minDist), 0.001, 1) * tess;
                float f = clamp(exp(- (dist*10 - minDist) / (maxDist - minDist)), 0.01, 1) * tess;
                return f;
            }
            float _TessellationUniform;
            UnityTessellationFactors hsconst (InputPatch<InternalTessInterp_appdata,3> v) {
                UnityTessellationFactors o;
                o.edge[0] = UnityCalcDistanceTessFactor1 (v[0].vertex,_MinDist, _MaxDist,_TessellationUniform);
                o.edge[1] = UnityCalcDistanceTessFactor1 ( v[1].vertex,_MinDist, _MaxDist,_TessellationUniform);
                o.edge[2] = UnityCalcDistanceTessFactor1 (v[2].vertex,_MinDist, _MaxDist,_TessellationUniform);
                o.inside = UnityCalcDistanceTessFactor1 ((v[0].vertex+v[1].vertex+v[2].vertex)/3,_MinDist, _MaxDist,_TessellationUniform);
                // o.edge[0] = _TessellationUniform;
                // o.edge[1] = _TessellationUniform;
                // o.edge[2] = _TessellationUniform;
                // o.inside = _TessellationUniform;
                
                return o;
            }
 
            [UNITY_domain("tri")]// "tri", "quad", or "isoline",
            [UNITY_partitioning("fractional_odd")]//"integer", "pow2", "fractional_even", or "fractional_odd"
            [UNITY_outputtopology("triangle_cw")]//"point", "line", "triangle_cw", or "triangle_ccw"
            [UNITY_patchconstantfunc("hsconst")]
            [UNITY_outputcontrolpoints(3)]
            InternalTessInterp_appdata hs (InputPatch<InternalTessInterp_appdata,3> v, uint id : SV_OutputControlPointID) {
                return v[id];
            }
            
            [UNITY_domain("tri")]
            v2f ds (UnityTessellationFactors tessFactors, const OutputPatch<InternalTessInterp_appdata,3> vi, float3 bary : SV_DomainLocation) {
                appdata v = (appdata)0;
            
                v.vertex = vi[0].vertex*bary.x + vi[1].vertex*bary.y + vi[2].vertex*bary.z;
                v.tangent = vi[0].tangent*bary.x + vi[1].tangent*bary.y + vi[2].tangent*bary.z;
                v.normal = vi[0].normal*bary.x + vi[1].normal*bary.y + vi[2].normal*bary.z;
                v.uv = vi[0].texcoord*bary.x + vi[1].texcoord*bary.y + vi[2].texcoord*bary.z;
            
                v2f o = vert (v);
                return o;
            }

            fixed4 frag(v2f i): SV_Target
            {
                fixed noise = tex2D(_FoamNoiseTex, i.uv+_Time*0.01).r;
                fixed3 normal =normalize(UnityObjectToWorldNormal
                                            (tex2D(_Normal, i.uv).rgb+noise*_FoamNoiseDis));
  
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                // float atten = LIGHT_ATTENUATION(i);

                //depth LUT
                // float sceneZ = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.scrPos)));
                // float z =  LinearEyeDepth(tex2D(_CameraDepthTexture,i.uv));
                float sceneZ = LinearEyeDepth(tex2D(_CameraDepthTexture, i.scrPos.xy/i.scrPos.w));
                float diff = (sceneZ - i.scrPos.w);
                // if( diff > 0.7)
                    // diff = 20;                 
                float diffMax = diff/_DepthMaxDistance;
                float3 depthLUTCol = tex2D(_DepthLUTTex, float2(diffMax, 0.1));
   
                //SSS次表面散射
                float displcae = tex2D(_Displace, i.uv).y/40;
                float3 sssColor = SSSColor(depthLUTCol, lightDir, viewDir, normal, displcae)*_LightColor0*depthLUTCol;
                float3 pbrColor = PBR(i.worldPos, normal, sssColor, 1-_Roughness, _Metal, 1, 1);
                    // return float4(pbrColor,1);

                float bubbles = tex2D(_Bubbles, i.uv).r;
                float3 diffuse =pbrColor+ _BubblesColor.rbg*bubbles;                 
                //foam edge
                // float3 EdgeFoamCol = tex2D(_FoamNoiseTex, i.uv+_Time*0.01).rgb*saturate(1-diffFoam);

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                // #ifdef _FOG_ON
                //     col.xyz = ExponentialHeightFog(col.xyz, i.worldPos);
                // #endif

                return fixed4(diffuse,1);
            }
            ENDCG
        }
        // UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
Shader "Unlit/URP_NPR_SHADER"
{
    Properties
    {
        [Header(Texture)]
        _MainTex ("Texture", 2D) = "white" {}
        _RampMap("RampMap", 2D) = "white" {}
        _SkinMask("SkinMask", 2D) = "white" {}
        _HairMask("HairMask", 2D) = "white" {}
        _EmissionMask("EmissionMask", 2D) = "white" {}
        _SdfFaceMap("_SdfFaceMap", 2D) = "white" {}
        [Space][Header(__________ Roughness __________)][Space]
        _RoughnessTex ("_RoughnessTex", 2D) = "white" {}
        _Roughness ("_Roughness", Range(0,1)) = 0     
       
        [Space][Header(__________ Metallic __________)][Space]
        _MetalTex ("_MetalTex", 2D) = "white" {}
        _Metal ("_Metal", Range(0,1)) = 0
        [Space][Header(__________ AO __________)][Space]
        _AOTex ("_AOTex", 2D) = "white" {}
        _AO ("_AO", Range(0,1)) = 0    
        [Space][Header(__________ NormalDisTex __________)][Space]
        _NormalDisTex ("_NormalDisTex", 2D) = "white" {}
        _NormalDis ("_NormalDis", Range(0,1)) = 0    


        [Header(PRM)]
        [Toggle(_NPRandPBR)] _NPRandPBR ("_NPRandPBR", Float) = 0
        [Header(Test)]
        [Toggle(_ONLY_RIM)] _OnlyRim ("OnlyRim", Float) = 0
        [Toggle(_ONLY_SPACE)] _OnlySpace ("OnlySpace", Float) = 0
        [Toggle(_ONLY_AO)] _OnlyAO ("OnlyAO", Float) = 0
        [Toggle(_ONLY_SKIN)] _OnlySkin ("OnlySkin", Float) = 0
        [Toggle(_ONLY_SHADOW)] _OnlyShadow ("OnlyShadow", Float) = 0
        
        [Toggle(_HAIR)] _Hair ("Hair", Float) = 0
        [Toggle(_FACE)] _Face ("Face", Float) = 0
        [Toggle(_BODY)] _Body ("Body", Float) = 0
        [Toggle(_CLOTH)] _Cloth ("Cloth", Float) = 0
        [Toggle(_SILK)] _Silk ("Silk", Float) = 0
        [Toggle(_METAL)] _METAL ("Metal", Float) = 0
        [Header(__________ OtherTest __________)]
        [IntRange] _Ref("Ref", Range(0, 16)) = 0
        [IntRange] _Comp("Comp", Range(1, 8)) = 8
        [IntRange] _Pass("Pass", Range(0, 7)) = 0
        
        
        [Header(__________ PBR __________)]


        [Header(__________ NPR __________)]
[Space][Header(RampShaodw)][Space]
        _RampMapXRange("RampMapXRange", Range(0, 1)) = 0.05
        _RampMapYRange("RampMapYRange", Range(0, 1)) = 0.05
        _RampShadowRange ("RampShadowRange", Range(0.004, 2)) = 1
[Space][Header(SdfFace)][Space]
        _LightSmooth("LightSmooth", Range(0, 2)) = 1

[Space][Header(RimLight)][Space]
        _RimLightColor("RimLightColor", Color) = (1,1,1,1)
        _RimThreshold("RimThreshold", Range(0, 5)) = 0.1
        _RimOffect("RimOffect", Range(0, 0.02)) = 0.001

[Space][Header(Skil)][Space]
       	_SkilCentre("Centre",Color)=(1,0,0,1)
		_SkilEdge("Edge",Color)=(0,0,1,1)
		_SkilCentreRange("Range", Range(1,100))=1
[Space][Header(Anisotropic)][Space]
        _SPColor1("SPColor1", Color) = (1, 1, 1, 1)
        _SPColor2("SPColor2", Color) = (1, 1, 1, 1)
        _spaceExp("spaceExp", Vector) = (0, 0, 0, 0)
        _AnisoScale("AnisoScale", Range(0, 1)) = 0.5
        [Header(__________ UNIVERSAL __________)]
[Space][Header(Emission)][Space]
        _EmissionIntensity("RimThreshold", Range(0, 5)) = 0.1




    }
    SubShader
    {
        Tags {  
            "RenderPipeline"="UniversalPipeline"//声明这是一个URP Shader！
             }
        
		HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
		#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderVariablesFunctions.hlsl"
        #include "URP_NPR_INPUT.hlsl"
        ENDHLSL

        Pass
        {
            Cull Off
            Tags{
                "LightMode" = "UniversalForward"
                "RenderType"="Opaque"
                "Queue"="Opaque"
  
                }
            Stencil
            {
                Ref [_Ref]
                Comp [_Comp]
                //Never1 Less2 Equal3 LEqual4 Greater5 NotEqual6 GEqual7 Always8
                Pass [_Pass]
                //Keep0 Zero1 Replace2 IncrSat3 DecrSat4 Invert5 IncrWrap6 DecrWrap7
                Fail Keep
                ZFail Keep
            }
            HLSLPROGRAM
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            // #pragma multi_compile _ MAIN_LIGHT_CALCULATE_SHADOWS
            // // #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS 
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE 
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma shader_feature _ _NPRandPBR
            #pragma shader_feature _ _ONLY_RIM
            #pragma shader_feature _ _ONLY_SPACE
            #pragma shader_feature _ _ONLY_AO
            #pragma shader_feature _ _ONLY_SKIN
            #pragma shader_feature _ _ONLY_SHADOW

            #pragma shader_feature _ _HAIR
            #pragma shader_feature _ _FACE
            #pragma shader_feature _ _BODY
            #pragma shader_feature _ _CLOTH
            #pragma shader_feature _ _SILK
            #pragma shader_feature _ _EMISSION
            #pragma shader_feature _ _METAL

            #pragma vertex vert
            #pragma fragment frag

            #include "URP_NPR_PASS.hlsl"
            
            ENDHLSL
        }
//         Pass // jave.lin : 有 ApplyShadowBias
//         {
    
//             Cull Off
//             Name "ShadowCaster"
//             Tags{
    
//      "LightMode" = "ShadowCaster" }
//             HLSLPROGRAM
//             #pragma vertex vert
//             #pragma fragment frag
//             struct a2v {
    
    
//                 float4 vertex : POSITION;
//                 float2 uv : TEXCOORD0;
//                 float3 normal : NORMAL;
//             };
//             struct v2f {
    
    
//                 float4 vertex : SV_POSITION;
//                 float2 uv : TEXCOORD0;
//                 float3 worldPos : TEXCOORD1;
//             };
//             // 以下三个 uniform 在 URP shadows.hlsl 相关代码中可以看到没有放到 CBuffer 块中，所以我们只要在 定义为不同的 uniform 即可
//             float3 _LightDirection;
//             // float4 _ShadowBias; // x: depth bias, y: normal bias
//             // half4 _MainLightShadowParams;  // (x: shadowStrength, y: 1.0 if soft shadows, 0.0 otherwise)
//             // jave.lin 直接将：Shadows.hlsl 中的 ApplyShadowBias copy 过来
//             // float3 ApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection)
//             // {
    
    
//             //     float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
//             //     float scale = invNdotL * _ShadowBias.y;
//             //     // normal bias is negative since we want to apply an inset normal offset
//             //     positionWS = lightDirection * _ShadowBias.xxx + positionWS;
//             //     positionWS = normalWS * scale.xxx + positionWS;
//             //     return positionWS;
//             // }
//             v2f vert(a2v v)
//             {
    
    
//                 v2f o = (v2f)0;
//                 o.worldPos = TransformObjectToWorld(v.vertex.xyz);
//                 float3 normalWS = TransformObjectToWorldNormal(v.normal);
//                 worldPos = ApplyShadowBias(worldPos, normalWS, _LightDirection);
//                 o.vertex = TransformWorldToHClip(worldPos);
//                 o.uv = TRANSFORM_TEX(v.uv, _MainTex);
//                 return o;
//             }
//             real4 frag(v2f i) : SV_Target
//             {
    
    
// #if _ALPHATEST_ON
//                 half4 col = tex2D(_MainTex, i.uv);
//                 clip(col.a - 0.001);
// #endif
//                 return 0;
//             }
//             ENDHLSL
//         }

UsePass "Universal Render Pipeline/Lit/ShadowCaster"


        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }
    }
}

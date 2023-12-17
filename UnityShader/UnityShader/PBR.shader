Shader "PBR"
{
    Properties
    {
        [Header(Texture)]
        _MainTex ("Texture", 2D) = "white" {}    
        _F0 ("_F0", Range(0,2)) = 0.2    
        [Header(__________ PBR __________)]
        [Space][Header(__________ Roughness __________)][Space]
        _RoughnessTex ("_RoughnessTex", 2D) = "white" {}
        _Roughness ("_Roughness", Range(0,2)) = 1     
       
        [Space][Header(__________ Metallic __________)][Space]
        _MetalTex ("_MetalTex", 2D) = "white" {}
        _Metal ("_Metal", Range(0,2)) = 1
        [Space][Header(__________ AO __________)][Space]
        _AOTex ("_AOTex", 2D) = "white" {}
        _AO ("_AO", Range(0,2)) = 0    
        [Space][Header(__________ NormalTex __________)][Space]
        _NormalTex ("_NormalTex", 2D) = "white" {}
        _Normal ("_Normal", Range(0,2)) = 1   

        [Space][Header(__________ HeightTex __________)][Space]
        _HeightTex ("_HeightTex", 2D) = "white" {}
        _Height ("_Height", Range(0,2)) = 1   




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
        #include "URP_PBR_INPUT.hlsl"
        ENDHLSL

        Pass
        {
            // Cull Off
            Tags{
                "LightMode" = "UniversalForward"
                "RenderType"="Opaque"
                "Queue"="Opaque"
                }

            HLSLPROGRAM
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            // #pragma multi_compile _ MAIN_LIGHT_CALCULATE_SHADOWS
            // // #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS 
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE 
            #pragma multi_compile _ _SHADOWS_SOFT

            #pragma vertex vert
            #pragma fragment frag

            #include "URP_PBR_PASS.hlsl"
            
            ENDHLSL
        }
        UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    }
}
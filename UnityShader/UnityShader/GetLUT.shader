Shader "GetLUT"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _CosTheta ("CosTheta", Range(-1,1)) = 0
        _d ("d", Range(0,20)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        CGINCLUDE
        #include "UnityCG.cginc"
        float _CosTheta,_d;
        float Gaussianf(float v, float r)  
        {   // v is variance , r is radius
            // return 1.0f/sqrt(2*3.14159*v)*exp((-r*r)/(2*v));  
            return 1.0f/(2*3.14159*v)*exp((-r*r)/(2*v));  
            //Nakagami-m分布
            //瑞丽(Rayleigh)分布
            // return r/(v*v)*exp((-r*r)/(2*v*v));
        
        }  
        float3 Scatter(float r)  
        {  
            return Gaussianf(0.0064,r)*float3(0.233,0.455,0.649)+  
                    Gaussianf(0.0484,r)*float3(0.1,0.366,0.344)+  
                    Gaussianf(0.187,r)*float3(0.118,0.198,0.0)+  
                    Gaussianf(0.567,r)*float3(0.113,0.007,0.007)+  
                    Gaussianf(1.99,r)*float3(0.358,0.004,0.0)+  
                    Gaussianf(7.41,r)*float3(0.078,0.0,0.0);  
            // return (exp(-r/_d)+exp(-r/3/_d))/(8*3.14159*_d*r);

        }  
        float3 integrateDiffuseScatteringOnRing(float CosTheta,float Radius)  
        {  
            //theta is NdotL , Radius is 1/r
            float theta = acos(CosTheta);  
            float3 totalWeight = 0;  
            float3 totalLight = 0;
            float x =-(UNITY_PI/2);  
            float inc = (UNITY_PI/2)/1000;  
            while (x<=(UNITY_PI/2))  
            {  
                float sampleAngle = theta+x;  
                float Diffuse = saturate(cos(sampleAngle));  
                float sampleDis = abs(2*Radius*sin(x*0.5));  
                float3 weight = Scatter(sampleDis);  
                totalWeight += weight;  
                totalLight += Diffuse*weight;  
                x+=inc;  
            }  
            return totalLight/totalWeight;  
        }  
        ENDCG


        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work


            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag (v2f i) : SV_Target
            {
                
                float3 col = integrateDiffuseScatteringOnRing(i.uv.x*2-1,1-i.uv.y);
                // col = pow(col, 2.2);

                return float4(col,1);
            }
            ENDCG
        }
    }
}

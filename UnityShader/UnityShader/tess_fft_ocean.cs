using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Rendering;
using System.IO;

public class tess_fft_ocean : MonoBehaviour
{
    public int MeshSize = 250;		//网格长宽数量
    public float MeshLength = 10;	//网格长度
    private int[] vertIndexs;		//网格三角形索引
    private Vector3[] positions;    //位置
    private Vector2[] uvs; 			//uv坐标
    private Mesh mesh;
    private MeshFilter filetr;
    private MeshRenderer render;

    public Material OceanMaterial;  //渲染海洋的材质
    public Material DisplaceXMat;   //x偏移材质
    public Material DisplaceYMat;   //y偏移材质
    public Material DisplaceZMat;   //z偏移材质
    public Material DisplaceMat;    //偏移材质
    public Material NormalMat;      //法线材质
    public Material BubblesMat;     //泡沫材质
    public Material DepthMatrix;
    public int FFTPow = 9;         //生成海洋纹理大小 2的次幂，例 为10时，纹理大小为1024*1024
    public int rtSize = 512;

    public float WindScale = 2;     //风强
    public float TimeScale = 1;     //时间影响
    public float A = 1;
    public float Lambda = -1;       //用来控制偏移大小
    public float HeightScale = 1;   //高度影响
    public float BubblesScale = 1;  //泡沫强度
    public float BubblesThreshold = 1;//泡沫阈值
    public float pre = 0;
    public Vector4 WindAndSeed = new Vector4(0.1f, 0.2f, 0, 0);//风向和随机种子 xy为风, zw为两个随机种子

    public bool isControlH = true;  //是否控制横向FFT，否则控制纵向FFT
    public int ControlM = 12;       //控制m,控制FFT变换阶段

    public RawImage img1;
    public RawImage img2;
    public RawImage img3;
    public RawImage img4;
    public RawImage img5;
    public RawImage img6;
    public RawImage img7;
    public RawImage img8;
    public RawImage img9;
    public RawImage img10;
    public RawImage img11;
    public RawImage img12;


    private int kernelGaussianRandom;                       //计算高斯随机数
    private int kernelCreateHeightSpectrum;                 //创建高度频谱
    private int kernelGetDisplaceSpectrum;                  //创建偏移频谱
    private int kernelFFTHorizontal;                        //FFT横向
    private int kernelFFTHorizontalEnd;                     //FFT横向，最后阶段
    private int kernelFFTVertical;                          //FFT纵向
    private int kernelFFTVerticalEnd;                       //FFT纵向,最后阶段
    private int kernelTextureGenerationDisplace;            //生成偏移纹理
    private int kernelTextureGenerationNormalBubbles;       //生成法线和泡沫纹理
    private int kernelScreenSpaceReflection;
    private int kernelPreDisTextureGenerationTexture;


    public ComputeShader OceanCS;
    private RenderTexture GaussianRandomRT;                 //高斯随机数
    private RenderTexture HeightSpectrumRT;                 //高度频谱
    private RenderTexture DisplaceXSpectrumRT;              //X偏移频谱
    private RenderTexture DisplaceZSpectrumRT;              //Z偏移频谱
    private RenderTexture DisplaceRT;                       //偏移频谱
    private RenderTexture OutputRT;                         //临时储存输出纹理
    private RenderTexture NormalRT;                         //法线纹理
    private RenderTexture BubblesRT;                        //泡沫纹理
    private RenderTexture BlurRT;                           //bulrRT
    private RenderTexture PreDisRT;
    private RenderTexture DepthRT;

    private float time = 0;  
    private bool tlock = true;
    //水波部分（新）
    public GameObject obj;
    private RenderTexture WaveTexture;

    public float WaveHeight = 0.999f;
    private Vector4 m_waveTransmitParams;
    private Vector4 m_waveMarkParams;
    public float WaterPlaneWidth;
    public float WaterPlaneLength;
    public float WaveRadius = 1.0f;
    public float WaveSpeed = 1.0f;
    public float WaveViscosity = 1.0f; //粘度
    public float WaveAtten = 0.99f; //衰减
    private void Awake()
    {
        //添加网格及渲染组件
        filetr = gameObject.GetComponent<MeshFilter>();
        if (filetr == null)
        {
            filetr = gameObject.AddComponent<MeshFilter>();
        }
        render = gameObject.GetComponent<MeshRenderer>();
        if (render == null)
        {
            render = gameObject.AddComponent<MeshRenderer>();
        }
        mesh = new Mesh();
        filetr.mesh = mesh;
        render.material = OceanMaterial;
    }    
    void Start()
    {
        //创建网格
        CreateMesh();
        //初始化ComputerShader相关数据
        InitializeCSvalue();
    }



 public bool SaveRenderTextureToPNG(RenderTexture rt, string contents, string pngName)
    {
        RenderTexture prev = RenderTexture.active;
        RenderTexture.active = rt;
        Texture2D png = new Texture2D(rt.width, rt.height, TextureFormat.ARGB32, false);
        png.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0);
        byte[] bytes = png.EncodeToPNG();
        if (!Directory.Exists(contents))
            Directory.CreateDirectory(contents);
        FileStream file = File.Open(contents + "/" + pngName + ".png", FileMode.Create);
        BinaryWriter writer = new BinaryWriter(file);
        writer.Write(bytes);
        file.Close();
        Texture2D.DestroyImmediate(png);
        png = null;
        RenderTexture.active = prev;
        print("true");
        return true;
    }  
    private void Update()
    {
        time += Time.deltaTime * TimeScale;
        ComputeOceanValue();
        if(tlock && time >= 1){
// GaussianRandomRT;      
// HeightSpectrumRT;      
// DisplaceXSpectrumRT;   
// DisplaceZSpectrumRT;   
// DisplaceRT;            
// OutputRT;              
// NormalRT;              
// BubblesRT;              
// BlurRT;                
// PreDisRT;
            // SaveRenderTextureToPNG(GaussianRandomRT, "Assets/ComputeShader", "GaussianRandomRT");
            // SaveRenderTextureToPNG(HeightSpectrumRT, "Assets/ComputeShader", "HeightSpectrumRT");
            // SaveRenderTextureToPNG(DisplaceXSpectrumRT, "Assets/ComputeShader", "DisplaceXSpectrumRT");
            // SaveRenderTextureToPNG(DisplaceZSpectrumRT, "Assets/ComputeShader", "DisplaceZSpectrumRT");
            SaveRenderTextureToPNG(GaussianRandomRT, "Assets/ComputeShader/texture", "GaussianRandomRT");
            SaveRenderTextureToPNG(HeightSpectrumRT, "Assets/ComputeShader/texture", "HeightSpectrumRT");
            SaveRenderTextureToPNG(DisplaceXSpectrumRT, "Assets/ComputeShader/texture", "DisplaceXSpectrumRT");
            SaveRenderTextureToPNG(DisplaceRT, "Assets/ComputeShader/texture", "DisplaceRT");
            SaveRenderTextureToPNG(OutputRT, "Assets/ComputeShader/texture", "OutputRT");
            SaveRenderTextureToPNG(NormalRT, "Assets/ComputeShader/texture", "NormalRT");  
            SaveRenderTextureToPNG(BubblesRT, "Assets/ComputeShader/texture", "BubblesRT");
            tlock = false;
        }
    }

	public Shader m_BlurShader;
	private Material m_Material;

    /***********************   ***********************/
    //初始化
    private void InitializeCSvalue(){
        //创建渲染纹理
        if (GaussianRandomRT != null && GaussianRandomRT.IsCreated())
        {
            GaussianRandomRT.Release();
            HeightSpectrumRT.Release();    
            DisplaceXSpectrumRT.Release(); 
            DisplaceZSpectrumRT.Release(); 
            DisplaceRT.Release();          
            OutputRT.Release();            
            NormalRT.Release();            
            BubblesRT.Release(); 
            BlurRT.Release(); 
        }
        //创建纹理
        GaussianRandomRT = CreateRT(rtSize);
        HeightSpectrumRT = CreateRT(rtSize);
        DisplaceXSpectrumRT = CreateRT(rtSize);
        DisplaceZSpectrumRT = CreateRT(rtSize);
        DisplaceRT = CreateRT(rtSize);
        OutputRT = CreateRT(rtSize);
        NormalRT = CreateRT(rtSize);
        BubblesRT = CreateRT(rtSize);

        //水波部分（新）
        WaveTexture = CreateRT(rtSize);
        BlurRT = CreateRT(rtSize);
        PreDisRT = CreateRT(rtSize);
        DepthRT = CreateRT(rtSize);
        CommandBuffer cmd = new CommandBuffer();
        cmd.Blit(GaussianRandomRT,DepthRT,DepthMatrix);
        //获取kernel id
        kernelGaussianRandom = OceanCS.FindKernel("ComputeGaussianRandom");                   
        kernelCreateHeightSpectrum = OceanCS.FindKernel("CreateHeightSpectrum");                   
        kernelGetDisplaceSpectrum = OceanCS.FindKernel("CreateDisplaceSpectrum"); 
        kernelFFTHorizontal = OceanCS.FindKernel("FFTHorizontal");
        kernelFFTHorizontalEnd = OceanCS.FindKernel("FFTHorizontalEnd");
        kernelFFTVertical = OceanCS.FindKernel("FFTVertical");
        kernelFFTVerticalEnd = OceanCS.FindKernel("FFTVerticalEnd");
        kernelTextureGenerationDisplace = OceanCS.FindKernel("TextureGenerationDisplace");
        kernelTextureGenerationNormalBubbles = OceanCS.FindKernel("TextureGenerationNormalBubbles");
        kernelPreDisTextureGenerationTexture = OceanCS.FindKernel("PreDisTextureGenerationTexture");
        
        kernelScreenSpaceReflection = OceanCS.FindKernel("ScreenSpaceReflection");
        //设置cs数据
        OceanCS.SetInt("N",rtSize);
        OceanCS.SetFloat("OceanLength", MeshLength);


        //生成高斯随机数
        OceanCS.SetTexture(kernelGaussianRandom, "GaussianRandomRT", GaussianRandomRT);
        OceanCS.Dispatch(kernelGaussianRandom, rtSize / 8, rtSize / 8, 1);

    }
    //ocean计算
    private void ComputeOceanValue(){
       
        /************设置纹理  ************/            
        //赋值纹理入参出参
        OceanCS.SetFloat("A",A);
        WindAndSeed.z = Random.Range(1, 100f);
        WindAndSeed.w = Random.Range(1, 100f);    
        Vector2 wind = new Vector2(WindAndSeed.x, WindAndSeed.y);
        wind.Normalize();
        wind *= WindScale;
        OceanCS.SetVector("WindAndSeed",new Vector4(wind.x, wind.y, WindAndSeed.z, WindAndSeed.w));
        OceanCS.SetFloat("Time",time);
        OceanCS.SetFloat("Lambda", Lambda);
        OceanCS.SetFloat("HeightScale", HeightScale);
        OceanCS.SetFloat("BubblesScale", BubblesScale);
        OceanCS.SetFloat("BubblesThreshold",BubblesThreshold);
        OceanCS.SetFloat("Pre",pre);

        ///  
        // 设置数据处理单元并运行CS
        // 我们使用numthreads[8,8,2]
        // 则根据纹理宽/8，高/8，1设置numthreads处理的数据范围
        ///
        CSheight();
        CSdispatch();

        if (ControlM == 0)
        {
            SetMaterialTex();
            return;
        }

        CSfft();
        CSdisplace();
        CSfoam();
        CSPreDisplace();
        CSssr();
		// CommandBuffer buf = new CommandBuffer();        
        // buf.Blit (BubblesRT, PreDisRT, m_Material);
        // buf.SetGlobalTexture("_GrabBlurTexture", PreDisRT);
        // print(pre);
        //提取tex进行展示
        img1.texture = PreDisRT;
        img2.texture = HeightSpectrumRT;
        img3.texture = DisplaceXSpectrumRT;
        img4.texture = DisplaceZSpectrumRT;
        img5.texture = OutputRT;
        img6.texture = DisplaceRT;
        img7.texture = NormalRT;
        img8.texture = BubblesRT;
        img9.texture = DepthRT;
        SetMaterialTex();

    }
    // 创建网格
    private void CreateMesh(){
        //fftSize = (int)Mathf.Pow(2, FFTPow);
        vertIndexs = new int[(MeshSize - 1) * (MeshSize - 1) * 6];
        positions = new Vector3[MeshSize * MeshSize];
        uvs = new Vector2[MeshSize * MeshSize];

        int inx = 0;
        for (int i = 0; i < MeshSize; i++)
        {
            for (int j = 0; j < MeshSize; j++)
            {
                int index = i * MeshSize + j;
                positions[index] = new Vector3((j - MeshSize / 2.0f) * MeshLength / MeshSize, 0, (i - MeshSize / 2.0f) * MeshLength / MeshSize);
                uvs[index] = new Vector2(j / (MeshSize - 1.0f), i / (MeshSize - 1.0f));

                if (i != MeshSize - 1 && j != MeshSize - 1)
                {
                    vertIndexs[inx++] = index;
                    vertIndexs[inx++] = index + MeshSize;
                    vertIndexs[inx++] = index + MeshSize + 1;

                    vertIndexs[inx++] = index;
                    vertIndexs[inx++] = index + MeshSize + 1;
                    vertIndexs[inx++] = index + 1;
                }
            }
        }
        mesh.vertices = positions;
        mesh.SetIndices(vertIndexs, MeshTopology.Triangles, 0);
        mesh.uv = uvs;
    }   

    private RenderTexture CreateRT(int size){
        RenderTexture rt = new RenderTexture(size, size, 0, RenderTextureFormat.ARGBFloat);
        rt.enableRandomWrite = true;
        rt.Create();
        return rt;
    }
    // 计算fft
    private void ComputeFFT(int kernel, ref RenderTexture input){
        OceanCS.SetTexture(kernel, "InputRT", input);
        OceanCS.SetTexture(kernel, "OutputRT", OutputRT);
        OceanCS.Dispatch(kernel, rtSize / 8, rtSize / 8, 1);

        //交换输入输出纹理
        RenderTexture rt = input;
        input = OutputRT;
        OutputRT = rt;
    }
    //设置材质纹理
    private void SetMaterialTex(){
        //设置海洋材质纹理
        OceanMaterial.SetTexture("_Displace", DisplaceRT);
        OceanMaterial.SetTexture("_Normal", NormalRT);
        OceanMaterial.SetTexture("_Bubbles", BubblesRT);
        OceanMaterial.SetTexture("_BlurTexture", PreDisRT);

        //水波
        OceanMaterial.SetTexture("_WaveResult", WaveTexture);

        //设置显示纹理
        DisplaceXMat.SetTexture("_MainTex", DisplaceXSpectrumRT);
        DisplaceYMat.SetTexture("_MainTex", HeightSpectrumRT);
        DisplaceZMat.SetTexture("_MainTex", DisplaceZSpectrumRT);
        DisplaceMat.SetTexture("_MainTex", DisplaceRT);
        NormalMat.SetTexture("_MainTex", NormalRT);
        BubblesMat.SetTexture("_MainTex", BubblesRT);


    }
    //生成高度频谱
    private void CSheight(){
        OceanCS.SetTexture(kernelCreateHeightSpectrum, "GaussianRandomRT", GaussianRandomRT);
        OceanCS.SetTexture(kernelCreateHeightSpectrum, "HeightSpectrumRT", HeightSpectrumRT);
        OceanCS.Dispatch(kernelCreateHeightSpectrum, rtSize / 8, rtSize / 8, 1);
    }
    //生成偏移频谱
    private void CSdispatch(){
        OceanCS.SetTexture(kernelGetDisplaceSpectrum, "HeightSpectrumRT", HeightSpectrumRT);
        OceanCS.SetTexture(kernelGetDisplaceSpectrum, "DisplaceXSpectrumRT", DisplaceXSpectrumRT);
        OceanCS.SetTexture(kernelGetDisplaceSpectrum, "DisplaceZSpectrumRT", DisplaceZSpectrumRT);
        OceanCS.Dispatch(kernelGetDisplaceSpectrum, rtSize / 8, rtSize / 8, 1);
    }
    //生成法线和泡沫纹理
    private void CSfoam(){
        OceanCS.SetTexture(kernelTextureGenerationNormalBubbles, "DisplaceRT", DisplaceRT);
        OceanCS.SetTexture(kernelTextureGenerationNormalBubbles, "NormalRT", NormalRT);
        OceanCS.SetTexture(kernelTextureGenerationNormalBubbles, "BubblesRT", BubblesRT);
        OceanCS.SetTexture(kernelTextureGenerationNormalBubbles, "BlurRT", PreDisRT);
        OceanCS.Dispatch(kernelTextureGenerationNormalBubbles, rtSize / 8, rtSize / 8, 1);
    }
    //计算纹理偏移    
    private void CSdisplace(){

        OceanCS.SetTexture(kernelTextureGenerationDisplace, "HeightSpectrumRT", HeightSpectrumRT);
        OceanCS.SetTexture(kernelTextureGenerationDisplace, "DisplaceXSpectrumRT", DisplaceXSpectrumRT);
        OceanCS.SetTexture(kernelTextureGenerationDisplace, "DisplaceZSpectrumRT", DisplaceZSpectrumRT);
        OceanCS.SetTexture(kernelTextureGenerationDisplace, "DisplaceRT", DisplaceRT);
        OceanCS.Dispatch(kernelTextureGenerationDisplace, rtSize / 8, rtSize / 8, 1);
    }
    /// <summary>
    /// 
    /// </summary>
    
    private void CSPreDisplace(){
        pre++;
        OceanCS.SetTexture(kernelPreDisTextureGenerationTexture, "DisplaceRT", DisplaceRT);
        OceanCS.SetTexture(kernelPreDisTextureGenerationTexture, "PreDisRT", PreDisRT);

        OceanCS.Dispatch(kernelPreDisTextureGenerationTexture, rtSize / 8, rtSize / 8, 1);
    }  
    private void CSssr(){
        
        OceanCS.SetTexture(kernelScreenSpaceReflection, "DepthRT", DepthRT);


         OceanCS.Dispatch(kernelScreenSpaceReflection, rtSize / 8, rtSize / 8, 1);
    }  
    //fft
    private void CSfft(){
                //进行横向FFT
        for (int m = 1; m <= FFTPow; m++)
        {
            int ns = (int)Mathf.Pow(2, m - 1);
            OceanCS.SetInt("Ns", ns);
            //最后一次进行特殊处理
            if (m != FFTPow)
            {
                ComputeFFT(kernelFFTHorizontal, ref HeightSpectrumRT);
                ComputeFFT(kernelFFTHorizontal, ref DisplaceXSpectrumRT);
                ComputeFFT(kernelFFTHorizontal, ref DisplaceZSpectrumRT);
            }
            else
            {
                ComputeFFT(kernelFFTHorizontalEnd, ref HeightSpectrumRT);
                ComputeFFT(kernelFFTHorizontalEnd, ref DisplaceXSpectrumRT);
                ComputeFFT(kernelFFTHorizontalEnd, ref DisplaceZSpectrumRT);
            }
            if (isControlH && ControlM == m)
            {
                SetMaterialTex();
                return;
            }
        }
        //进行纵向FFT
        for (int m = 1; m <= FFTPow; m++)
        {
            int ns = (int)Mathf.Pow(2, m - 1);
            OceanCS.SetInt("Ns", ns);
            //最后一次进行特殊处理
            if (m != FFTPow)
            {
                ComputeFFT(kernelFFTVertical, ref HeightSpectrumRT);
                ComputeFFT(kernelFFTVertical, ref DisplaceXSpectrumRT);
                ComputeFFT(kernelFFTVertical, ref DisplaceZSpectrumRT);
            }
            else
            {
                ComputeFFT(kernelFFTVerticalEnd, ref HeightSpectrumRT);
                ComputeFFT(kernelFFTVerticalEnd, ref DisplaceXSpectrumRT);
                ComputeFFT(kernelFFTVerticalEnd, ref DisplaceZSpectrumRT);
            }
            if (!isControlH && ControlM == m)
            {
                SetMaterialTex();
                return;
            }
        }
    }
}
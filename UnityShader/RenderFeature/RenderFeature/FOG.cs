using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class FOG : ScriptableRendererFeature
{
    class CustomRenderPass : ScriptableRenderPass
    {

        public Material material;
        private RenderTargetHandle tempTargetHandle;

        public Color _FogColor;
        public float _FogGlobalDensity;//全局密度
        public float _FogFallOff;
        public float _FogHeight;//雾效高度
        public float _FogStartDis;
        public float _FogInscatteringExp;
        public float _FogGradientDis;

        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            //新建RT需要一个 RenderTextureDescriptor类的参数，里面是一些描述RT的属性，
            RenderTextureDescriptor Rd = new RenderTextureDescriptor(Camera.main.pixelWidth,Camera.main.pixelHeight,RenderTextureFormat.Default,0); 
            //RenderTexture tex = new RenderTexture(Rd);//新建RT
            //获取摄像机RT
            RenderTargetIdentifier cameraColorTexture = renderingData.cameraData.renderer.cameraColorTarget;
            // RenderTargetIdentifier cameraColorTexture1 = render
            RenderTextureDescriptor cameraTextureDescriptor = renderingData.cameraData.cameraTargetDescriptor;



            //var stack = VolumeManager.instance.stack;
            //mvc = stack.GetComponent<MyVolumeComponent>();
            CommandBuffer cmd = CommandBufferPool.Get();
            cmd.name = "test pass";//这里可以在FrameDebugger里看到我们pass的名字
            cmd.GetTemporaryRT(tempTargetHandle.id,cameraTextureDescriptor);
            
            material.SetColor("_FogColor", _FogColor);
            material.SetFloat("_FogGlobalDensity",_FogGlobalDensity);
            material.SetFloat("_FogFallOff",_FogFallOff);
            material.SetFloat("_FogHeight",_FogHeight);
            material.SetFloat("_FogStartDis",_FogStartDis);
            material.SetFloat("_FogInscatteringExp",_FogInscatteringExp);
            material.SetFloat("_FogGradientDis",_FogGradientDis);



            // material.SetColor("_Color", mvc.cp.value);
            
            cmd.Blit(cameraColorTexture, tempTargetHandle.Identifier(),material);
            cmd.Blit(tempTargetHandle.Identifier(), cameraColorTexture);
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
            cmd.ReleaseTemporaryRT(tempTargetHandle.id);


        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }


    [System.Serializable]
    public class PostSettings{
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        public Material material = null;
        public Color _FogColor=new Color(0.5f,0.5f,0.5f,1f);
        public float _FogGlobalDensity = 0.5f;//全局密度
        public float _FogFallOff = 0.5f;
        public float _FogHeight = 0.5f;//雾效高度
        public float _FogStartDis = 0.5f;
        public float _FogInscatteringExp = 0.5f;
        public float _FogGradientDis = 0.5f;
    }



    CustomRenderPass m_ScriptablePass;
   public PostSettings settings = new PostSettings();
    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass();

        m_ScriptablePass.material = settings.material;
        m_ScriptablePass.renderPassEvent = settings.renderPassEvent;
        m_ScriptablePass._FogColor = settings._FogColor;
        m_ScriptablePass._FogGlobalDensity = settings._FogGlobalDensity; 
        m_ScriptablePass._FogFallOff = settings._FogFallOff;
        m_ScriptablePass._FogHeight = settings._FogHeight;
        m_ScriptablePass._FogStartDis = settings._FogStartDis;
        m_ScriptablePass._FogInscatteringExp = settings._FogInscatteringExp;
        m_ScriptablePass._FogGradientDis = settings._FogGradientDis;



    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}



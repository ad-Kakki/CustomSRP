using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class DOF : ScriptableRendererFeature
{
    class DofRenderPass : ScriptableRenderPass
    {

        public Material material;
        private RenderTargetHandle tempTargetHandle;
        public float _FocusDistance;
        public float _BokehRadius;
        public float _BlurSize;


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
            // RenderTextureDescriptor Rd = new RenderTextureDescriptor(Camera.main.pixelWidth,Camera.main.pixelHeight,RenderTextureFormat.Default,0); 
            //RenderTexture tex = new RenderTexture(Rd);//新建RT
            //获取摄像机RT
            RenderTargetIdentifier cameraColorTexture = renderingData.cameraData.renderer.cameraColorTarget;
            // RenderTargetIdentifier cameraColorTexture1 = render
            RenderTextureDescriptor cameraTextureDescriptor = renderingData.cameraData.cameraTargetDescriptor;
    
            // material.SetColor("_Color", mvc.cp.value);
            material.SetFloat("_FocusDistance", _FocusDistance);
            material.SetFloat("_BokehRadius", _BokehRadius);
            material.SetFloat("_BlurSize", _BlurSize);
            material.SetVector("_MainTex_TexelSize", new Vector4(1.0f / cameraTextureDescriptor.width, 1.0f / cameraTextureDescriptor.height, 0.0f,0.0f));


            //var stack = VolumeManager.instance.stack;
            //mvc = stack.GetComponent<MyVolumeComponent>();
            CommandBuffer cmd = CommandBufferPool.Get();
            cmd.name = "fog pass";//这里可以在FrameDebugger里看到我们pass的名字
            //cmd.GetTemporaryRT(tempTargetHandle.id,cameraTextureDescriptor);
            RenderTexture tempBlur1 = RenderTexture.GetTemporary(cameraTextureDescriptor.width, cameraTextureDescriptor.height, 0, RenderTextureFormat.ARGB32);
            RenderTexture tempBlur2 = RenderTexture.GetTemporary(cameraTextureDescriptor.width, cameraTextureDescriptor.height, 0, RenderTextureFormat.ARGB32);
            RenderTexture tempCoc = RenderTexture.GetTemporary(cameraTextureDescriptor.width, cameraTextureDescriptor.height, 0, RenderTextureFormat.ARGB32);


            cmd.Blit(cameraColorTexture, tempCoc,material,0);
            cmd.Blit(cameraColorTexture, tempBlur1,material,1);
            cmd.Blit(tempBlur1, tempBlur2, material,2);
            cmd.Blit(tempBlur2, tempBlur1, material,1);
            cmd.Blit(tempBlur1, tempBlur2, material,2);
            material.SetTexture("_CocTex", tempCoc);
            material.SetTexture("_BlurTex", tempBlur2);
            cmd.Blit(cameraColorTexture, tempBlur1, material, 3);
            cmd.CopyTexture(tempBlur1, cameraColorTexture);
            //cmd.Blit(tempBlur, tempTargetHandle.Identifier(), material,2);
            //cmd.Blit(tempTargetHandle.Identifier(), cameraColorTexture);//将结果写回相机
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
            //cmd.ReleaseTemporaryRT(tempTargetHandle.id);
            tempBlur1.Release();
            tempBlur2.Release();
            tempCoc.Release();

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
        public float _FocusDistance = -100f;
        public float _BokehRadius = 5f;
        public float _BlurSize = 1.2f;

    }

    DofRenderPass m_ScriptablePass;
   public PostSettings settings = new PostSettings();
    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new DofRenderPass();

        m_ScriptablePass.material = settings.material;
        m_ScriptablePass.renderPassEvent = settings.renderPassEvent;
        m_ScriptablePass._FocusDistance = settings._FocusDistance;
        m_ScriptablePass._BokehRadius = settings._BokehRadius;
        

        m_ScriptablePass._BlurSize = settings._BlurSize;
        // m_ScriptablePass._MainTex_TexelSize = settings._MainTex_TexelSize;

        



    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }
}
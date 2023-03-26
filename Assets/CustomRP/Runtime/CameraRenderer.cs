using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public partial class CameraRenderer
{

    ScriptableRenderContext context;

    Camera camera;
    CullingResults cullingResults;//剔除对象


    public void Render(ScriptableRenderContext context, Camera camera)
    {
        this.context = context;
        this.camera = camera;
        PrepareBuffer();
        PrepareForSceneWindow();
        if (!Cull())
        {
            return;
        }

        Setup();//设置
        DrawVisibleGeometry();//绘制可见物体
        DrawUnsupportedShaders();//绘制错误shader
        DrawGizmos();//绘制小控件
        Submit();//提交
    }

    const string bufferName = "Render Camera";
    CommandBuffer buffer = new CommandBuffer
    {
        name = bufferName
    };

    void Setup()
    {//设置绘制

        context.SetupCameraProperties(camera);
CameraClearFlags flags = camera.clearFlags;
        buffer.BeginSample(SampleName);
        //参数-深度、颜色、用于清除的颜色 
        buffer.ClearRenderTarget(
            flags <= CameraClearFlags.Depth, //skybox(1);color(2);depth(3);nothing(4)
            flags == CameraClearFlags.Color, 
            flags == CameraClearFlags.Color ? camera.backgroundColor.linear : Color.clear 
            );

        ExecuteBuffer();
    }
    void Submit()
    {//提交绘制

        buffer.EndSample(SampleName);
        ExecuteBuffer();
        context.Submit();
    }
    void ExecuteBuffer()
    {//执行Command

        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }
    void DrawVisibleGeometry()
    {//绘制可见图形
        var sortingSettings = new SortingSettings(camera)
        {//从前向后排序（不稳定）
            criteria = SortingCriteria.CommonOpaque//不透明物体
        };
        var drawingSettings = new DrawingSettings(unlitShaderTagId, sortingSettings);
        var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
        context.DrawRenderers(
            cullingResults, ref drawingSettings, ref filteringSettings
        );

        context.DrawSkybox(camera);

        sortingSettings.criteria = SortingCriteria.CommonTransparent;//透明物体
        drawingSettings.sortingSettings = sortingSettings;
        filteringSettings.renderQueueRange = RenderQueueRange.transparent;
        context.DrawRenderers(
            cullingResults, ref drawingSettings, ref filteringSettings
        );
    }

    bool Cull()
    {
        if (camera.TryGetCullingParameters(out ScriptableCullingParameters p))
        {
            cullingResults = context.Cull(ref p);
            return true;
        }
        return false;
    }

}

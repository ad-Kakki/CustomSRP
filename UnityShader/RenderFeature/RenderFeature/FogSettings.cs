using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;



[CustomEditor(typeof(FogSettings))]
public class FogSettings : EditorWindow {

    // public override void OnInspectorGUI() {
    //     base.OnInspectorGUI();
    // }
    Vector2 scrollPos = new Vector2(5f,10f);

public MeshRenderer SomeMeshRenderer;

    FogSettings(){
        this.titleContent = new GUIContent("Fog Settings");
    }
    [MenuItem(itemName:"Custom/FogTool", isValidateFunction:false)]
    public static void FogWindow(){
        Debug.Log("Test_FogWindow");
        EditorWindow.GetWindow<FogSettings>();
    }   
   
    private void OnEnable() {
        //数据初始化
    }
    private void OnGUI(){
        //窗口控件

        //BgeinScrollView(滚动坐标，窗口宽度，窗口高度)
        //scrollPos = GUILayout.BeginScrollView(scrollPos, GUILayout.Width(position.width), GUILayout.Height(position.height));
    

    }



}


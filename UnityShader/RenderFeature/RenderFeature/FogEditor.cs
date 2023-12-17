using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using Unity.VisualScripting;


[CustomEditor(typeof(FogInspector))]
public class FogEditor : Editor {

    public override void OnInspectorGUI() {

        base.OnInspectorGUI();
        Draw();
        if(GUILayout.Button("Generate Fog"))
        {
            //FogInspector ctr = target as FogInspector;
            //ctr.strName = "FogEditor";
            serializedObject.FindProperty("strName").stringValue = "FogEditor";
            serializedObject.ApplyModifiedProperties();
        }
        
    }
    void Draw(){
        FogInspector ctr = target as FogInspector;
        Color originColor = Handles.color;
        Color circleColor = Color.red;
        Color lineColor = Color.yellow;
        Vector2 lastPos = Vector2.zero;
        for(int i = 0; i < ctr.poses.Count; i++){
            var pos = ctr.poses[i];
            Vector2 targetPos = ctr.transform.position;
            Handles.color = circleColor;
            Handles.SphereHandleCap(GUIUtility.GetControlID(FocusType.Passive), targetPos+pos, Quaternion.identity, 0.2f, EventType.Repaint);
            if(i>0){
                Handles.color = lineColor;
                Handles.DrawLine(lastPos, pos);
            }
            lastPos = pos;
       
        }
        Handles.color = originColor;

    }


}

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.Rendering;
using System.IO;

public class GetLUT : MonoBehaviour
{
    public Shader shader;
    public Material material;
    public RawImage img1;
    private RenderTexture rt;
    private bool tlock = true;
    private float time = 0;  

    // Start is called before the first frame update
    void Start()
    {

        material = new Material(shader);
        // RenderTexture rt = new RenderTexture(1024, 1024, 0, RenderTextureFormat.ARGBFloat);
        
        // rt.enableRandomWrite = true;
        // rt.Create();

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
    // Update is called once per frame
    void Update()
    {
        time += Time.deltaTime;

        if(tlock && time >= 1){
            // CommandBuffer cmd = new CommandBuffer();
            // int rtID = Shader.PropertyToID("_SSSLUT");
            // cmd.GetTemporaryRT(rtID, -1, -1, 0, FilterMode.Bilinear);
            // cmd.Blit(rt, rt,material);
            RenderTexture rt = RenderTexture.GetTemporary(1024, 1024, 0);
            Graphics.Blit(rt, rt, material);
            SaveRenderTextureToPNG(rt,"Assets/", "LUT3");
            img1.texture = rt;
            tlock = false;
            print("ture");
        }
    }
 
}

using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CustomRenderFeature: ScriptableRendererFeature{
    public class CustomRenderPass: ScriptableRenderPass{

        const string customPassTag = "Custom Render Pass";
        private VolumetricCloud parameters;
        private Material mat;
        private RenderTargetIdentifier sourceRT;
        private RenderTargetHandle tempRT;

        public void Setup(Material material){
            
            this.mat = material;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            sourceRT = renderingData.cameraData.renderer.cameraColorTargetHandle;
        }

        public override void Execute(ScriptableRenderContext ctx, ref RenderingData data){

            VolumeStack stack = VolumeManager.instance.stack;
            parameters = stack.GetComponent<VolumetricCloud>();
            CommandBuffer command = CommandBufferPool.Get(customPassTag);
            Render(command, ref data);
            ctx.ExecuteCommandBuffer(command);
            CommandBufferPool.Release(command);
            command.ReleaseTemporaryRT(tempRT.id);
        }
        public void Render(CommandBuffer command, ref RenderingData data){

            if(parameters.IsActive()){
                parameters.load(mat, ref data);
                RenderTextureDescriptor opaqueDesc = data.cameraData.cameraTargetDescriptor;
                opaqueDesc.depthBufferBits = 0;
                command.GetTemporaryRT(tempRT.id, opaqueDesc);
                command.Blit(sourceRT, tempRT.Identifier(), mat,0);
                command.Blit(tempRT.Identifier(), sourceRT);
            }
        }
    }

    [SerializeField] private Shader shader;             // 手动指定该RenderFeature的所用到的Shader
    [SerializeField] private RenderPassEvent evt = RenderPassEvent.BeforeRenderingPostProcessing;
    private Material matInstance;                       // 创建一个该Shader的材质对象
    private CustomRenderPass pass;                      // RenderPass

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData){

        if(shader == null)return;
        if(matInstance == null){
            matInstance = CoreUtils.CreateEngineMaterial(shader);
        }
        pass.Setup( matInstance);
        renderer.EnqueuePass(pass);
    }
    public override void Create(){
        
        pass = new CustomRenderPass();
        pass.renderPassEvent = evt;
    }
    
}
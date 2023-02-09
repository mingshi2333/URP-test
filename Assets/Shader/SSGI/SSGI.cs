using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Demonixis.Toolbox.Rendering
{
    [Serializable]
    public class SSGISettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingOpaques;

        public Material Material = null;

        [Range(8, 128)]
        public int SamplesCount = 8;
        [Range(0.0f, 512.0f)]
        public float IndirectAmount = 8;
        [Range(0.0f, 5.0f)]
        public float NoiseAmount = 2;
        public bool Noise = true;
        public bool Enabled = true;
    }

    public class CustomRenderPass : ScriptableRenderPass
    {
        private string m_ProfilerTag;
        private RenderTargetHandle m_TmpRT1;
        private RenderTargetIdentifier m_Source;

        public Material Material;
        public int SamplesCount;
        public float IndirectAmount;
        public float NoiseAmount;
        public bool Noise;
        public bool Enabled;
        

        public CustomRenderPass(string profilerTag)
        {
            m_ProfilerTag = profilerTag;
        }
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            RenderTextureDescriptor rtDesc = renderingData.cameraData.cameraTargetDescriptor;
            cmd.GetTemporaryRT(m_TmpRT1.id, rtDesc);

            m_Source = renderingData.cameraData.renderer.cameraColorTarget;
        }
        

        private RenderTargetHandle SetupRenderTargetIdentifier(CommandBuffer cmd, int id, int width, int height)
        {
            int tmpId = Shader.PropertyToID($"SSGI_{id}_RT");
            cmd.GetTemporaryRT(tmpId, width, height, 0, FilterMode.Bilinear, RenderTextureFormat.ARGB32);

            var rt = new RenderTargetHandle(tmpId);
            ConfigureTarget(rt.id);

            return rt;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (Material == null)
            {
                return;
            }

            var cmd = CommandBufferPool.Get(m_ProfilerTag);
            var opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
            opaqueDesc.depthBufferBits = 0;

            if (Enabled)
            {
                var invProjectionMatrix = GL.GetGPUProjectionMatrix(renderingData.cameraData.camera.projectionMatrix, false).inverse;

                Material.SetFloat("_SamplesCount", SamplesCount);
                Material.SetFloat("_IndirectAmount", IndirectAmount);
                Material.SetFloat("_NoiseAmount", NoiseAmount);
                Material.SetInt("_Noise", Noise ? 1 : 0);
                Material.SetMatrix("_InverseProjectionMatrix", invProjectionMatrix);
                var temp = m_TmpRT1.id;

                Blit(cmd, m_Source, temp, Material, 0);
                Blit(cmd, temp, m_Source);
            }
            else
            {
                Blit(cmd, m_Source, m_Source);
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(m_TmpRT1.id);
        }
    }

    public class SSGI : ScriptableRendererFeature
    {
        public SSGISettings settings = new SSGISettings();
        private CustomRenderPass pass;

        public override void Create()
        {
            pass = new CustomRenderPass("SSGI");
            pass.Material = settings.Material;
            pass.SamplesCount = settings.SamplesCount;
            pass.IndirectAmount = settings.IndirectAmount;
            pass.NoiseAmount = settings.NoiseAmount;
            pass.Noise = settings.Noise;
            pass.Enabled = settings.Enabled;
            pass.renderPassEvent = settings.renderPassEvent;
        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {

            renderer.EnqueuePass(pass);
        }
    }
}
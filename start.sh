#!/bin/bash
echo "============================================"
echo "TriaAds Serverless Worker Starting"
echo "============================================"

VOLUME="/runpod-volume"
MODELS="${VOLUME}/models"

if [ ! -d "$MODELS" ]; then
    echo "[WARNING] Models dir not found at ${MODELS}"
    echo "[WARNING] Continuing anyway - models may be elsewhere"
fi

# Create symlinks if models exist
if [ -f "${MODELS}/vae/wanvideo/Wan2_1_VAE_bf16.safetensors" ]; then
    ln -sf "${MODELS}/vae/wanvideo/Wan2_1_VAE_bf16.safetensors" \
           "${MODELS}/vae/Wan2_1_VAE_bf16.safetensors" 2>/dev/null
fi

if [ -f "${MODELS}/loras/WanVideo/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" ]; then
    ln -sf "${MODELS}/loras/WanVideo/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" \
           "${MODELS}/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" 2>/dev/null
fi

echo "Starting worker..."
exec /start.sh

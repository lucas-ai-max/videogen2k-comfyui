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

# Patch handler to capture audio AND video files (not just images)
echo "[PATCH] Patching handler to support audio/video output..."
HANDLER="/handler.py"
if [ -f "$HANDLER" ]; then
    # Add mp3, wav, mp4, webm to the file extensions the handler looks for
    sed -i 's/IMAGE_EXTENSIONS = \[/IMAGE_EXTENSIONS = [".mp3", ".wav", ".mp4", ".webm", /' "$HANDLER" 2>/dev/null
    # Also try alternative patterns
    sed -i "s/\\.png'/'.png', '.mp3', '.wav', '.mp4', '.webm'/" "$HANDLER" 2>/dev/null
    sed -i 's/\.png"/.png", ".mp3", ".wav", ".mp4", ".webm"/' "$HANDLER" 2>/dev/null
    # Broader approach: replace image-only glob with all files
    sed -i 's/glob\.glob.*\.png/glob.glob(os.path.join(output_dir, "**", "*.*")/' "$HANDLER" 2>/dev/null
    echo "[PATCH] Handler patched"
else
    echo "[WARNING] Handler not found at $HANDLER"
    # Try alternative locations
    find / -name "handler.py" -path "*/src/*" 2>/dev/null | head -5
    find / -name "rp_handler.py" 2>/dev/null | head -5
fi

echo "Starting worker..."
exec /start.sh

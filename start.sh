#!/bin/bash
# =============================================================================
# TriaAds Serverless Worker — Startup Script
# Creates symlinks for models that workflows expect at root level,
# then starts the RunPod worker-comfyui handler.
# =============================================================================

echo "============================================"
echo "TriaAds Serverless Worker Starting"
echo "Date: $(date)"
echo "============================================"

VOLUME="/runpod-volume"
MODELS="${VOLUME}/models"

# ---------------------------------------------------------------------------
# 1. Check if network volume is mounted and has models
# ---------------------------------------------------------------------------
if [ ! -d "$MODELS" ]; then
    echo "[ERROR] Network volume not found at $VOLUME or models dir missing!"
    echo "  Make sure you:"
    echo "  1. Created a network volume"
    echo "  2. Downloaded models to ${MODELS}/"
    echo "  3. Attached the volume to this endpoint"
    echo ""
    echo "  Expected structure:"
    echo "    ${MODELS}/diffusion_models/WanVideo/wan2.1_i2v_480p_14B_fp8_e4m3fn.safetensors"
    echo "    ${MODELS}/diffusion_models/WanVideo/InfiniteTalk/Wan2_1-InfiniteTalk-Multi_fp8_e4m3fn_scaled_KJ.safetensors"
    echo "    ${MODELS}/text_encoders/umt5-xxl-enc-bf16.safetensors"
    echo "    ${MODELS}/clip_vision/clip_vision_h.safetensors"
    echo "    ${MODELS}/vae/wanvideo/Wan2_1_VAE_bf16.safetensors"
    echo "    ${MODELS}/diffusion_models/MelBandRoformer/MelBandRoformer_fp16.safetensors"
    echo "    ${MODELS}/loras/WanVideo/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"
    exit 1
fi

echo "[OK] Network volume found at $VOLUME"
ls -la "$MODELS"

# ---------------------------------------------------------------------------
# 2. Create symlinks that workflows expect at root model dirs
# ---------------------------------------------------------------------------
echo "[SYMLINKS] Creating model symlinks..."

# VAE: workflow expects vae/Wan2_1_VAE_bf16.safetensors
if [ -f "${MODELS}/vae/wanvideo/Wan2_1_VAE_bf16.safetensors" ]; then
    ln -sf "${MODELS}/vae/wanvideo/Wan2_1_VAE_bf16.safetensors" \
           "${MODELS}/vae/Wan2_1_VAE_bf16.safetensors"
    echo "  VAE symlink created"
fi

# LoRA: workflow expects loras/lightx2v_...bf16.safetensors
if [ -f "${MODELS}/loras/WanVideo/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" ]; then
    ln -sf "${MODELS}/loras/WanVideo/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors" \
           "${MODELS}/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"
    echo "  LoRA symlink created"
fi

# ---------------------------------------------------------------------------
# 3. Verify critical models exist
# ---------------------------------------------------------------------------
echo "[CHECK] Verifying critical models..."
MISSING=0

check_model() {
    if [ ! -f "$1" ]; then
        echo "  [MISSING] $1"
        MISSING=$((MISSING + 1))
    else
        SIZE=$(du -h "$1" | cut -f1)
        echo "  [OK] $(basename $1) ($SIZE)"
    fi
}

check_model "${MODELS}/diffusion_models/WanVideo/wan2.1_i2v_480p_14B_fp8_e4m3fn.safetensors"
check_model "${MODELS}/diffusion_models/WanVideo/InfiniteTalk/Wan2_1-InfiniteTalk-Multi_fp8_e4m3fn_scaled_KJ.safetensors"
check_model "${MODELS}/text_encoders/umt5-xxl-enc-bf16.safetensors"
check_model "${MODELS}/clip_vision/clip_vision_h.safetensors"
check_model "${MODELS}/vae/wanvideo/Wan2_1_VAE_bf16.safetensors"
check_model "${MODELS}/diffusion_models/MelBandRoformer/MelBandRoformer_fp16.safetensors"
check_model "${MODELS}/loras/WanVideo/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank64_bf16.safetensors"

if [ $MISSING -gt 0 ]; then
    echo "[WARNING] $MISSING model(s) missing! Worker will start but may fail on jobs."
else
    echo "[OK] All 7 models present"
fi

# ---------------------------------------------------------------------------
# 4. Start the worker-comfyui handler
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo "Starting worker-comfyui handler..."
echo "============================================"

# The base image's /start.sh initializes ComfyUI and the RunPod handler
exec /start.sh

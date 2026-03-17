# =============================================================================
# TriaAds Serverless Worker — InfiniteTalk + Qwen3-TTS + MelBandRoFormer
# Base: runpod/worker-comfyui (clean ComfyUI, no models)
# Models: loaded from Network Volume at /runpod-volume
# =============================================================================
FROM runpod/worker-comfyui:5.7.1-base

# ---------------------------------------------------------------------------
# 1. Pip dependencies (pinned versions from TriaAds setup guide)
# ---------------------------------------------------------------------------
RUN pip install --no-cache-dir \
    comfy_aimdo --upgrade \
    transformers==4.57.3 \
    librosa \
    accelerate \
    gguf \
    ftfy \
    pyloudnorm \
    "diffusers>=0.31.0" \
    rotary-embedding-torch \
    comfy-cli

# ---------------------------------------------------------------------------
# 2. Custom nodes — Core pipeline (4 nodes)
# ---------------------------------------------------------------------------
WORKDIR /comfyui/custom_nodes

RUN git clone --depth 1 https://github.com/ltdrdata/ComfyUI-Manager.git && \
    git clone --depth 1 https://github.com/flybirdxx/ComfyUI-Qwen-TTS.git && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-WanVideoWrapper.git && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-MelBandRoFormer.git

# ---------------------------------------------------------------------------
# 3. Custom nodes — Utilities (12 nodes)
# ---------------------------------------------------------------------------
RUN git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-Florence2.git comfyui-florence2 && \
    git clone --depth 1 https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git && \
    git clone --depth 1 https://github.com/cubiq/ComfyUI_essentials.git && \
    git clone --depth 1 https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git && \
    git clone --depth 1 https://github.com/chrisgoringe/cg-use-everywhere.git && \
    git clone --depth 1 https://github.com/yolain/ComfyUI-Easy-Use.git comfyui-easy-use && \
    git clone --depth 1 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git comfyui-videohelpersuite && \
    git clone --depth 1 https://github.com/Derfuu/Derfuu_ComfyUI_ModdedNodes.git derfuu_comfyui_moddednodes && \
    git clone --depth 1 https://github.com/jags111/ComfyUI-Logic.git comfyui-logic && \
    git clone --depth 1 https://github.com/MoonGoblinDev/Civicomfy && \
    git clone --depth 1 https://github.com/MadiatorLabs/ComfyUI-RunpodDirect

# ---------------------------------------------------------------------------
# 4. Audio separation node (via comfy-cli)
# ---------------------------------------------------------------------------
RUN echo "N" | comfy node install audio-separation-nodes-comfyui || true

# ---------------------------------------------------------------------------
# 5. Install requirements from custom nodes that have them
# ---------------------------------------------------------------------------
RUN pip install --no-cache-dir -r ComfyUI-Qwen-TTS/requirements.txt || true && \
    pip install --no-cache-dir -r ComfyUI-WanVideoWrapper/requirements.txt || true && \
    pip install --no-cache-dir -r ComfyUI-MelBandRoFormer/requirements.txt || true && \
    pip install --no-cache-dir -r ComfyUI-KJNodes/requirements.txt || true && \
    pip install --no-cache-dir -r comfyui-florence2/requirements.txt || true && \
    pip install --no-cache-dir -r ComfyUI_essentials/requirements.txt || true && \
    pip install --no-cache-dir -r comfyui-easy-use/requirements.txt || true && \
    pip install --no-cache-dir -r comfyui-videohelpersuite/requirements.txt || true

# Force pin transformers back (some requirements.txt may override)
RUN pip install --no-cache-dir transformers==4.57.3

# ---------------------------------------------------------------------------
# 6. Patch WanVideoWrapper — fp16_accumulation fix for PyTorch < 2.7
# ---------------------------------------------------------------------------
RUN WANFILE="ComfyUI-WanVideoWrapper/nodes_model_loading.py" && \
    if grep -q 'raise ValueError.*accumulation' "$WANFILE" 2>/dev/null; then \
        sed -i 's/raise ValueError("torch.backends.cuda.matmul.allow_fp16_accumulation.*")/print("[WARNING] fp16_accumulation not available, skipping (requires torch 2.7+)")/' "$WANFILE"; \
        echo "Patch applied to WanVideoWrapper"; \
    fi

# ---------------------------------------------------------------------------
# 7. Model path config — maps /runpod-volume to ComfyUI model dirs
# ---------------------------------------------------------------------------
WORKDIR /comfyui

COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml

# ---------------------------------------------------------------------------
# 8. Startup script — creates symlinks + starts worker
# ---------------------------------------------------------------------------
COPY start.sh /start_custom.sh
RUN chmod +x /start_custom.sh

CMD ["/start_custom.sh"]

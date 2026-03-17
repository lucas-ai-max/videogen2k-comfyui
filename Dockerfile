FROM runpod/worker-comfyui:5.4.0-base
RUN apt-get update && apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*
# Update ComfyUI to latest (Z-Image support)
RUN cd /comfyui && git init && git remote add origin https://github.com/comfyanonymous/ComfyUI.git || true && \
    git fetch origin master && git reset --hard origin/master
RUN pip install --no-cache-dir --upgrade comfyui-frontend-package comfy_aimdo
RUN pip install --no-cache-dir -r /comfyui/requirements.txt || true
RUN pip install --no-cache-dir \
    transformers==4.57.3 librosa accelerate gguf ftfy \
    pyloudnorm "diffusers>=0.31.0" rotary-embedding-torch
RUN comfy-node-install \
    comfyui-manager comfyui-wanvideowrapper comfyui-kjnodes \
    comfyui_essentials comfyui-videohelpersuite comfyui-custom-scripts \
    comfyui-easy-use cg-use-everywhere comfyui-florence2 comfyui_ultimatesdupscale
WORKDIR /comfyui/custom_nodes
RUN git clone --depth 1 https://github.com/flybirdxx/ComfyUI-Qwen-TTS.git && \
    git clone --depth 1 https://github.com/kijai/ComfyUI-MelBandRoFormer.git && \
    git clone --depth 1 https://github.com/Derfuu/Derfuu_ComfyUI_ModdedNodes.git && \
    git clone --depth 1 https://github.com/jags111/ComfyUI-Logic.git && \
    git clone --depth 1 https://github.com/MoonGoblinDev/Civicomfy && \
    git clone --depth 1 https://github.com/MadiatorLabs/ComfyUI-RunpodDirect
RUN pip install --no-cache-dir -r ComfyUI-Qwen-TTS/requirements.txt || true && \
    pip install --no-cache-dir -r ComfyUI-MelBandRoFormer/requirements.txt || true
RUN pip install --no-cache-dir transformers==4.57.3
RUN WANFILE=$(find /comfyui/custom_nodes -name "nodes_model_loading.py" -path "*/WanVideo*" 2>/dev/null | head -1) && \
    if [ -n "$WANFILE" ] && grep -q 'raise ValueError.*accumulation' "$WANFILE" 2>/dev/null; then \
        sed -i 's/raise ValueError("torch.backends.cuda.matmul.allow_fp16_accumulation.*")/print("[WARNING] fp16_accumulation not available")/' "$WANFILE"; \
    fi
WORKDIR /comfyui
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
COPY start.sh /start_custom.sh
RUN chmod +x /start_custom.sh
CMD ["/start_custom.sh"]

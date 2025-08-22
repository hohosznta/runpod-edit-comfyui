FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_PREFER_BINARY=1 \
    PYTHONUNBUFFERED=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

WORKDIR /workspace

# 1. 필수 패키지 설치
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3-dev \
      python3-pip \
      python3-venv \
      fonts-dejavu-core \
      rsync \
      git \
      jq \
      moreutils \
      aria2 \
      wget \
      curl \
      libglib2.0-0 \
      libsm6 \
      libgl1 \
      libxrender1 \
      libxext6 \
      ffmpeg \
      libgoogle-perftools4 \
      libtcmalloc-minimal4 \
      procps && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 2. ComfyUI + custom_nodes 설치
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI && \
    git clone https://github.com/chflame163/ComfyUI_LayerStyle.git /workspace/ComfyUI/custom_nodes/ComfyUI_LayerStyle && \
    git clone https://github.com/yolain/ComfyUI-Easy-Use.git /workspace/ComfyUI/custom_nodes/ComfyUI-Easy-Use 

# 3. Python venv 생성 및 requirements 설치
RUN python3 -m venv /workspace/venv && \
    /workspace/venv/bin/pip install --upgrade pip && \
    /workspace/venv/bin/pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu129 && \
    /workspace/venv/bin/pip install --no-cache-dir -r /workspace/ComfyUI/requirements.txt && \
    /workspace/venv/bin/pip install --no-cache-dir -r /workspace/ComfyUI/custom_nodes/ComfyUI_LayerStyle/requirements.txt && \
    /workspace/venv/bin/pip install --no-cache-dir -r /workspace/ComfyUI/custom_nodes/ComfyUI-Easy-Use /requirements.txt && \
    /workspace/venv/bin/pip install runpod==1.7.10 boto3 requests && \
    /workspace/venv/bin/pip install sageattention

# 모델 폴더 생성
RUN mkdir -p /workspace/ComfyUI/models/diffusion_models && \
    mkdir -p /workspace/ComfyUI/models/text_encoders && \
    mkdir -p /workspace/ComfyUI/models/vae && \
    mkdir -p /workspace/ComfyUI/models/loras

# 모델 다운로드
RUN wget -O /workspace/ComfyUI/models/vae/qwen_image_vae.safetensors \
      "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/vae/qwen_image_vae.safetensors" && \
    wget -O /workspace/ComfyUI/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors \
      "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors" && \
    wget -O /workspace/ComfyUI/models/diffusion_models/qwen_image_fp8_e4m3fn.safetensors \
      "https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_fp8_e4m3fn.safetensors" && \
    wget -O /workspace/ComfyUI/models/loras/Qwen-Image-Lightning-8steps-V1.1.safetensors \
      "https://huggingface.co/lightx2v/Qwen-Image-Lightning/resolve/main/Qwen-Image-Lightning-8steps-V1.1.safetensors" && \
    wget -O /workspace/ComfyUI/models/diffusion_models/qwen_image_edit_fp8_e4m3fn.safetensors \
      "https://huggingface.co/Comfy-Org/Qwen-Image-Edit_ComfyUI/resolve/main/split_files/diffusion_models/qwen_image_edit_fp8_e4m3fn.safetensors"

# 7. RunPod 핸들러 및 설정 복사
COPY start.sh handler.py ./
COPY schemas /workspace/schemas
COPY workflows /workflows

RUN chmod +x /workspace/start.sh
ENTRYPOINT ["/workspace/start.sh"]
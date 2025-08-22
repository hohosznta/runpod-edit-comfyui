#!/usr/bin/env bash

echo "Worker Initiated"
echo "Starting ComfyUI API"
source /workspace/venv/bin/activate
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"
export PYTHONUNBUFFERED=true
export HF_HOME="/workspace"
cd /workspace/ComfyUI
python main.py --port 3000 &

echo "Starting RunPod Handler"
python3 -u /workspace/handler.py

#!/usr/bin/env python3
"""
Startup script for vLLM server.
Downloads model if needed, then starts the vLLM OpenAI-compatible API server.
"""

import os
import sys
import subprocess
import logging
import time
from pathlib import Path

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def check_gpu():
    """Check if GPU is available and accessible."""
    try:
        import torch
        if torch.cuda.is_available():
            gpu_count = torch.cuda.device_count()
            gpu_name = torch.cuda.get_device_name(0)
            logger.info(f"GPU available: {gpu_name} (Count: {gpu_count})")
            return True
        else:
            logger.warning("GPU not available - falling back to CPU")
            return False
    except Exception as e:
        logger.error(f"Error checking GPU: {e}")
        return False

def download_model_if_needed():
    """Download model if it doesn't exist."""
    model_dir = "/app/models/llama-3.2-3b"
    
    if os.path.exists(os.path.join(model_dir, "config.json")):
        logger.info("Model already exists, skipping download")
        return model_dir
    
    logger.info("Model not found, downloading...")
    try:
        subprocess.run([sys.executable, "/app/download_model.py"], check=True)
        return model_dir
    except subprocess.CalledProcessError as e:
        logger.error(f"Model download failed: {e}")
        sys.exit(1)

def start_vllm_server():
    """Start the vLLM OpenAI-compatible API server."""
    
    # Check GPU availability
    gpu_available = check_gpu()
    
    # Download model if needed
    model_path = download_model_if_needed()
    
    # vLLM server configuration - don't include 'python' in the cmd
    cmd = [
        "-m", "vllm.entrypoints.openai.api_server",
        "--model", model_path,
        "--host", "0.0.0.0",
        "--port", "8000",
        "--served-model-name", "llama-3.2-3b",
    ]
    
    # GPU-specific settings
    if gpu_available:
        cmd.extend([
            "--gpu-memory-utilization", "0.8",  # Use 80% of GPU memory
            "--max-model-len", "4096",          # Context length
            "--dtype", "half",                  # Use float16 for efficiency
        ])
    else:
        logger.warning("Running on CPU - this will be very slow!")
        cmd.extend([
            "--cpu-offload-gb", "0",  # CPU fallback settings
        ])
    
    # Optional: Add more advanced settings
    cmd.extend([
        "--max-num-seqs", "64",      # Max concurrent requests
        "--block-size", "16",        # Memory block size
        "--swap-space", "4",         # Swap space in GB
    ])
    
    logger.info("Starting vLLM server with command:")
    logger.info("python " + " ".join(cmd))
    
    try:
        # Use subprocess instead of exec
        logger.info("Starting vLLM server...")
        result = subprocess.run([sys.executable] + cmd, check=True)
    except subprocess.CalledProcessError as e:
        logger.error(f"vLLM server failed to start: {e}")
        sys.exit(1)
    except Exception as e:
        logger.error(f"vLLM server failed to start: {e}")
        sys.exit(1)

if __name__ == "__main__":
    logger.info("🚀 Starting Llama 3.2-3B vLLM server...")
    
    # Add some startup delay to ensure GPU is ready
    time.sleep(5)
    
    start_vllm_server()
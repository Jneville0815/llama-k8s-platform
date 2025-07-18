#!/usr/bin/env python3
"""
Download Llama 3.2-3B model for vLLM serving.
"""

import os
import sys
import logging
from pathlib import Path
from huggingface_hub import snapshot_download, login

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def download_model():
    """Download Llama 3.2-3B model to local storage."""
    
    model_name = "meta-llama/Llama-3.2-3B-Instruct"
    model_dir = "/app/models/llama-3.2-3b"
    
    logger.info(f"Starting download of {model_name}")
    logger.info(f"Download location: {model_dir}")
    
    # Create model directory
    Path(model_dir).mkdir(parents=True, exist_ok=True)
    
    try:
        # Check if model already exists
        if os.path.exists(os.path.join(model_dir, "config.json")):
            logger.info("Model already exists, skipping download")
            return model_dir
            
        # Note: Llama models may require HuggingFace authentication
        # For now, we'll try without auth - if it fails, user needs to provide HF_TOKEN
        hf_token = os.getenv("HF_TOKEN")
        if hf_token:
            logger.info("Found HF_TOKEN, logging in to HuggingFace")
            login(token=hf_token)
        else:
            logger.warning("No HF_TOKEN found. If download fails, you may need HuggingFace authentication.")
        
        # Download model
        logger.info("Downloading model files...")
        snapshot_download(
            repo_id=model_name,
            local_dir=model_dir,
            local_dir_use_symlinks=False,
            cache_dir="/app/hf_cache",
            # Download only essential files for inference
            ignore_patterns=["*.md", "*.txt", "*.pdf"]
        )
        
        logger.info("Model download completed successfully!")
        
        # Verify essential files exist
        essential_files = ["config.json", "tokenizer.json"]
        for file in essential_files:
            file_path = os.path.join(model_dir, file)
            if os.path.exists(file_path):
                logger.info(f"✓ Found {file}")
            else:
                logger.warning(f"⚠ Missing {file}")
        
        return model_dir
        
    except Exception as e:
        logger.error(f"Error downloading model: {e}")
        
        # If download fails, provide helpful error message
        if "authentication" in str(e).lower() or "unauthorized" in str(e).lower():
            logger.error("Authentication error. Llama models require HuggingFace access.")
            logger.error("Please:")
            logger.error("1. Create a HuggingFace account at https://huggingface.co")
            logger.error("2. Request access to meta-llama/Llama-3.2-3B-Instruct")
            logger.error("3. Create an access token at https://huggingface.co/settings/tokens")
            logger.error("4. Set HF_TOKEN environment variable with your token")
            
        sys.exit(1)

if __name__ == "__main__":
    download_model()
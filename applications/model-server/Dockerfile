# Use the official vLLM OpenAI-compatible server image
FROM vllm/vllm-openai:latest

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV HF_HOME=/app/hf_cache

# Create app directory and subdirectories
WORKDIR /app
RUN mkdir -p /app/models /app/logs /app/hf_cache

# Install additional dependencies if needed
RUN pip install requests

# Copy our custom scripts
COPY download_model.py /app/download_model.py
COPY start_server.py /app/start_server.py

# Set proper permissions
RUN chmod +x /app/download_model.py /app/start_server.py

# Expose vLLM default port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=300s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Use our custom startup script instead of the default vLLM server
CMD ["python", "/app/start_server.py"]
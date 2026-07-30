from fastapi import FastAPI, HTTPException, Request, Response
from pydantic import BaseModel
import httpx
import logging
import time
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="LLaMA Chat API", version="1.0.0")

# Configuration
VLLM_SERVICE_URL = "http://llama-model-server.llama-platform.svc.cluster.local:8000"

# Prometheus metrics
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration')
CHAT_REQUESTS = Counter('llama_chat_requests_total', 'Total chat requests')
CHAT_TOKENS = Counter('llama_tokens_generated_total', 'Total tokens generated')
CHAT_DURATION = Histogram('llama_chat_duration_seconds', 'Chat request duration')

class ChatRequest(BaseModel):
    message: str
    max_tokens: int = 100

class ChatResponse(BaseModel):
    response: str

@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    
    REQUEST_COUNT.labels(
        method=request.method, 
        endpoint=request.url.path, 
        status=response.status_code
    ).inc()
    REQUEST_DURATION.observe(time.time() - start_time)
    
    return response

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    CHAT_REQUESTS.inc()
    start_time = time.time()
    
    try:
        # Call your vLLM service
        async with httpx.AsyncClient(timeout=30.0) as client:
            vllm_request = {
                "model": "llama-3.2-3b",
                "messages": [{"role": "user", "content": request.message}],
                "max_tokens": request.max_tokens,
                "temperature": 0.7
            }
            
            response = await client.post(
                f"{VLLM_SERVICE_URL}/v1/chat/completions",
                json=vllm_request
            )
            response.raise_for_status()
            
            result = response.json()
            ai_response = result["choices"][0]["message"]["content"]
            
            # Count approximate tokens (rough estimate)
            estimated_tokens = len(ai_response.split())
            CHAT_TOKENS.inc(estimated_tokens)
            
            CHAT_DURATION.observe(time.time() - start_time)
            
            return ChatResponse(response=ai_response)
            
    except Exception as e:
        logger.error(f"Error calling vLLM service: {e}")
        raise HTTPException(status_code=500, detail="Error processing chat request")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
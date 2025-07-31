from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import httpx
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="LLaMA Chat API", version="1.0.0")

# Configuration
VLLM_SERVICE_URL = "http://llama-model-server:8000"

class ChatRequest(BaseModel):
    message: str
    max_tokens: int = 100

class ChatResponse(BaseModel):
    response: str

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
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
            
            return ChatResponse(response=ai_response)
            
    except Exception as e:
        logger.error(f"Error calling vLLM service: {e}")
        raise HTTPException(status_code=500, detail="Error processing chat request")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
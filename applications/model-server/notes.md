1. run `build-image.sh`
2. push image to ecr

`docker tag llama-vllm-server:latest 861819669871.dkr.ecr.us-east-1.amazonaws.com/llama-vllm-server`

`docker push 861819669871.dkr.ecr.us-east-1.amazonaws.com/llama-vllm-server`

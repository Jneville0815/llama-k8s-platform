```
kubectl create secret docker-registry ecr-secret \
  --docker-server=861819669871.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  --namespace=llama-platform
```

```
kubectl create secret generic huggingface-token \
  --from-literal=token=YOUR_HF_TOKEN_HERE \
  --namespace=llama-platform
```

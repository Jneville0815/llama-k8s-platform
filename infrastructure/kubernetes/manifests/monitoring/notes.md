# Add Helm repos

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install the full stack

helm install prometheus prometheus-community/kube-prometheus-stack \
 --namespace monitoring \
 --create-namespace \
 --set grafana.enabled=true \
 --set grafana.service.type=ClusterIP

# Restart FastAPI deployment

kubectl rollout restart deployment llama-api-backend -n llama-platform

# Apply monitoring manifests

kubectl apply -f ~/Projects/llama-k8s-platform/infrastructure/kubernetes/manifests/monitoring/

# Get Grafana password

kubectl get secret prometheus-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 --decode

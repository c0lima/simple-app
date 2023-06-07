#!/bin/bash



#function is_es_cluster_healthy() {
#  HEALTH_STATUS=$(curl -s "${ES_SERVICE_URL}/_cluster/health" | jq -r '.status')
#  if [[ $HEALTH_STATUS == "green" ]] || [[ $HEALTH_STATUS == "yellow" ]]; then
#    return 0
#  else
#    return 1
#  fi
#}

# Create a directory on your host machine to store Elasticsearch data
mkdir -p ~/elasticsearch-data

# Start Minikube
minikube start --extra-config="apiserver.enable-admission-plugins=DefaultStorageClass" --extra-config="apiserver.authorization-mode=Node,RBAC"

# Stop until Minikube is ready
while [[ $(minikube status -o json | jq -r '.Host') != "Running" ]]; do
  echo "Waiting for Minikube to be ready..."
  sleep 5
done

# Mount the host directory to Minikube VM
minikube mount ~/elasticsearch-data:/mnt/data/elasticsearch &

# Wait for the mount to be established
sleep 10

# Create namespace for installing helm charts.
kubectl apply -f k8s/base/0-namespace.yaml

# Install nginx ingress controller & KEDA
helm repo add nginx-stable https://helm.nginx.com/stable
helm install main nginx-stable/nginx-ingress -f k8s/helm/ingress-controller-vars.yaml -n myapp

helm repo add kedacore https://kedacore.github.io/charts 
helm install keda kedacore/keda -n myapp

# Apply your Kubernetes configuration
kubectl apply --recursive -f k8s/base/.

## Wait for Elasticsearch pod(s) to be running
#ES_PODS_RUNNING=false
#while [ $ES_PODS_RUNNING == false ]; do
#  ES_PODS_STATUS=$(kubectl get pods -n myapp -l app=elasticsearch -o jsonpath='{.items[*].status.phase}')
#  if [[ $ES_PODS_STATUS == "Running" ]]; then
#    ES_PODS_RUNNING=true
#  else
#    echo "Waiting for Elasticsearch pods to be ready..."
#    sleep 10
#  fi
#done
#
## Get the name of one of the Elasticsearch pods
#ES_POD_NAME=$(kubectl get pods -n myapp -l app=elasticsearch -o jsonpath='{.items[0].metadata.name}')
#
## Forward a local port (e.g., 9200) to the Elasticsearch service port
#kubectl port-forward -n myapp "$ES_POD_NAME" 9200:9200 &
#
## Wait for port-forwarding to be established
#sleep 5
#
## Update the Elasticsearch service URL
#ES_SERVICE_URL="http://localhost:9200"
#
## Wait for Elasticsearch cluster to be healthy
#ES_HEALTHY=false
#while [ $ES_HEALTHY == false ]; do
#  if is_es_cluster_healthy; then
#    ES_HEALTHY=true
#  else
#    echo "Waiting for Elasticsearch cluster to be healthy..."
#    sleep 10
#  fi
#done
#
## TODO: Automate this part
#
## We need to manually send this request to Elasticsearch
## in order to upload the template to ES.
##curl -X POST "${ES_SERVICE_URL}/_scripts/nginx_requests_keda" -H 'Content-Type: application/json' --data-binary "@k8s/elasticsearch/nginx_requests_keda.json"
#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}
ACTION=${2:-apply}

echo "🚀 Deploying to $ENVIRONMENT environment..."

cd terraform/environments/$ENVIRONMENT

# Run Terraform
terraform init -upgrade
terraform validate
terraform plan -out=tfplan

if [ "$ACTION" == "apply" ]; then
    read -p "Do you want to apply these changes? (yes/no): " confirm
    if [ "$confirm" == "yes" ]; then
        terraform apply tfplan
        
        # Update kubeconfig
        CLUSTER_NAME="$ENVIRONMENT-eks-cluster"
        aws eks update-kubeconfig --region us-west-2 --name $CLUSTER_NAME
        
        # Deploy monitoring
        echo "Deploying monitoring stack..."
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        helm repo update
        
        kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
        
        helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
            --namespace monitoring \
            --values ../../../monitoring/prometheus/values.yaml
        
        echo "✅ Deployment complete!"
        echo "Access Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
    fi
fi
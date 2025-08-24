#!/bin/bash
set -e

ENVIRONMENT=${1:-dev}

echo "⚠️  WARNING: This will destroy all resources in $ENVIRONMENT environment!"
read -p "Are you sure? Type 'destroy' to confirm: " confirm

if [ "$confirm" == "destroy" ]; then
    cd terraform/environments/$ENVIRONMENT
    
    # Remove Kubernetes resources first
    kubectl delete ingress --all -A
    kubectl delete service --all -A
    kubectl delete deployment --all -A
    
    # Destroy infrastructure
    terraform destroy -auto-approve
    
    echo "✅ Cleanup complete!"
else
    echo "Cleanup cancelled."
fi
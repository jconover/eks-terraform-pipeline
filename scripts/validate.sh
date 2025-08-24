#!/bin/bash
set -e

echo "🔍 Validating EKS cluster..."

# Check cluster
echo "Checking cluster status..."
kubectl get nodes

echo "Checking system pods..."
kubectl get pods -n kube-system

echo "Checking deployments..."
kubectl get deployments -A

echo "Checking services..."
kubectl get services -A

echo "Checking ingress..."
kubectl get ingress -A

# Test metrics
echo "Testing metrics server..."
kubectl top nodes

echo "Testing pod metrics..."
kubectl top pods -A

echo "✅ Validation complete!"
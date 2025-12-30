#!/bin/bash

##############################################################################
# Script: Install ArgoCD on EKS Cluster
# Description: Installs ArgoCD and configures initial setup
##############################################################################

set -e

echo "=========================================="
echo "ArgoCD Installation on EKS"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: kubectl is not configured or cluster is not reachable${NC}"
    exit 1
fi

echo -e "${GREEN}✓ kubectl is configured${NC}"

# Create ArgoCD namespace
echo ""
echo "Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
echo ""
echo "Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo ""
echo "Waiting for ArgoCD pods to be ready (this may take 2-3 minutes)..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Patch ArgoCD server to use LoadBalancer (for easy access)
echo ""
echo "Patching ArgoCD server service to LoadBalancer..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Wait for LoadBalancer to get external IP
echo ""
echo "Waiting for LoadBalancer to get external IP..."
sleep 10

ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -z "$ARGOCD_SERVER" ]; then
    echo -e "${YELLOW}Warning: LoadBalancer IP not available yet. Please wait a few minutes and check:${NC}"
    echo "kubectl get svc argocd-server -n argocd"
else
    echo -e "${GREEN}✓ ArgoCD Server URL: https://$ARGOCD_SERVER${NC}"
fi

# Get initial admin password
echo ""
echo "Retrieving initial admin password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "=========================================="
echo -e "${GREEN}ArgoCD Installation Complete!${NC}"
echo "=========================================="
echo ""
echo "📝 Access Information:"
echo "   URL: https://$ARGOCD_SERVER"
echo "   Username: admin"
echo "   Password: $ARGOCD_PASSWORD"
echo ""
echo "💡 To access ArgoCD CLI:"
echo "   argocd login $ARGOCD_SERVER --username admin --password $ARGOCD_PASSWORD --insecure"
echo ""
echo "🔐 IMPORTANT: Change the default password after first login!"
echo "   argocd account update-password"
echo ""
echo "📊 To install ArgoCD CLI:"
echo "   Linux: curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "   chmod +x /usr/local/bin/argocd"
echo ""
echo "🚀 Next steps:"
echo "   1. Login to ArgoCD UI"
echo "   2. Change admin password"
echo "   3. Deploy ArgoCD applications: ./argocd/install/deploy-apps.sh"
echo ""

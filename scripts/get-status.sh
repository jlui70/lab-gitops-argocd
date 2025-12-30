#!/bin/bash

##############################################################################
# Script: Get GitOps Stack Status
# Description: Shows status of all components
##############################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================================================"
echo -e "${BLUE}       GitOps Stack Status${NC}"
echo "================================================================"
echo ""

# Cluster info
echo -e "${YELLOW}▶ Cluster Information:${NC}"
kubectl cluster-info | head -1
echo ""

# Namespaces
echo -e "${YELLOW}▶ Namespaces:${NC}"
kubectl get namespaces | grep -E "NAME|istio-system|argocd|ecommerce" || echo "No relevant namespaces found"
echo ""

# Istio status
echo -e "${YELLOW}▶ Istio Components:${NC}"
kubectl get pods -n istio-system || echo "Istio not installed"
echo ""

# ArgoCD status
echo -e "${YELLOW}▶ ArgoCD Status:${NC}"
kubectl get pods -n argocd 2>/dev/null || echo "ArgoCD not installed"
echo ""

# ArgoCD Applications
echo -e "${YELLOW}▶ ArgoCD Applications:${NC}"
kubectl get applications -n argocd 2>/dev/null || echo "No applications found"
echo ""

# Staging apps
echo -e "${YELLOW}▶ Staging Environment:${NC}"
kubectl get pods -n ecommerce-staging 2>/dev/null || echo "Staging environment not deployed"
echo ""

# Production apps
echo -e "${YELLOW}▶ Production Environment:${NC}"
kubectl get pods -n ecommerce-production 2>/dev/null || echo "Production environment not deployed"
echo ""

# Load Balancers
echo -e "${YELLOW}▶ LoadBalancers:${NC}"
echo "Istio Gateway:"
kubectl get svc istio-ingressgateway -n istio-system 2>/dev/null || echo "  Not found"
echo ""
echo "ArgoCD Server:"
kubectl get svc argocd-server -n argocd 2>/dev/null || echo "  Not found"
echo ""

# Access URLs
echo "================================================================"
echo -e "${BLUE}Access URLs:${NC}"
echo "================================================================"
echo ""

ISTIO_GATEWAY=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending...")
ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "Pending...")

echo "🌐 Application: http://$ISTIO_GATEWAY"
echo "🔧 ArgoCD: https://$ARGOCD_SERVER"
echo ""

# ArgoCD password
if kubectl get secret argocd-initial-admin-secret -n argocd &>/dev/null; then
    ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    echo "🔑 ArgoCD Password: $ARGOCD_PASSWORD"
else
    echo "🔑 ArgoCD Password: (not found - may have been deleted after password change)"
fi

echo ""
echo "================================================================"

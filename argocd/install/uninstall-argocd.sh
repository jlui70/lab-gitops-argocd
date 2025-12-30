#!/bin/bash

##############################################################################
# Script: Uninstall ArgoCD
# Description: Removes ArgoCD and all applications
##############################################################################

set -e

echo "=========================================="
echo "Uninstalling ArgoCD"
echo "=========================================="

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}WARNING: This will delete ArgoCD and all managed applications!${NC}"
read -p "Are you sure? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "Aborted."
    exit 1
fi

# Delete ArgoCD applications first
echo "Deleting ArgoCD applications..."
kubectl delete application ecommerce-staging -n argocd --ignore-not-found=true
kubectl delete application ecommerce-production -n argocd --ignore-not-found=true

# Delete managed namespaces
echo "Deleting managed namespaces..."
kubectl delete namespace ecommerce-staging --ignore-not-found=true
kubectl delete namespace ecommerce-production --ignore-not-found=true

# Delete ArgoCD
echo "Deleting ArgoCD installation..."
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Delete ArgoCD namespace
echo "Deleting argocd namespace..."
kubectl delete namespace argocd --ignore-not-found=true

echo ""
echo -e "${RED}ArgoCD has been completely removed.${NC}"

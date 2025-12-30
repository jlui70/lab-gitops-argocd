#!/bin/bash

##############################################################################
# Script: Destroy GitOps Stack
# Description: Complete cleanup of all resources
##############################################################################

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================================"
echo -e "${RED}WARNING: Complete GitOps Stack Destruction${NC}"
echo "================================================================"
echo ""
echo "This will destroy:"
echo "  - ArgoCD and all applications"
echo "  - Staging and Production namespaces"
echo "  - Istio Service Mesh"
echo "  - EKS Cluster and all resources"
echo "  - VPC and networking"
echo "  - Terraform state backend"
echo ""
echo -e "${YELLOW}This action CANNOT be undone!${NC}"
echo ""
read -p "Type 'destroy-everything' to continue: " -r
echo

if [[ $REPLY != "destroy-everything" ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Starting destruction process..."
echo ""

# Step 1: Delete ArgoCD applications
echo "Step 1: Deleting ArgoCD applications..."
kubectl delete application --all -n argocd --ignore-not-found=true
sleep 5

# Step 2: Delete managed namespaces
echo "Step 2: Deleting application namespaces..."
kubectl delete namespace ecommerce-staging --ignore-not-found=true &
kubectl delete namespace ecommerce-production --ignore-not-found=true &
wait

# Step 3: Uninstall ArgoCD
echo "Step 3: Uninstalling ArgoCD..."
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --ignore-not-found=true
kubectl delete namespace argocd --ignore-not-found=true

# Step 4: Uninstall Istio
echo "Step 4: Uninstalling Istio..."
cd istio/install
./cleanup.sh 2>/dev/null || echo "Istio cleanup script not found or failed"
cd ../..

# Step 5: Destroy Terraform infrastructure
echo "Step 5: Destroying infrastructure..."
./destroy-all.sh

echo ""
echo "================================================================"
echo -e "${RED}GitOps Stack Destroyed${NC}"
echo "================================================================"
echo ""
echo "All resources have been removed."
echo ""

#!/bin/bash

##############################################################################
# Script: Deploy ArgoCD Applications (Staging and Production)
# Description: Creates ArgoCD Application resources for GitOps
##############################################################################

set -e

echo "=========================================="
echo "Deploying ArgoCD Applications"
echo "=========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get current Git repository URL
GIT_REPO=$(git config --get remote.origin.url)

if [ -z "$GIT_REPO" ]; then
    echo -e "${YELLOW}Warning: Could not detect Git repository. Using placeholder.${NC}"
    GIT_REPO="https://github.com/YOUR-USERNAME/istio-eks-terraform-gitops.git"
fi

echo "Git Repository: $GIT_REPO"

# Update ArgoCD application manifests with actual Git repo
echo ""
echo "Updating ArgoCD applications with Git repository..."

# Deploy staging application
echo ""
echo "Deploying Staging Application..."
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ecommerce-staging
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${GIT_REPO}
    targetRevision: HEAD
    path: k8s-manifests/staging
  destination:
    server: https://kubernetes.default.svc
    namespace: ecommerce-staging
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF

echo -e "${GREEN}✓ Staging application created${NC}"

# Deploy production application (manual sync for safety)
echo ""
echo "Deploying Production Application..."
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ecommerce-production
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${GIT_REPO}
    targetRevision: HEAD
    path: k8s-manifests/production
  destination:
    server: https://kubernetes.default.svc
    namespace: ecommerce-production
  syncPolicy:
    syncOptions:
    - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF

echo -e "${GREEN}✓ Production application created (manual sync required)${NC}"

echo ""
echo "=========================================="
echo -e "${GREEN}ArgoCD Applications Deployed!${NC}"
echo "=========================================="
echo ""
echo "📊 Check application status:"
echo "   kubectl get applications -n argocd"
echo ""
echo "🔄 Sync applications:"
echo "   argocd app sync ecommerce-staging"
echo "   argocd app sync ecommerce-production  # Manual approval required"
echo ""
echo "🌐 View in ArgoCD UI:"
echo "   Get ArgoCD URL: kubectl get svc argocd-server -n argocd"
echo ""
echo "📝 Notes:"
echo "   - Staging: Auto-sync enabled (any Git push triggers deploy)"
echo "   - Production: Manual sync required (safety measure)"
echo ""

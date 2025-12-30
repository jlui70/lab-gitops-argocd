#!/bin/bash

# ============================================================================
# Script: deploy-v2-simple.sh
# Descrição: Deploy simples da versão 2.0 via GitOps
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}"
cat << "EOF"
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║   🚀 DEPLOY VERSÃO 2.0 - GitOps Demo                              ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Get AWS account info
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
ECR_REPO="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecommerce"

echo -e "${CYAN}📊 Configuração:${NC}"
echo "   AWS Account: $ACCOUNT_ID"
echo "   ECR Repo: $ECR_REPO"
echo ""

read -p "Deseja continuar? (s/N): " confirm
if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

# ============================================================================
# Step 1: Build Docker image from microservices-v2
# ============================================================================

echo ""
echo -e "${BLUE}[1/4] 🐳 Build da imagem v2.0 (microservices-v2)${NC}"
echo ""

cd microservices-v2/ecommerce-ui

docker build -t ${ECR_REPO}/ecommerce-ui:v2.0.0 \
             -t ${ECR_REPO}/ecommerce-ui:staging-latest \
             .

echo -e "${GREEN}✅ Build concluído${NC}"

# ============================================================================
# Step 2: Push to ECR
# ============================================================================

echo ""
echo -e "${BLUE}[2/4] 📤 Push para ECR${NC}"
echo ""

aws ecr get-login-password --region ${AWS_REGION} | \
    docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

docker push ${ECR_REPO}/ecommerce-ui:v2.0.0
docker push ${ECR_REPO}/ecommerce-ui:staging-latest

echo -e "${GREEN}✅ Push concluído${NC}"

# ============================================================================
# Step 3: Update manifest
# ============================================================================

echo ""
echo -e "${BLUE}[3/4] 📝 Atualizando manifesto${NC}"
echo ""

cd "$PROJECT_ROOT"

sed -i "s|image: rslim087/ecommerce-ui:.*|image: ${ECR_REPO}/ecommerce-ui:v2.0.0|g" k8s-manifests/base/ecommerce-ui.yaml
sed -i "s|image: ${ECR_REPO}/ecommerce-ui:.*|image: ${ECR_REPO}/ecommerce-ui:v2.0.0|g" k8s-manifests/base/ecommerce-ui.yaml

echo -e "${YELLOW}📋 Nova imagem:${NC}"
grep "image:" k8s-manifests/base/ecommerce-ui.yaml | head -1

git add k8s-manifests/base/ecommerce-ui.yaml
git commit -m "feat: Deploy ecommerce-ui v2.0.0

- Built from microservices-v2/ecommerce-ui
- Added 'Versão 2.0 🚀' to welcome message
- GitOps deployment via ArgoCD"

echo -e "${GREEN}✅ Manifesto atualizado${NC}"

# ============================================================================
# Step 4: Git push (triggers ArgoCD)
# ============================================================================

echo ""
echo -e "${BLUE}[4/4] 🚀 Git push (ArgoCD auto-sync)${NC}"
echo ""

git push origin main

echo -e "${GREEN}✅ Push concluído!${NC}"
echo ""
echo -e "${CYAN}⏳ ArgoCD vai sincronizar automaticamente em ~3 minutos${NC}"
echo ""
echo -e "${YELLOW}💡 Monitore com:${NC}"
echo "   kubectl rollout status deployment/ecommerce-ui -n ecommerce-staging"
echo ""
echo -e "${YELLOW}🌐 Depois acesse:${NC}"
echo "   http://aea55d7dff98f43afa1b5a3ce75aa411-126944.us-east-1.elb.amazonaws.com/"
echo ""
echo -e "${GREEN}🎉 Você verá: 'Welcome to the E-commerce App - Versão 2.0 🚀'${NC}"
echo ""

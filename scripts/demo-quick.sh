#!/bin/bash

#######################################################
# DEMO RÁPIDA - Apenas aplica mudanças já preparadas
# Use este durante a apresentação para ser mais rápido
#######################################################

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 GitOps Demo - Deploy Rápido v2.0${NC}"
echo ""

# 1. Mostrar URL atual
GATEWAY_URL=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo -e "${GREEN}URL Aplicação:${NC} http://$GATEWAY_URL"
echo -e "${YELLOW}Versão atual: 'Welcome to the E-commerce App'${NC}"
echo ""

# 2. Mostrar mudança no código
echo -e "${BLUE}📝 Mudança no código:${NC}"
echo -e "${GREEN}+ <h1>Welcome to the E-commerce App - Versão 2.0 🚀</h1>${NC}"
echo ""

# 3. Build e Push (simplificado - usa imagem já existente se possível)
echo -e "${BLUE}🐳 Build & Push Docker image...${NC}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Login ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com > /dev/null 2>&1

# Build
cd microservices/ecommerce-ui
docker build -q -t ecommerce-ui:v2.0 . > /dev/null
docker tag ecommerce-ui:v2.0 ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/ecommerce/ecommerce-ui:v2.0
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/ecommerce/ecommerce-ui:v2.0 > /dev/null
cd ../..

echo -e "${GREEN}✓ Imagem v2.0 publicada no ECR${NC}"
echo ""

# 4. Atualizar manifests
echo -e "${BLUE}📦 Atualizando Kubernetes manifests...${NC}"
cd k8s-manifests/staging
kustomize edit set image rslim087/ecommerce-ui=${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/ecommerce/ecommerce-ui:v2.0
cd ../..

echo -e "${GREEN}✓ Manifests atualizados${NC}"
echo ""

# 5. Git commit + push
echo -e "${BLUE}🌐 Git commit + push (trigger GitOps)...${NC}"
git add -A
git commit -m "feat: Update UI to version 2.0 - GitOps Demo" > /dev/null
git push origin main > /dev/null 2>&1

echo -e "${GREEN}✓ Push realizado! ArgoCD vai sincronizar em ~1-3 min${NC}"
echo ""

# 6. Force ArgoCD refresh
echo -e "${BLUE}🔄 Forçando ArgoCD refresh...${NC}"
argocd app get ecommerce-staging --refresh > /dev/null 2>&1 || true
echo -e "${GREEN}✓ ArgoCD notificado${NC}"
echo ""

# 7. Watch sync
echo -e "${YELLOW}Aguardando ArgoCD sync...${NC}"
sleep 10

# 8. Watch pods
echo -e "${BLUE}📊 Pods sendo recriados:${NC}"
kubectl get pods -n ecommerce-staging -l app=ecommerce-ui
echo ""

echo -e "${GREEN}✓ DEMO CONCLUÍDA!${NC}"
echo ""
echo -e "Abra: ${BLUE}http://$GATEWAY_URL${NC}"
echo -e "Você deve ver: ${GREEN}'Welcome to the E-commerce App - Versão 2.0 🚀'${NC}"
echo ""

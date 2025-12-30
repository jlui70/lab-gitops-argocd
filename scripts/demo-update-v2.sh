#!/bin/bash

# ============================================================================
# Script: demo-update-v2.sh
# Descrição: Demonstração GitOps - Atualização automática v1.0 → v2.0
# Demonstra: GitOps workflow 100% automático com ArgoCD + Git + ECR
# Fluxo: Code → Build → ECR → Git Push → ArgoCD Auto-Sync → Deploy
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}"
cat << "EOF"
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║   🚀 DEMO: ATUALIZAÇÃO PARA VERSÃO 2.0                            ║
║                                                                    ║
║   Simulando desenvolvedor fazendo alteração no código             ║
║   Build → Push ECR → ArgoCD Sync → Deploy v2.0                   ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificações
echo -e "${BLUE}🔍 Verificando pré-requisitos...${NC}"

if ! aws sts get-caller-identity &>/dev/null; then
    echo -e "${RED}❌ Credenciais AWS não configuradas${NC}"
    exit 1
fi

if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}❌ Cluster EKS não acessível${NC}"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
ECR_REPO="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecommerce"

echo -e "${GREEN}✅ AWS Account: $ACCOUNT_ID${NC}"
echo -e "${GREEN}✅ ECR Repository: $ECR_REPO${NC}"

# Confirmação
echo ""
echo -e "${YELLOW}Este script irá:${NC}"
echo "   1. 🔄 Verificar que estamos na versão 1.0"
echo "   2. 👨‍💻 Simular desenvolvedor alterando o código"
echo "   3. 🐳 Construir imagem Docker v2.0.0"
echo "   4. 📤 Fazer push para ECR"
echo "   5. 📝 Git commit + push (trigger ArgoCD)"
echo "   6. 🎯 Aguardar ArgoCD sincronizar AUTOMATICAMENTE (~3 min)"
echo "   7. ✅ Validar deployment da versão 2.0"
echo ""
echo -e "${GREEN}🎯 GitOps Puro: Sem intervenção manual no cluster!${NC}"
echo ""
read -p "Deseja continuar? (s/N): " confirm

if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

START_TIME=$(date +%s)

# ============================================================================
# Step 1: Verificar versão atual
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [1/7] 🔍 VERIFICANDO VERSÃO ATUAL                                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

CURRENT_VERSION=$(kubectl get deployment ecommerce-ui -n ecommerce-staging -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "não encontrado")
echo -e "Versão atual: ${CYAN}$CURRENT_VERSION${NC}"
sleep 2

# ============================================================================
# Step 2: Mostrar alteração do desenvolvedor
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [2/7] 👨‍💻 ALTERAÇÃO DO CÓDIGO (Desenvolvedor)                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}📝 Alteração feita pelo desenvolvedor:${NC}"
echo ""
echo "  Arquivo: microservices/ecommerce-ui/src/pages/Home.js"
echo ""
echo -e "${RED}  - <h1>Welcome to the E-commerce App</h1>${NC}"
echo -e "${GREEN}  + <h1>Welcome to the E-commerce App - Versão 2.0 🚀</h1>${NC}"
echo ""
echo -e "  package.json: version: ${GREEN}2.0.0${NC}"
echo ""
sleep 3

# ============================================================================
# Step 3: Build da imagem Docker
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [3/7] 🐳 CONSTRUINDO IMAGEM DOCKER v2.0.0                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

cd microservices/ecommerce-ui

echo "Construindo imagem..."
docker build -t ${ECR_REPO}/ecommerce-ui:v2.0.0 \
             -t ${ECR_REPO}/ecommerce-ui:staging-latest \
             . | tail -n 20

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo -e "${GREEN}✅ Imagem construída com sucesso${NC}"
else
    echo -e "${RED}❌ Erro ao construir imagem${NC}"
    exit 1
fi

cd "$PROJECT_ROOT"

# ============================================================================
# Step 4: Login no ECR e Push
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [4/7] 📤 ENVIANDO PARA ECR                                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo "Fazendo login no ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

echo "Enviando imagem v2.0.0..."
docker push ${ECR_REPO}/ecommerce-ui:v2.0.0 | tail -n 10

echo "Enviando tag staging-latest..."
docker push ${ECR_REPO}/ecommerce-ui:staging-latest | tail -n 10

echo -e "${GREEN}✅ Imagens enviadas para ECR${NC}"

# ============================================================================
# Step 5: Atualizar manifesto Kubernetes e fazer Git Push
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [5/7] 📝 ATUALIZANDO MANIFESTO E PUSH PARA GIT                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

MANIFEST_FILE="k8s-manifests/base/ecommerce-ui.yaml"

if [ -f "$MANIFEST_FILE" ]; then
    echo "Atualizando versão da imagem em $MANIFEST_FILE..."
    
    # Atualizar a imagem para v2.0.0
    sed -i "s|image: rslim087/ecommerce-ui:.*|image: ${ECR_REPO}/ecommerce-ui:v2.0.0|g" $MANIFEST_FILE
    sed -i "s|image: ${ECR_REPO}/ecommerce-ui:.*|image: ${ECR_REPO}/ecommerce-ui:v2.0.0|g" $MANIFEST_FILE
    
    echo -e "${GREEN}✅ Manifesto atualizado${NC}"
    
    # Mostrar a diferença
    echo ""
    echo -e "${YELLOW}📋 Alteração no manifesto:${NC}"
    grep "image:" $MANIFEST_FILE | head -1
    echo ""
    
    # Git: Add, Commit e Push
    echo -e "${CYAN}📤 Fazendo commit e push para Git...${NC}"
    echo ""
    
    git add $MANIFEST_FILE
    git add microservices/ecommerce-ui/src/pages/Home.js
    git add microservices/ecommerce-ui/package.json
    
    git commit -m "feat: Update ecommerce-ui to version 2.0

- Updated welcome message to include 'Versão 2.0 🚀'
- Updated Docker image tag to v2.0.0 in base manifest
- Built and pushed new image to ECR: ${ECR_REPO}/ecommerce-ui:v2.0.0
- Developer: Frontend Team
- GitOps Demo: Automatic deployment via ArgoCD" || echo "Sem mudanças para commitar"
    
    echo ""
    echo -e "${CYAN}🚀 Pushing para GitHub (isso vai trigger o ArgoCD automaticamente!)...${NC}"
    git push origin main
    
    echo -e "${GREEN}✅ Push realizado! ArgoCD vai detectar automaticamente em ~30s-3min${NC}"
else
    echo -e "${RED}❌ Manifesto não encontrado em $MANIFEST_FILE${NC}"
    exit 1
fi

# ============================================================================
# Step 6: Monitorar ArgoCD Sync Automático
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [6/7] 🎯 MONITORANDO ARGOCD SYNC AUTOMÁTICO                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if kubectl get application ecommerce-staging -n argocd &>/dev/null; then
    echo -e "${YELLOW}🔍 GitOps em Ação:${NC}"
    echo "   1. ✅ Código alterado e commitado"
    echo "   2. ✅ Push para GitHub realizado"
    echo "   3. 🔄 ArgoCD detectando mudanças no Git..."
    echo "   4. ⏳ Aguardando sincronização automática (pode levar até 3 minutos)"
    echo ""
    
    echo -e "${CYAN}💡 Dica: ArgoCD faz polling a cada 3 minutos por padrão${NC}"
    echo -e "${CYAN}   syncPolicy.automated está habilitado, então sync será automático!${NC}"
    echo ""
    
    # Aguardar sync automático
    COUNTER=0
    MAX_WAIT=180  # 3 minutos
    LAST_STATUS=""
    
    echo -e "${YELLOW}⏱️  Monitorando status (timeout: 3 minutos)...${NC}"
    echo ""
    
    while [ $COUNTER -lt $MAX_WAIT ]; do
        SYNC_STATUS=$(kubectl get application ecommerce-staging -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
        HEALTH_STATUS=$(kubectl get application ecommerce-staging -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
        REVISION=$(kubectl get application ecommerce-staging -n argocd -o jsonpath='{.status.sync.revision}' 2>/dev/null | cut -c1-7 || echo "Unknown")
        
        # Mostrar status apenas se mudou
        CURRENT_STATUS="${SYNC_STATUS}|${HEALTH_STATUS}"
        if [ "$CURRENT_STATUS" != "$LAST_STATUS" ]; then
            echo -e "  [${COUNTER}s] Sync: ${CYAN}${SYNC_STATUS}${NC} | Health: ${CYAN}${HEALTH_STATUS}${NC} | Revision: ${CYAN}${REVISION}${NC}"
            LAST_STATUS="$CURRENT_STATUS"
        fi
        
        # Verificar se sincronizou
        if [ "$SYNC_STATUS" == "Synced" ] && [ "$HEALTH_STATUS" == "Healthy" ]; then
            echo ""
            echo -e "${GREEN}✅ ArgoCD sincronizou automaticamente com sucesso!${NC}"
            echo -e "${GREEN}✅ Aplicação está saudável!${NC}"
            break
        fi
        
        sleep 5
        COUNTER=$((COUNTER + 5))
    done
    
    if [ $COUNTER -ge $MAX_WAIT ]; then
        echo ""
        echo -e "${YELLOW}⚠️  Timeout atingido. Verificar status manualmente:${NC}"
        echo "   kubectl get application ecommerce-staging -n argocd"
    fi
    
    echo ""
    echo -e "${CYAN}📊 Status Final:${NC}"
    kubectl get application ecommerce-staging -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null | xargs -I {} echo "   Sync Status: {}"
    kubectl get application ecommerce-staging -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null | xargs -I {} echo "   Health Status: {}"
    kubectl get application ecommerce-staging -n argocd -o jsonpath='{.status.sync.revision}' 2>/dev/null | cut -c1-7 | xargs -I {} echo "   Git Revision: {}"
    
else
    echo -e "${RED}❌ ArgoCD não encontrado no cluster${NC}"
    exit 1
fi

# ============================================================================
# Step 7: Validar Deployment
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [7/7] ✅ VALIDANDO DEPLOYMENT                                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo "Aguardando rollout do deployment..."
kubectl rollout status deployment/ecommerce-ui -n ecommerce-staging --timeout=120s

echo ""
echo "Verificando pods..."
kubectl get pods -n ecommerce-staging -l app=ecommerce-ui

echo ""
echo "Nova versão da imagem:"
kubectl get deployment ecommerce-ui -n ecommerce-staging -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

# ============================================================================
# Resumo Final
# ============================================================================

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

GATEWAY_URL=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║   ✅ ATUALIZAÇÃO PARA VERSÃO 2.0 CONCLUÍDA!                        ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📊 Tempo total: ${MINUTES}m ${SECONDS}s${NC}"
echo ""

echo -e "${YELLOW}🌐 Acesse a aplicação:${NC}"
echo ""
echo "  URL: http://$GATEWAY_URL"
echo ""
echo -e "${GREEN}  ✨ Você verá: 'Welcome to the E-commerce App - Versão 2.0 🚀'${NC}"
echo ""

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                                    ║${NC}"
echo -e "${CYAN}║   🎬 DEMONSTRAÇÃO GITOPS COMPLETA!                                 ║${NC}"
echo -e "${CYAN}║                                                                    ║${NC}"
echo -e "${CYAN}║   1. ✅ Desenvolvedor alterou código (Home.js)                     ║${NC}"
echo -e "${CYAN}║   2. ✅ Build da imagem Docker v2.0.0                              ║${NC}"
echo -e "${CYAN}║   3. ✅ Push para ECR                                              ║${NC}"
echo -e "${CYAN}║   4. ✅ Git commit + push para GitHub                              ║${NC}"
echo -e "${CYAN}║   5. ✅ ArgoCD detectou mudança AUTOMATICAMENTE                    ║${NC}"
echo -e "${CYAN}║   6. ✅ Deploy automático realizado                                ║${NC}"
echo -e "${CYAN}║   7. ✅ Aplicação atualizada                                       ║${NC}"
echo -e "${CYAN}║                                                                    ║${NC}"
echo -e "${CYAN}║   🎯 GitOps Puro: Sem intervenção manual no cluster!              ║${NC}"
echo -e "${CYAN}║                                                                    ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}🎉 Versão 2.0 está no ar!${NC}"
echo ""

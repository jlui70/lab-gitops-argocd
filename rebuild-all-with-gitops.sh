#!/bin/bash

# ============================================================================
# Script: rebuild-all-with-gitops.sh
# Descrição: Deploy COMPLETO incluindo GitOps (para demonstração final)
# Tempo estimado: ~40 minutos
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}"
cat << "EOF"
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║   🚀 REBUILD COMPLETO COM GITOPS                                   ║
║                                                                    ║
║   Infraestrutura + Istio + ArgoCD + Aplicação                     ║
║   Tempo estimado: ~40 minutos                                     ║
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

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✅ AWS Account: $ACCOUNT_ID${NC}"

# Confirmação
echo ""
echo -e "${YELLOW}Este script irá:${NC}"
echo "   1. [~15min] Deploy infraestrutura (VPC + EKS)"
echo "   2. [~5min]  Instalar Istio + Addons Observabilidade"
echo "   3. [~2min]  Instalar ArgoCD"
echo "   4. [~3min]  Criar imagens Docker e enviar para ECR"
echo "   5. [~2min]  Deploy aplicações via ArgoCD"
echo "   6. [~1min]  Iniciar ferramentas de monitoramento"
echo ""
read -p "Deseja continuar? (s/N): " confirm

if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

START_TIME=$(date +%s)

# ============================================================================
# Step 1: Deploy Infraestrutura
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [1/6] 🏗️  DEPLOY INFRAESTRUTURA                                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if ./scripts/01-deploy-infra.sh; then
    echo -e "${GREEN}✅ Infraestrutura OK${NC}"
else
    echo -e "${RED}❌ Erro no deploy de infraestrutura${NC}"
    exit 1
fi

# ============================================================================
# Step 2: Instalar Istio + Addons
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [2/6] 🕸️  INSTALANDO ISTIO + OBSERVABILIDADE                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if ./scripts/02-install-istio.sh; then
    echo -e "${GREEN}✅ Istio e addons OK${NC}"
else
    echo -e "${RED}❌ Erro na instalação do Istio${NC}"
    exit 1
fi

# ============================================================================
# Step 3: Instalar ArgoCD
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [3/6] 🎯 INSTALANDO ARGOCD                                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if ./argocd/install/install-argocd.sh; then
    echo -e "${GREEN}✅ ArgoCD instalado${NC}"
else
    echo -e "${RED}❌ Erro na instalação do ArgoCD${NC}"
    exit 1
fi

# Capturar credenciais do ArgoCD
ARGOCD_URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "error")

# ============================================================================
# Step 4: Criar e Enviar Imagens Docker
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [4/6] 🐳 CRIANDO IMAGENS DOCKER                                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo "Construindo imagem ecommerce-ui v1.0.0 (cor azul)..."
if ./scripts/build-demo-image.sh v1.0.0 "#3498db"; then
    echo -e "${GREEN}✅ Imagem v1.0.0 criada${NC}"
else
    echo -e "${RED}❌ Erro ao criar imagem${NC}"
    exit 1
fi

# Criar imagens nginx simples para outros microserviços
echo ""
echo -e "${YELLOW}Criando imagens nginx para microserviços auxiliares...${NC}"

AWS_REGION="us-east-1"

# Login no ECR (caso não esteja logado)
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com >/dev/null 2>&1

# Lista de microserviços que precisam de imagens simples
SERVICES=(
    "contact-support-team"
    "product-catalog"
    "product-inventory"
    "profile-management"
)

for SERVICE in "${SERVICES[@]}"; do
    echo "  → Criando imagem: $SERVICE"
    
    # Criar repositório se não existir
    aws ecr describe-repositories --repository-names "ecommerce/$SERVICE" --region $AWS_REGION >/dev/null 2>&1 || \
        aws ecr create-repository --repository-name "ecommerce/$SERVICE" --region $AWS_REGION --image-tag-mutability MUTABLE >/dev/null 2>&1
    
    # Construir imagem nginx simples
    docker build -t ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecommerce/${SERVICE}:v1.0.0 - <<DOCKERFILE >/dev/null 2>&1
FROM nginx:alpine
RUN echo "<h1>$SERVICE</h1><p>Version: v1.0.0</p><p>Microservice placeholder</p>" > /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
DOCKERFILE
    
    # Fazer push para ECR
    docker push ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecommerce/${SERVICE}:v1.0.0 >/dev/null 2>&1
    echo -e "     ${GREEN}✓${NC} $SERVICE"
done

echo -e "${GREEN}✅ Todas as imagens criadas${NC}"

# ============================================================================
# Step 5: Deploy Aplicações via ArgoCD
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [5/6] 📦 DEPLOYANDO APLICAÇÕES VIA ARGOCD                         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if ./argocd/install/deploy-apps.sh; then
    echo -e "${GREEN}✅ Aplicações ArgoCD criadas${NC}"
else
    echo -e "${RED}❌ Erro ao criar aplicações${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}⏳ Aguardando sincronização inicial (30s)...${NC}"
sleep 30

echo "Forçando sincronização da aplicação staging..."
kubectl patch application ecommerce-staging -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'

echo ""
echo -e "${CYAN}⏳ Aguardando pods ficarem prontos (60s)...${NC}"
sleep 60

# ============================================================================
# Step 6: Start Monitoring
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  [6/6] 📊 INICIANDO MONITORAMENTO                                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

./scripts/04-start-monitoring.sh &
MONITORING_PID=$!
sleep 5

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
echo -e "${GREEN}║   ✅ DEPLOY COMPLETO COM GITOPS FINALIZADO!                        ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📊 Tempo total: ${MINUTES}m ${SECONDS}s${NC}"
echo ""

echo -e "${YELLOW}🌐 URLs de Acesso:${NC}"
echo ""
echo "  🛒 Aplicação:   http://$GATEWAY_URL"
echo "  🎯 ArgoCD:      https://$ARGOCD_URL"
echo "      User: admin"
echo "      Pass: $ARGOCD_PASSWORD"
echo ""
echo "  📊 Prometheus:  http://localhost:9090"
echo "  📈 Grafana:     http://localhost:3000"
echo "  🕸️  Kiali:      http://localhost:20001"
echo "  🔍 Jaeger:      http://localhost:16686"
echo ""

echo -e "${YELLOW}📋 Status dos Recursos:${NC}"
echo ""
kubectl get nodes --no-headers | awk '{print "  🖥️  Node: "$1" - "$2}'
echo ""
kubectl get applications -n argocd --no-headers | awk '{print "  📦 App: "$1" - Sync: "$2" - Health: "$3}'
echo ""
kubectl get pods -n ecommerce-staging --no-headers | wc -l | awk '{print "  🚀 Pods Staging: "$1}'
echo ""

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                                                                    ║${NC}"
echo -e "${CYAN}║   🎬 PRONTO PARA DEMONSTRAÇÃO!                                     ║${NC}"
echo -e "${CYAN}║                                                                    ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}📝 Para demonstrar atualização GitOps:${NC}"
echo ""
echo "  1. Criar nova versão:"
echo "     ./scripts/build-demo-image.sh v2.0.0 '#e74c3c'"
echo ""
echo "  2. Fazer commit e push:"
echo "     git add k8s-manifests/"
echo "     git commit -m 'Update to v2.0.0'"
echo "     git push origin main"
echo ""
echo "  3. Aguardar ArgoCD sincronizar automaticamente (30-60s)"
echo ""
echo "  4. Acessar aplicação e ver versão 2.0.0 com cor vermelha"
echo ""

echo -e "${GREEN}🎉 Ambiente completo pronto!${NC}"
echo ""

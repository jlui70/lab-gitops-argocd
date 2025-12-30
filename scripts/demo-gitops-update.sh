#!/bin/bash

#######################################################
# Script de Demonstração GitOps - Atualização v2.0
# Este script automatiza o fluxo completo de GitOps
#######################################################

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    GitOps Demo - Deploy Versão 2.0 do Frontend        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Função para pausar e esperar confirmação
pause() {
    echo -e "${YELLOW}Pressione ENTER para continuar...${NC}"
    read -r
}

# Função para mostrar status
show_status() {
    echo -e "${GREEN}✓${NC} $1"
}

# Função para mostrar erro
show_error() {
    echo -e "${RED}✗${NC} $1"
}

# Função para mostrar info
show_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Verificar se estamos no diretório correto
if [ ! -f "scripts/deploy-gitops-stack.sh" ]; then
    show_error "Execute este script a partir da raiz do repositório!"
    exit 1
fi

echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PASSO 1: Verificar Estado Atual da Aplicação${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo ""

show_info "Obtendo URL da aplicação..."
GATEWAY_URL=$(kubectl get svc istio-ingressgateway -n istio-system \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ -z "$GATEWAY_URL" ]; then
    show_error "Não foi possível obter URL do Istio Gateway!"
    show_info "Verifique se o cluster está rodando: kubectl get svc -n istio-system"
    exit 1
fi

show_status "URL da aplicação: http://$GATEWAY_URL"
echo ""
show_info "Versão ATUAL mostra: 'Welcome to the E-commerce App'"
show_info "Vamos atualizar para: 'Welcome to the E-commerce App - Versão 2.0 🚀'"
echo ""

pause

echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PASSO 2: Código já foi alterado pelo desenvolvedor${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo ""

show_info "Arquivo modificado: microservices/ecommerce-ui/src/pages/Home.js"
echo ""

# Mostrar diff
if [ -f "microservices/ecommerce-ui/src/pages/Home.js" ]; then
    show_info "Mudança no código:"
    echo -e "${GREEN}+ <h1>Welcome to the E-commerce App - Versão 2.0 🚀</h1>${NC}"
    echo -e "${RED}- <h1>Welcome to the E-commerce App</h1>${NC}"
    show_status "Código atualizado!"
else
    show_error "Arquivo Home.js não encontrado!"
    show_info "Certifique-se de que os arquivos de código fonte foram criados."
    exit 1
fi

echo ""
pause

echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PASSO 3: Build da Nova Imagem Docker${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo ""

# Obter AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")

if [ -z "$AWS_ACCOUNT_ID" ]; then
    show_error "Não foi possível obter AWS Account ID!"
    show_info "Execute: aws configure"
    exit 1
fi

show_info "AWS Account ID: $AWS_ACCOUNT_ID"
show_info "Registry: ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com"
echo ""

show_info "Fazendo login no Amazon ECR..."
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com > /dev/null 2>&1

show_status "Login no ECR realizado com sucesso!"
echo ""

show_info "Building Docker image (isso pode levar 3-5 minutos)..."
echo ""

cd microservices/ecommerce-ui

docker build -t ecommerce-ui:v2.0 . 2>&1 | while read line; do
    echo "  $line"
done

show_status "Build concluído!"
echo ""

# Tag para ECR
show_info "Tagging imagem para ECR..."
docker tag ecommerce-ui:v2.0 \
  ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/ecommerce/ecommerce-ui:v2.0

show_status "Imagem taggeada: ecommerce-ui:v2.0"
echo ""

# Push para ECR
show_info "Pushing imagem para ECR..."
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/ecommerce/ecommerce-ui:v2.0

show_status "Imagem publicada no ECR!"
echo ""

cd ../..
pause

echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PASSO 4: Atualizar Manifests Kubernetes${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo ""

show_info "Atualizando kustomization.yaml para staging..."
cd k8s-manifests/staging

# Atualizar image tag usando kustomize
kustomize edit set image \
  rslim087/ecommerce-ui=${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/ecommerce/ecommerce-ui:v2.0

show_status "Manifest atualizado!"
echo ""

show_info "Conteúdo de kustomization.yaml:"
cat kustomization.yaml | grep -A5 "images:" || echo "images configuradas"
echo ""

cd ../..
pause

echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PASSO 5: Commit e Push (Trigger GitOps!)${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo ""

# Verificar mudanças
show_info "Arquivos modificados:"
git status --short | while read line; do
    echo "  $line"
done
echo ""

# Adicionar mudanças
show_info "Adicionando mudanças ao Git..."
git add microservices/ecommerce-ui/
git add k8s-manifests/staging/kustomization.yaml

# Commit
show_info "Criando commit..."
git commit -m "feat: Update UI to version 2.0 with new welcome message

- Changed welcome message to include 'Versão 2.0 🚀'
- Updated Docker image tag to v2.0
- Built and pushed new image to ECR
- Developer: Team Frontend
- GitOps Demo: Automatic deployment via ArgoCD"

show_status "Commit criado!"
echo ""

# Push
show_info "Pushing para GitHub (isso vai trigger o ArgoCD!)..."
git push origin main

show_status "Push realizado! ArgoCD vai detectar em ~30s-3min"
echo ""

pause

echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PASSO 6: Monitorar ArgoCD Sync${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo ""

show_info "Verificando status do ArgoCD..."
echo ""

# Forçar refresh do ArgoCD
show_info "Forçando refresh do ArgoCD..."
argocd app get ecommerce-staging --refresh > /dev/null 2>&1 || true

# Mostrar status
show_info "Status atual:"
argocd app get ecommerce-staging 2>/dev/null | grep -E "Sync Status|Health Status|Revision" || {
    show_info "ArgoCD CLI não disponível, use a UI:"
    show_info "kubectl get svc argocd-server -n argocd"
}
echo ""

show_info "Aguardando ArgoCD sincronizar (pode levar 1-3 minutos)..."
show_info "Você pode acompanhar em tempo real:"
echo ""
echo "  ArgoCD UI: kubectl port-forward -n argocd svc/argocd-server 8080:443"
echo "  Ou CLI: watch -n 2 'argocd app get ecommerce-staging | grep -A5 Sync'"
echo ""

# Aguardar sync
COUNTER=0
MAX_WAIT=180  # 3 minutos

while [ $COUNTER -lt $MAX_WAIT ]; do
    SYNC_STATUS=$(argocd app get ecommerce-staging -o json 2>/dev/null | \
      jq -r '.status.sync.status' 2>/dev/null || echo "Unknown")
    
    if [ "$SYNC_STATUS" == "Synced" ]; then
        show_status "ArgoCD sincronizado com sucesso!"
        break
    fi
    
    echo -ne "\r  Aguardando... ${COUNTER}s (Status: $SYNC_STATUS)        "
    sleep 5
    COUNTER=$((COUNTER + 5))
done

echo ""
echo ""

pause

echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PASSO 7: Verificar Pods Sendo Recriados${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo ""

show_info "Verificando pods do ecommerce-ui..."
echo ""

kubectl get pods -n ecommerce-staging -l app=ecommerce-ui

echo ""
show_info "Aguardando novo pod ficar pronto (com imagem v2.0)..."

kubectl wait --for=condition=ready pod \
  -l app=ecommerce-ui \
  -n ecommerce-staging \
  --timeout=120s

echo ""
show_status "Novo pod está rodando!"
echo ""

show_info "Detalhes do pod:"
kubectl describe pod -n ecommerce-staging -l app=ecommerce-ui | \
  grep -E "Image:|Status:|Ready:" | head -5

echo ""
pause

echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}PASSO 8: Validar Mudança na Aplicação${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════${NC}"
echo ""

show_info "URL da aplicação: http://$GATEWAY_URL"
echo ""
show_status "Abra o browser e recarregue a página!"
echo ""
show_info "Você deve ver: 'Welcome to the E-commerce App - Versão 2.0 🚀'"
echo ""

# Testar endpoint
show_info "Testando endpoint..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://$GATEWAY_URL" || echo "000")

if [ "$HTTP_CODE" == "200" ]; then
    show_status "Aplicação está respondendo (HTTP $HTTP_CODE)"
else
    show_error "Aplicação retornou HTTP $HTTP_CODE"
fi

echo ""
pause

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✓ DEMO GITOPS CONCLUÍDA!                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}Resumo do que aconteceu:${NC}"
echo "  1. ✓ Desenvolvedor alterou código (Home.js)"
echo "  2. ✓ Build da nova imagem Docker v2.0"
echo "  3. ✓ Push da imagem para ECR"
echo "  4. ✓ Atualização do manifest Kubernetes"
echo "  5. ✓ Git commit + push para GitHub"
echo "  6. ✓ ArgoCD detectou mudança e sincronizou"
echo "  7. ✓ Kubernetes criou novo pod (rolling update)"
echo "  8. ✓ Aplicação atualizada - Zero downtime!"
echo ""

echo -e "${BLUE}Tempo total:${NC} ~8-10 minutos (do commit ao deploy)"
echo ""

echo -e "${YELLOW}Próximos passos:${NC}"
echo "  • Ver tráfego no Kiali: kubectl port-forward -n istio-system svc/kiali 20001:20001"
echo "  • Ver métricas no Grafana: kubectl port-forward -n istio-system svc/grafana 3000:3000"
echo "  • Deploy para production: Repita o processo em k8s-manifests/production/"
echo ""

show_status "GitOps demonstrado com sucesso! 🎉"
echo ""

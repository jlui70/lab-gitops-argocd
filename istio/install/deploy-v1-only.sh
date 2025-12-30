#!/bin/bash

# Script para fazer deploy APENAS da versão V1 (sem Canary)
# Usado para demonstração inicial - mostrando aplicação estável
# Autor: DevOps Project
# Data: Dezembro 2025

set -e

echo "🚀 Deploy da Aplicação E-Commerce - VERSÃO V1 APENAS"
echo "===================================================="

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verificar pré-requisitos
echo -e "${YELLOW}📋 Verificando pré-requisitos...${NC}"

if ! kubectl get namespace istio-system &> /dev/null; then
    echo -e "${RED}❌ Namespace istio-system não encontrado. Instale o Istio primeiro.${NC}"
    echo "Execute: ./scripts/02-install-istio.sh"
    exit 1
fi

echo -e "${GREEN}✅ Istio encontrado${NC}\n"

# 1. Criar namespace
echo -e "${YELLOW}📦 Passo 1/4: Criando namespace ecommerce...${NC}"
kubectl apply -f ../manifests/01-namespace/

echo -e "${GREEN}✅ Namespace criado com injeção automática habilitada${NC}\n"

# 2. Deploy dos microserviços v1
echo -e "${YELLOW}📦 Passo 2/4: Fazendo deploy dos microserviços (v1 APENAS)...${NC}"
kubectl apply -f ../manifests/02-microservices-v1/

echo "⏳ Aguardando pods ficarem prontos (pode levar 3-5 minutos)..."
kubectl wait --for=condition=ready pod \
  --all -n ecommerce \
  --timeout=300s

echo -e "${GREEN}✅ Todos os microserviços v1 deployados${NC}\n"

# 3. Configurar Gateway e VirtualService
echo -e "${YELLOW}📦 Passo 3/4: Configurando Istio Gateway...${NC}"
kubectl apply -f ../manifests/03-istio-gateway/

echo -e "${GREEN}✅ Gateway e VirtualService configurados${NC}\n"

# 4. Instalar stack de observabilidade
echo -e "${YELLOW}📦 Passo 4/4: Instalando stack de observabilidade...${NC}"
kubectl apply -f ../manifests/06-observability/

echo "⏳ Aguardando ferramentas de observabilidade ficarem prontas..."
kubectl wait --for=condition=ready pod \
  -l app=prometheus \
  -n istio-system \
  --timeout=180s 2>/dev/null || true

kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=grafana \
  -n istio-system \
  --timeout=180s 2>/dev/null || true

kubectl wait --for=condition=ready pod \
  -l app=kiali \
  -n istio-system \
  --timeout=180s 2>/dev/null || true

kubectl wait --for=condition=ready pod \
  -l app=jaeger \
  -n istio-system \
  --timeout=180s 2>/dev/null || true

echo -e "${GREEN}✅ Stack de observabilidade instalada${NC}\n"

# Exibir status
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 Deploy V1 concluído com sucesso!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}\n"

# Listar pods
echo -e "${YELLOW}📊 Status dos Pods (v1 apenas):${NC}"
kubectl get pods -n ecommerce

# Obter URL da aplicação
echo -e "\n${YELLOW}🌐 URL da Aplicação:${NC}"
GATEWAY_URL=$(kubectl get svc istio-ingressgateway -n istio-system \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -n "$GATEWAY_URL" ]; then
    echo -e "${GREEN}http://$GATEWAY_URL${NC}"
else
    echo -e "${RED}Aguardando LoadBalancer ser provisionado...${NC}"
    echo "Execute: kubectl get svc istio-ingressgateway -n istio-system"
fi

echo -e "\n${YELLOW}📚 Próximos passos para DEMONSTRAÇÃO:${NC}"
echo ""
echo -e "${GREEN}1. Iniciar ferramentas de monitoramento:${NC}"
echo "   ./scripts/04-start-monitoring.sh"
echo ""
echo -e "${GREEN}2. Gerar tráfego e visualizar no Kiali (100% v1):${NC}"
echo "   ./test-canary-visual.sh"
echo "   Acesse: http://localhost:20001 (Kiali)"
echo ""
echo -e "${YELLOW}3. DEMO: Deploy do Canary (80% v1 / 20% v2):${NC}"
echo "   ./istio/install/demo-deploy-v2-canary.sh"
echo ""
echo -e "${YELLOW}4. DEMO: Ativar Circuit Breaker:${NC}"
echo "   ./istio/install/demo-deploy-circuit-breaker.sh"
echo ""

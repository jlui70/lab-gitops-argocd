#!/bin/bash

# Script para DEMONSTRAÇÃO: Deploy do Canary (product-catalog v2)
# Mostra transição de 100% v1 → 80% v1 / 20% v2
# Autor: DevOps Project
# Data: Dezembro 2025

set -e

echo "🎭 DEMONSTRAÇÃO: Deploy do Canary Deployment"
echo "============================================="

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                                                                    ║"
echo "║   🎬 CENÁRIO DE DEMONSTRAÇÃO #1                                    ║"
echo "║                                                                    ║"
echo "║   Deploy do product-catalog v2                                    ║"
echo "║   Configuração: 80% v1 / 20% v2 (Canary)                          ║"
echo "║                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Verificar se v1 está rodando
echo -e "${YELLOW}📋 Verificando se aplicação v1 está rodando...${NC}"
if ! kubectl get deployment product-catalog -n ecommerce &> /dev/null; then
    echo -e "${RED}❌ Aplicação v1 não encontrada!${NC}"
    echo "Execute primeiro: ./istio/install/deploy-v1-only.sh"
    exit 1
fi

echo -e "${GREEN}✅ Aplicação v1 rodando${NC}\n"

# Mostrar status atual
echo -e "${YELLOW}📊 Status ANTES do deploy do Canary:${NC}"
kubectl get pods -n ecommerce -l app=product-catalog
echo ""

# Deploy do Canary
echo -e "${YELLOW}🚀 Fazendo deploy do product-catalog v2 (Canary)...${NC}"
kubectl apply -f ../manifests/04-canary-deployment/product-catalog-v2.yaml

echo "⏳ Aguardando pods do canary ficarem prontos..."
kubectl wait --for=condition=ready pod \
  -l app=product-catalog,version=v2 \
  -n ecommerce \
  --timeout=180s

kubectl wait --for=condition=ready pod \
  -l app=mongodb-product-catalog \
  -n ecommerce \
  --timeout=180s

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║   ✅ CANARY DEPLOYMENT ATIVADO COM SUCESSO!                        ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}\n"

# Mostrar status após deploy
echo -e "${YELLOW}📊 Status DEPOIS do deploy do Canary:${NC}"
kubectl get pods -n ecommerce -l app=product-catalog
echo ""

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}║   🎯 DEMONSTRAÇÃO: Canary Deployment Configurado                   ║${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}║   Distribuição de Tráfego:                                        ║${NC}"
echo -e "${BLUE}║   • 80% → product-catalog v1 (versão estável)                     ║${NC}"
echo -e "${BLUE}║   • 20% → product-catalog v2 (nova versão - teste)                ║${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}📚 Próximos passos para DEMONSTRAÇÃO:${NC}\n"

echo -e "${GREEN}1. Gerar tráfego para visualizar o Canary:${NC}"
echo "   ./test-canary-visual.sh"
echo ""

echo -e "${GREEN}2. Abrir Kiali para visualizar distribuição 80/20:${NC}"
echo "   http://localhost:20001"
echo "   Graph → Namespace: ecommerce → Display: Traffic Distribution"
echo ""

echo -e "${GREEN}3. Verificar métricas no Prometheus:${NC}"
echo "   http://localhost:9090"
echo "   Query: sum by (destination_version) (istio_requests_total{destination_service_namespace=\"ecommerce\"})"
echo ""

echo -e "${YELLOW}4. PRÓXIMA DEMO: Deploy do Circuit Breaker:${NC}"
echo "   ./istio/install/demo-deploy-circuit-breaker.sh"
echo ""

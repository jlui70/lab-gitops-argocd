#!/bin/bash

# Script para DEMONSTRAÇÃO: Deploy do Circuit Breaker (order-management v2)
# Mostra circuit breaker em ação → erro → fallback 100% v1
# Autor: DevOps Project
# Data: Dezembro 2025

set -e

echo "🎭 DEMONSTRAÇÃO: Circuit Breaker em Ação"
echo "========================================"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                                                                    ║"
echo "║   🎬 CENÁRIO DE DEMONSTRAÇÃO #2                                    ║"
echo "║                                                                    ║"
echo "║   Deploy do order-management v2 com ERRO                          ║"
echo "║   Demonstra: Circuit Breaker → Fallback 100% v1                   ║"
echo "║                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

# Verificar se Canary está rodando
echo -e "${YELLOW}📋 Verificando se Canary está ativo...${NC}"
if ! kubectl get deployment product-catalog-v2 -n ecommerce &> /dev/null; then
    echo -e "${RED}❌ Canary (product-catalog v2) não encontrado!${NC}"
    echo "Execute primeiro: ./istio/install/demo-deploy-v2-canary.sh"
    exit 1
fi

echo -e "${GREEN}✅ Canary ativo (80% v1 / 20% v2)${NC}\n"

# Mostrar status atual
echo -e "${YELLOW}📊 Status ANTES do deploy do Circuit Breaker:${NC}"
kubectl get pods -n ecommerce
echo ""

# Deploy do Circuit Breaker (order-management v2 com erro)
echo -e "${YELLOW}🚀 Fazendo deploy do order-management v2...${NC}"
echo -e "${MAGENTA}⚠️  ATENÇÃO: Esta versão contém um erro proposital!${NC}\n"

kubectl apply -f ../manifests/05-circuit-breaker/

echo "⏳ Aguardando pods do order-management v2 ficarem prontos..."
kubectl wait --for=condition=ready pod \
  -l app=order-management,version=v2 \
  -n ecommerce \
  --timeout=180s 2>/dev/null || true

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║   ✅ ORDER-MANAGEMENT V2 DEPLOYADO                                 ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}\n"

# Mostrar status após deploy
echo -e "${YELLOW}📊 Status DEPOIS do deploy:${NC}"
kubectl get pods -n ecommerce
echo ""

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}║   🎯 DEMONSTRAÇÃO: Circuit Breaker Configurado                     ║${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}║   Cenário:                                                         ║${NC}"
echo -e "${BLUE}║   1. order-management v2 tem um BUG (erro 500)                    ║${NC}"
echo -e "${BLUE}║   2. Circuit Breaker detecta falhas                               ║${NC}"
echo -e "${BLUE}║   3. TRIP! Tráfego redirecionado 100% para v1                     ║${NC}"
echo -e "${BLUE}║   4. Aplicação volta a funcionar normalmente                      ║${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}📚 Passos para DEMONSTRAR o Circuit Breaker:${NC}\n"

echo -e "${GREEN}FASE 1: Provocar o erro (gerar tráfego intenso)${NC}"
echo "   ./test-canary-visual.sh"
echo "   ${MAGENTA}→ Aplicação começará a retornar erros 500!${NC}"
echo ""

echo -e "${GREEN}FASE 2: Observar Circuit Breaker em ação no Kiali${NC}"
echo "   http://localhost:20001"
echo "   ${BLUE}→ Você verá conexões vermelhas (erros)${NC}"
echo "   ${BLUE}→ Circuit Breaker ativa (trip)${NC}"
echo "   ${BLUE}→ Tráfego redirecionado 100% para v1${NC}"
echo ""

echo -e "${GREEN}FASE 3: Verificar logs do pod com erro${NC}"
echo "   kubectl logs -n ecommerce -l app=order-management,version=v2 --tail=50"
echo "   ${MAGENTA}→ Verá mensagens de erro simulado${NC}"
echo ""

echo -e "${GREEN}FASE 4: Aplicação volta ao normal${NC}"
echo "   Continue gerando tráfego com ./test-canary-visual.sh"
echo "   ${GREEN}→ Kiali mostrará tráfego 100% em v1 (verde)${NC}"
echo "   ${GREEN}→ Aplicação funcionando perfeitamente!${NC}"
echo ""

echo -e "${YELLOW}💡 DICA: Abra os 4 dashboards lado a lado:${NC}"
echo "   • Kiali:      http://localhost:20001 (topologia)"
echo "   • Prometheus: http://localhost:9090  (métricas)"
echo "   • Grafana:    http://localhost:3000  (dashboards)"
echo "   • Jaeger:     http://localhost:16686 (tracing)"
echo ""

echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🎬 DEMONSTRAÇÃO COMPLETA CONFIGURADA!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}\n"

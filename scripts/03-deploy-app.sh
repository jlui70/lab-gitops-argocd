#!/bin/bash

# ============================================================================
# Script: 03-deploy-app.sh
# Descrição: Deploy da aplicação E-Commerce - VERSÃO V1 APENAS (para demo)
# Autor: DevOps Project
# Data: Dezembro 2025
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                                                                    ║"
echo "║   🚀 DEPLOY DA APLICAÇÃO E-COMMERCE                                ║"
echo "║                                                                    ║"
echo "║   Fase 3: Microserviços V1 APENAS (Cenário de Demonstração)       ║"
echo "║                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${MAGENTA}📢 MODO DEMONSTRAÇÃO:${NC}"
echo -e "${YELLOW}   Este script instala APENAS a versão V1 (sem Canary)${NC}"
echo -e "${YELLOW}   Permite demonstrar a evolução gradual:${NC}"
echo -e "${YELLOW}   v1 → Canary (80/20) → Circuit Breaker${NC}\n"

echo -e "${YELLOW}▶ Executando deploy da aplicação (v1 apenas)...${NC}"

cd "$PROJECT_ROOT/istio/install"
chmod +x deploy-v1-only.sh
./deploy-v1-only.sh

cd "$PROJECT_ROOT"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║   ✅ APLICAÇÃO V1 DEPLOYADA COM SUCESSO!                           ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📊 Microserviços deployados:${NC}"
echo "  • Frontend (React) ✅"
echo "  • Product Catalog v1 (100%) ✅"
echo "  • MongoDB Product Catalog ✅"
echo "  • Istio Gateway configurado ✅"
echo "  • Stack de Observabilidade ✅"
echo ""
echo -e "${YELLOW}🎯 Próximo passo:${NC}"
echo "  ./scripts/04-start-monitoring.sh"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}🎬 CENÁRIOS DE DEMONSTRAÇÃO DISPONÍVEIS:${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════════${NC}\n"
echo -e "${GREEN}Demo 1 - Canary Deployment (80% v1 / 20% v2):${NC}"
echo "  ./istio/install/demo-deploy-v2-canary.sh"
echo ""
echo -e "${GREEN}Demo 2 - Circuit Breaker (fallback 100% v1):${NC}"
echo "  ./istio/install/demo-deploy-circuit-breaker.sh"
echo ""

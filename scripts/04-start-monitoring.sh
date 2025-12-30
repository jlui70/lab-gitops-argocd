#!/bin/bash

# ============================================================================
# Script: 04-start-monitoring.sh
# Descrição: Inicia stack de observabilidade (Prometheus, Grafana, Kiali, Jaeger)
# Autor: DevOps Project
# Data: Dezembro 2025
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                                                                    ║"
echo "║   📊 INICIAR OBSERVABILIDADE                                       ║"
echo "║                                                                    ║"
echo "║   Fase 4: Monitoring Stack (Prometheus, Grafana, Kiali, Jaeger)   ║"
echo "║                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}▶ Iniciando ferramentas de observabilidade...${NC}"

chmod +x istio/install/start-monitoring.sh
cd istio/install
./start-monitoring.sh

cd "$PROJECT_ROOT"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║   ✅ STACK DE OBSERVABILIDADE INICIADA!                            ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}🌐 Acesse as ferramentas:${NC}"
echo ""
echo "  📊 Grafana:    http://localhost:3000"
echo "  📈 Prometheus: http://localhost:9090"
echo "  🗺️  Kiali:     http://localhost:20001"
echo "  🔍 Jaeger:     http://localhost:16686"
echo ""
echo -e "${YELLOW}💡 Dica:${NC} Mantenha os terminais abertos para acessar as ferramentas!"
echo ""

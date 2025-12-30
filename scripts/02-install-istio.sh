#!/bin/bash

# ============================================================================
# Script: 02-install-istio.sh
# Descrição: Instalação do Istio Service Mesh
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
echo "║   🕸️  INSTALAR ISTIO SERVICE MESH                                  ║"
echo "║                                                                    ║"
echo "║   Fase 2: Istio + Addons (Prometheus, Grafana, Kiali, Jaeger)    ║"
echo "║                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}▶ Executando instalação do Istio...${NC}"

cd "$PROJECT_ROOT/istio/install"
chmod +x install-istio.sh
./install-istio.sh

cd "$PROJECT_ROOT"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║   ✅ ISTIO SERVICE MESH INSTALADO!                                 ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📊 Componentes instalados:${NC}"
echo "  • Istiod (Control Plane) ✅"
echo "  • Istio Ingress Gateway ✅"
echo "  • Prometheus ✅"
echo "  • Grafana ✅"
echo "  • Kiali ✅"
echo "  • Jaeger ✅"
echo ""
echo -e "${YELLOW}🎯 Próximo passo:${NC}"
echo "  ./scripts/03-deploy-app.sh"
echo ""

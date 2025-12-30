#!/bin/bash

# Script para fazer limpeza completa do ambiente
# Autor: Seu Nome
# Data: 2025

echo "🧹 LIMPEZA COMPLETA DO AMBIENTE"
echo "================================"

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}⚠️  ATENÇÃO: Este script irá remover:${NC}"
echo "  • Todos os recursos do namespace ecommerce"
echo "  • Stack de observabilidade (Prometheus, Grafana, Kiali, Jaeger)"
echo "  • Istio Service Mesh completo"
echo ""
read -p "Deseja continuar? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operação cancelada."
    exit 1
fi

echo -e "\n${YELLOW}🧹 Iniciando limpeza...${NC}\n"

# 1. Parar port-forwards
echo -e "${YELLOW}1. Parando port-forwards...${NC}"
pkill -f 'kubectl port-forward' 2>/dev/null || true
echo -e "${GREEN}✅ Port-forwards encerrados${NC}\n"

# 2. Remover namespace ecommerce
echo -e "${YELLOW}2. Removendo namespace ecommerce...${NC}"
kubectl delete namespace ecommerce --ignore-not-found=true
echo -e "${GREEN}✅ Namespace ecommerce removido${NC}\n"

# 3. Remover observability stack
echo -e "${YELLOW}3. Removendo stack de observabilidade...${NC}"
kubectl delete -f manifests/06-observability/ --ignore-not-found=true 2>/dev/null || true
echo -e "${GREEN}✅ Observability stack removida${NC}\n"

# 4. Desinstalar Istio
echo -e "${YELLOW}4. Desinstalando Istio...${NC}"
istioctl uninstall --purge -y 2>/dev/null || echo "Istio já removido ou istioctl não encontrado"

# Remover namespace istio-system
kubectl delete namespace istio-system --ignore-not-found=true
echo -e "${GREEN}✅ Istio removido${NC}\n"

# 5. Remover CRDs do Istio
echo -e "${YELLOW}5. Removendo CRDs do Istio...${NC}"
kubectl get crd -o name | grep istio.io | xargs kubectl delete 2>/dev/null || true
echo -e "${GREEN}✅ CRDs removidos${NC}\n"

# 6. Verificação final
echo -e "${YELLOW}6. Verificando limpeza...${NC}"
echo "Namespaces restantes:"
kubectl get namespaces | grep -E '(istio|ecommerce)' || echo "  Nenhum namespace istio ou ecommerce encontrado ✅"

echo -e "\n${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 Limpeza concluída com sucesso!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📚 Para reinstalar:${NC}"
echo "  1. ./scripts/install-istio.sh"
echo "  2. ./scripts/deploy-all.sh"
echo "  3. ./scripts/start-monitoring.sh"

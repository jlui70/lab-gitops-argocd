#!/bin/bash

# Script para verificar status de todos os componentes
# Autor: Seu Nome
# Data: 2025

echo "🎯 STATUS DOS COMPONENTES ISTIO E-COMMERCE"
echo "=========================================="

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 1. Istio System
echo -e "\n${YELLOW}📦 1. ISTIO SYSTEM${NC}"
echo "─────────────────────"
kubectl get pods -n istio-system

# 2. E-commerce Namespace
echo -e "\n${YELLOW}📦 2. MICROSERVIÇOS (ecommerce namespace)${NC}"
echo "──────────────────────────────────────────"
kubectl get pods -n ecommerce

# 3. Services
echo -e "\n${YELLOW}🌐 3. SERVICES${NC}"
echo "──────────────────"
kubectl get svc -n ecommerce

# 4. Gateway e VirtualServices
echo -e "\n${YELLOW}🚪 4. ISTIO GATEWAY & VIRTUALSERVICES${NC}"
echo "────────────────────────────────────────"
kubectl get gateway,virtualservice -n ecommerce

# 5. DestinationRules
echo -e "\n${YELLOW}🎯 5. DESTINATION RULES${NC}"
echo "───────────────────────────"
kubectl get destinationrule -n ecommerce

# 6. LoadBalancer URL
echo -e "\n${YELLOW}🌍 6. URL DA APLICAÇÃO${NC}"
echo "────────────────────────"
GATEWAY_URL=$(kubectl get svc istio-ingressgateway -n istio-system \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

if [ -n "$GATEWAY_URL" ]; then
    echo -e "${GREEN}✅ http://$GATEWAY_URL${NC}"
else
    echo -e "${RED}⏳ Aguardando LoadBalancer...${NC}"
fi

# 7. Port-forwards ativos
echo -e "\n${YELLOW}🔌 7. PORT-FORWARDS ATIVOS${NC}"
echo "─────────────────────────────"

check_port() {
    local port=$1
    local name=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $name - http://localhost:$port${NC}"
    else
        echo -e "${RED}❌ $name - Porta $port não está ativa${NC}"
    fi
}

check_port 8000 "Grafana   "
check_port 9090 "Prometheus"
check_port 20001 "Kiali     "
check_port 16686 "Jaeger    "

# 8. Resumo
echo -e "\n${YELLOW}📊 8. RESUMO${NC}"
echo "─────────────"

TOTAL_PODS=$(kubectl get pods -n ecommerce --no-headers 2>/dev/null | wc -l)
RUNNING_PODS=$(kubectl get pods -n ecommerce --no-headers 2>/dev/null | grep Running | wc -l)

echo "Pods no namespace ecommerce: $RUNNING_PODS/$TOTAL_PODS Running"

ISTIO_PODS=$(kubectl get pods -n istio-system --no-headers 2>/dev/null | wc -l)
ISTIO_RUNNING=$(kubectl get pods -n istio-system --no-headers 2>/dev/null | grep Running | wc -l)

echo "Pods no namespace istio-system: $ISTIO_RUNNING/$ISTIO_PODS Running"

# 9. Comandos úteis
echo -e "\n${YELLOW}💡 COMANDOS ÚTEIS${NC}"
echo "───────────────────"
echo "• Logs de um pod:"
echo "  kubectl logs -n ecommerce <POD-NAME> -c <CONTAINER-NAME>"
echo ""
echo "• Ver eventos:"
echo "  kubectl get events -n ecommerce --sort-by='.lastTimestamp'"
echo ""
echo "• Reiniciar port-forwards:"
echo "  ./scripts/start-monitoring.sh"
echo ""
echo "• Limpar ambiente:"
echo "  ./scripts/cleanup.sh"

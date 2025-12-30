#!/bin/bash

set -e

echo "🔧 Inicializando Ferramentas de Monitoramento"
echo "============================================="

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}📋 Verificando ferramentas...${NC}"

# Verificar Prometheus
if kubectl get pods -n istio-system -l app.kubernetes.io/name=prometheus 2>/dev/null | grep -q Running; then
    echo -e "${GREEN}✅ prometheus está pronto${NC}"
else
    echo -e "${RED}❌ prometheus não encontrado${NC}"
    exit 1
fi

# Verificar Grafana
if kubectl get pods -n istio-system -l app.kubernetes.io/name=grafana 2>/dev/null | grep -q Running; then
    echo -e "${GREEN}✅ grafana está pronto${NC}"
else
    echo -e "${RED}❌ grafana não encontrado${NC}"
    exit 1
fi

# Verificar Kiali
if kubectl get pods -n istio-system -l app=kiali 2>/dev/null | grep -q Running; then
    echo -e "${GREEN}✅ kiali está pronto${NC}"
else
    echo -e "${RED}❌ kiali não encontrado${NC}"
    exit 1
fi

# Verificar Jaeger
if kubectl get pods -n istio-system -l app=jaeger 2>/dev/null | grep -q Running; then
    echo -e "${GREEN}✅ jaeger está pronto${NC}"
else
    echo -e "${RED}❌ jaeger não encontrado${NC}"
    exit 1
fi

echo -e "\n${YELLOW}🧹 Parando port-forwards anteriores...${NC}"
pkill -f 'kubectl port-forward' 2>/dev/null || true
sleep 2

echo -e "\n${YELLOW}🚀 Iniciando port-forwards...${NC}\n"

# Prometheus
echo "📊 Iniciando Prometheus na porta 9090..."
kubectl port-forward -n istio-system svc/prometheus 9090:9090 >/dev/null 2>&1 &
sleep 1

# Grafana
echo "📈 Iniciando Grafana na porta 3000..."
kubectl port-forward -n istio-system svc/grafana 3000:3000 >/dev/null 2>&1 &
sleep 1

# Kiali
echo "🕸️  Iniciando Kiali na porta 20001..."
kubectl port-forward -n istio-system svc/kiali 20001:20001 >/dev/null 2>&1 &
sleep 1

# Jaeger
echo "🔍 Iniciando Jaeger na porta 16686..."
kubectl port-forward -n istio-system svc/tracing 16686:80 >/dev/null 2>&1 &
sleep 2

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║   ✅ FERRAMENTAS DE OBSERVABILIDADE INICIADAS!                     ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}🌐 Acesse as ferramentas:${NC}"
echo ""
echo "  📊 Prometheus: http://localhost:9090"
echo "  📈 Grafana:    http://localhost:3000"
echo "  🕸️  Kiali:     http://localhost:20001"
echo "  🔍 Jaeger:     http://localhost:16686"
echo ""
echo -e "${YELLOW}💡 Dica:${NC} Mantenha este terminal aberto!"
echo -e "${YELLOW}⚠️  Para parar:${NC} pkill -f 'kubectl port-forward'"
echo ""

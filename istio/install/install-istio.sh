#!/bin/bash

# Script para instalar o Istio no cluster Kubernetes
# Autor: Seu Nome
# Data: 2025

set -e

echo "🚀 Instalação do Istio Service Mesh"
echo "===================================="

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar pré-requisitos
echo -e "${YELLOW}📋 Verificando pré-requisitos...${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl não encontrado. Instale kubectl primeiro.${NC}"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Não foi possível conectar ao cluster Kubernetes.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Pré-requisitos OK${NC}\n"

# Baixar Istio se não existir
ISTIO_VERSION="1.27.0"
ISTIO_DIR="istio-${ISTIO_VERSION}"

if [ ! -d "$ISTIO_DIR" ]; then
    echo -e "${YELLOW}📥 Baixando Istio ${ISTIO_VERSION}...${NC}"
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -
else
    echo -e "${GREEN}✅ Istio ${ISTIO_VERSION} já baixado${NC}"
fi

# Adicionar istioctl ao PATH temporariamente
export PATH="$PWD/$ISTIO_DIR/bin:$PATH"

# Verificar instalação do istioctl
if ! command -v istioctl &> /dev/null; then
    echo -e "${RED}❌ istioctl não encontrado${NC}"
    exit 1
fi

echo -e "${GREEN}✅ istioctl encontrado (versão: $(istioctl version --short --remote=false))${NC}\n"

# Pré-verificação do cluster
echo -e "${YELLOW}🔍 Executando pré-verificação do cluster...${NC}"
istioctl x precheck

# Instalar Istio
echo -e "\n${YELLOW}🔧 Instalando Istio com profile 'default'...${NC}"
istioctl install --set profile=default --set values.defaultRevision=default -y

# Instalar addons de observabilidade
echo -e "\n${YELLOW}📊 Instalando addons de observabilidade...${NC}"
kubectl apply -f $ISTIO_DIR/samples/addons/prometheus.yaml
kubectl apply -f $ISTIO_DIR/samples/addons/grafana.yaml
kubectl apply -f $ISTIO_DIR/samples/addons/kiali.yaml
kubectl apply -f $ISTIO_DIR/samples/addons/jaeger.yaml

echo -e "\n${YELLOW}⏳ Aguardando addons ficarem prontos...${NC}"
kubectl wait --for=condition=available --timeout=300s \
  deployment/prometheus -n istio-system 2>/dev/null || true
kubectl wait --for=condition=available --timeout=300s \
  deployment/grafana -n istio-system 2>/dev/null || true
kubectl wait --for=condition=available --timeout=300s \
  deployment/kiali -n istio-system 2>/dev/null || true
kubectl wait --for=condition=available --timeout=300s \
  deployment/jaeger -n istio-system 2>/dev/null || true

# Verificar instalação
echo -e "\n${YELLOW}✅ Verificando instalação...${NC}"
kubectl get pods -n istio-system

# Aguardar pods ficarem prontos
echo -e "\n${YELLOW}⏳ Aguardando pods do Istio ficarem prontos...${NC}"
kubectl wait --for=condition=ready pod --all -n istio-system --timeout=300s

# Tornar LoadBalancer internet-facing
echo -e "\n${YELLOW}🌐 Configurando LoadBalancer como internet-facing...${NC}"
kubectl annotate service istio-ingressgateway -n istio-system \
  service.beta.kubernetes.io/aws-load-balancer-scheme=internet-facing \
  --overwrite

echo -e "\n${GREEN}✅ Istio instalado com sucesso!${NC}"
echo -e "${GREEN}✅ Control plane (istiod): Running${NC}"
echo -e "${GREEN}✅ Ingress Gateway: Running${NC}"

# Obter URL do LoadBalancer
echo -e "\n${YELLOW}🔗 Obtendo URL do LoadBalancer...${NC}"
echo "Aguardando AWS provisionar o LoadBalancer (pode levar 2-3 minutos)..."

for i in {1..30}; do
    GATEWAY_URL=$(kubectl get svc istio-ingressgateway -n istio-system \
      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    
    if [ -n "$GATEWAY_URL" ]; then
        echo -e "${GREEN}✅ LoadBalancer URL: http://$GATEWAY_URL${NC}"
        break
    fi
    
    echo -n "."
    sleep 10
done

echo -e "\n${GREEN}🎉 Instalação concluída!${NC}"
echo -e "\n${YELLOW}📚 Próximos passos:${NC}"
echo "1. Criar namespace com injeção automática:"
echo "   kubectl apply -f manifests/01-namespace/"
echo ""
echo "2. Fazer deploy dos microserviços:"
echo "   ./scripts/deploy-all.sh"
echo ""
echo "3. Adicionar istioctl ao PATH permanentemente:"
echo "   export PATH=\"\$PATH:$PWD/$ISTIO_DIR/bin\""
echo "   echo 'export PATH=\"\$PATH:$PWD/$ISTIO_DIR/bin\"' >> ~/.bashrc"

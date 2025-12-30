#!/bin/bash

# ============================================================================
# Script: deploy-v2-configmap.sh  
# Descrição: Deploy v2.0 usando imagem rslim087 + nginx ConfigMap com sub_filter
# ============================================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}"
cat << "EOF"
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║   🚀 DEPLOY V2.0 - Via Nginx Sub_Filter                           ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}📝 Estratégia:${NC}"
echo "   ✅ Usa imagem rslim087/ecommerce-ui:latest (funciona 100%)"
echo "   ✅ Nginx ConfigMap com sub_filter injeta JavaScript"
echo "   ✅ Script muda 'Welcome...' para 'Welcome... - Versão 2.0 🚀'"
echo "   ✅ Zero rebuild, apenas ConfigMap + patch deployment"
echo ""

read -p "Deseja continuar? (s/N): " confirm
if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

# ============================================================================
# Step 1: Create ConfigMap with nginx config
# ============================================================================

echo ""
echo -e "${BLUE}[1/3] 📦 Criando ConfigMap com nginx.conf modificado${NC}"
echo ""

kubectl apply -f k8s-manifests/staging/ecommerce-ui-v2-nginx-configmap.yaml

echo -e "${GREEN}✅ ConfigMap criado: ecommerce-ui-v2-nginx${NC}"

# ============================================================================
# Step 2: Patch Deployment to mount ConfigMap
# ============================================================================

echo ""
echo -e "${BLUE}[2/3] 🔧 Atualizando Deployment para usar ConfigMap${NC}"
echo ""

kubectl patch deployment ecommerce-ui -n ecommerce-staging --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/volumes",
    "value": [
      {
        "name": "nginx-config",
        "configMap": {
          "name": "ecommerce-ui-v2-nginx"
        }
      }
    ]
  },
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/volumeMounts",
    "value": [
      {
        "name": "nginx-config",
        "mountPath": "/etc/nginx/conf.d/default.conf",
        "subPath": "default.conf"
      }
    ]
  }
]'

echo -e "${GREEN}✅ Deployment atualizado - nginx.conf montado via ConfigMap${NC}"

# ============================================================================
# Step 3: Wait for rollout
# ============================================================================

echo ""
echo -e "${BLUE}[3/3] ⏳ Aguardando rollout${NC}"
echo ""

kubectl rollout status deployment/ecommerce-ui -n ecommerce-staging --timeout=90s

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║   ✅ DEPLOY V2.0 CONCLUÍDO VIA CONFIGMAP!                          ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}🌐 Acesse agora:${NC}"
echo "   http://aea55d7dff98f43afa1b5a3ce75aa411-126944.us-east-1.elb.amazonaws.com/"
echo ""
echo -e "${YELLOW}✨ Você verá:${NC}"
echo "   'Welcome to the E-commerce App - Versão 2.0 🚀'"
echo ""
echo -e "${CYAN}💡 Como funciona:${NC}"
echo "   • Nginx sub_filter injeta JavaScript no HTML"
echo "   • Script muda o texto do H1 automaticamente"
echo "   • Imagem base rslim087 permanece intocada"
echo "   • Todas as APIs funcionam normalmente"
echo ""
echo -e "${GREEN}🎯 Rollback para v1.0:${NC}"
echo "   ./scripts/rollback-v2-configmap.sh"
echo ""

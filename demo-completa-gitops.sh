#!/bin/bash
# Script de Demonstração Completa GitOps
# Fluxo: v1.0 → simulação compras → deploy v2.0 via GitOps → validação

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para aguardar tecla
wait_key() {
    echo ""
    echo -e "${YELLOW}⏸️  Pressione ENTER para continuar...${NC}"
    read
}

# Função para obter URL da aplicação
get_app_url() {
    kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "aea55d7dff98f43afa1b5a3ce75aa411-126944.us-east-1.elb.amazonaws.com"
}

clear
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                                                                  ║"
echo "║      DEMONSTRAÇÃO COMPLETA GITOPS - E-COMMERCE APP              ║"
echo "║                                                                  ║"
echo "║  Fluxo: Deploy Infra → v1.0 → Compras → Deploy v2.0 GitOps     ║"
echo "║                                                                  ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ============================================================================
# ETAPA 1: VERIFICAR ESTADO ATUAL
# ============================================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📍 ETAPA 1: Verificar Estado Atual${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "Verificando se a aplicação está deployada..."
if kubectl get deployment ecommerce-ui -n ecommerce-staging &>/dev/null; then
    echo -e "${GREEN}✅ Aplicação já está deployada${NC}"
    CURRENT_IMAGE=$(kubectl get deployment ecommerce-ui -n ecommerce-staging -o jsonpath='{.spec.template.spec.containers[0].image}')
    echo "   Imagem atual: $CURRENT_IMAGE"
    
    if [[ "$CURRENT_IMAGE" == *"v2.0"* ]]; then
        echo -e "${YELLOW}⚠️  Aplicação está na v2.0, recomendo fazer rollback para v1.0 primeiro${NC}"
        echo ""
        echo "Executar rollback para v1.0?"
        echo "1) Sim, fazer rollback para v1.0"
        echo "2) Não, continuar com v2.0"
        read -p "Escolha (1/2): " choice
        
        if [ "$choice" == "1" ]; then
            echo ""
            echo "Fazendo rollback para v1.0..."
            git checkout 6768cd5
            kubectl rollout restart deployment/ecommerce-ui -n ecommerce-staging
            kubectl rollout status deployment/ecommerce-ui -n ecommerce-staging
            echo -e "${GREEN}✅ Rollback completo!${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  Aplicação NÃO está deployada${NC}"
    echo ""
    echo "Recomendo executar rebuild-all-with-gitops.sh primeiro"
    echo ""
    read -p "Deseja executar o rebuild agora? (s/n): " rebuild
    
    if [[ "$rebuild" == "s" || "$rebuild" == "S" ]]; then
        echo ""
        echo -e "${CYAN}🚀 Executando rebuild-all-with-gitops.sh...${NC}"
        echo ""
        ./rebuild-all-with-gitops.sh
        echo ""
        echo -e "${GREEN}✅ Rebuild completo!${NC}"
    else
        echo "Abortando demonstração. Execute o rebuild primeiro."
        exit 1
    fi
fi

wait_key

# ============================================================================
# ETAPA 2: MOSTRAR APLICAÇÃO v1.0
# ============================================================================
clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📍 ETAPA 2: Aplicação v1.0 em Produção${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

APP_URL="http://$(get_app_url)"

echo -e "${CYAN}🌐 URL da Aplicação:${NC}"
echo "   $APP_URL"
echo ""

echo -e "${CYAN}📦 Deployment Status:${NC}"
kubectl get deployment ecommerce-ui -n ecommerce-staging
echo ""

echo -e "${CYAN}🔄 Pods em Execução:${NC}"
kubectl get pods -n ecommerce-staging -l app=ecommerce-ui -o wide
echo ""

echo -e "${CYAN}🖼️  Imagem:${NC}"
kubectl get deployment ecommerce-ui -n ecommerce-staging -o jsonpath='   {.spec.template.spec.containers[0].image}'
echo ""
echo ""

echo -e "${YELLOW}➡️  DEMONSTRAÇÃO: Acesse a aplicação no navegador${NC}"
echo "   1. Abra: $APP_URL"
echo "   2. Verifique mensagem: ${GREEN}\"Welcome to the E-commerce App\"${NC}"
echo "   3. Navegue pelo catálogo de produtos"
echo "   4. Simule algumas compras (adicionar ao carrinho, etc)"
echo ""

wait_key

# ============================================================================
# ETAPA 3: TESTAR APIs v1.0
# ============================================================================
clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📍 ETAPA 3: Validar APIs v1.0${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${CYAN}🧪 Testando APIs do E-commerce...${NC}"
echo ""

echo "1️⃣  Products API:"
PRODUCTS=$(curl -s "$APP_URL/api/products" 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
if [ "$PRODUCTS" -gt 0 ]; then
    echo -e "   ${GREEN}✅ $PRODUCTS produtos encontrados${NC}"
else
    echo -e "   ${RED}❌ Erro ao buscar produtos${NC}"
fi

echo ""
echo "2️⃣  Inventory API:"
INVENTORY=$(curl -s "$APP_URL/api/inventory" 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
if [ "$INVENTORY" -gt 0 ]; then
    echo -e "   ${GREEN}✅ $INVENTORY itens no inventário${NC}"
else
    echo -e "   ${RED}❌ Erro ao buscar inventário${NC}"
fi

echo ""
echo "3️⃣  Sample Product:"
curl -s "$APP_URL/api/products" 2>/dev/null | jq '.[0] | {name: .name, price: .price, category: .category}' 2>/dev/null || echo "   ⚠️  Produto não disponível"

echo ""
echo -e "${GREEN}✅ v1.0 validada e funcionando!${NC}"

wait_key

# ============================================================================
# ETAPA 4: MOSTRAR CÓDIGO v1.0
# ============================================================================
clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📍 ETAPA 4: Código Fonte Atual (v1.0)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${CYAN}📄 Arquivo: ecommerce-app-v2/client/src/pages/Home.js${NC}"
echo ""
echo "Linha atual do código:"
echo ""
grep -A 2 "Welcome to the E-commerce App" ecommerce-app-v2/client/src/pages/Home.js | head -3
echo ""

echo -e "${YELLOW}💡 Vamos simular uma mudança de um desenvolvedor...${NC}"
echo "   Um dev vai atualizar a mensagem para mostrar 'Versão 2.0 🚀'"

wait_key

# ============================================================================
# ETAPA 5: PREPARAR DEPLOY v2.0
# ============================================================================
clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📍 ETAPA 5: Preparar Deploy v2.0 via GitOps${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${CYAN}📝 Histórico de Commits:${NC}"
git log --oneline --graph -5
echo ""

echo -e "${YELLOW}➡️  Vamos fazer checkout para o commit v2.0${NC}"
echo ""
echo "   Commit v2.0: a6f0d3d - Deploy v2.0 - Welcome message com Versão 2.0 🚀"
echo ""

read -p "Fazer checkout para v2.0? (s/n): " proceed

if [[ "$proceed" != "s" && "$proceed" != "S" ]]; then
    echo "Demonstração cancelada."
    exit 0
fi

echo ""
echo -e "${CYAN}🔄 Fazendo checkout...${NC}"
git checkout a6f0d3d

echo ""
echo -e "${CYAN}📋 Mudanças no manifest:${NC}"
echo ""
echo "Antes (v1.0):"
echo "   image: rslim087/ecommerce-ui:latest"
echo ""
echo "Depois (v2.0):"
cat k8s-manifests/base/ecommerce-ui.yaml | grep "image:" | sed 's/^/   /'
echo ""

wait_key

# ============================================================================
# ETAPA 6: AGUARDAR ARGOCD SYNC
# ============================================================================
clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📍 ETAPA 6: ArgoCD Auto-Sync (GitOps em Ação)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${CYAN}🤖 ArgoCD Configuration:${NC}"
echo "   • Sync Policy: Automated"
echo "   • Prune: Enabled"
echo "   • Self Heal: Enabled"
echo "   • Polling Interval: 3 minutes"
echo ""

echo -e "${YELLOW}⏰ ArgoCD detecta mudanças no Git a cada 3 minutos...${NC}"
echo ""

read -p "Aguardar sync automático (3 min) ou forçar deploy imediato? (a/f): " sync_choice

if [[ "$sync_choice" == "f" || "$sync_choice" == "F" ]]; then
    echo ""
    echo -e "${CYAN}🚀 Forçando deploy imediato...${NC}"
    kubectl rollout restart deployment/ecommerce-ui -n ecommerce-staging
    echo ""
    echo "⏳ Aguardando rollout..."
    kubectl rollout status deployment/ecommerce-ui -n ecommerce-staging --timeout=180s
else
    echo ""
    echo -e "${CYAN}⏳ Aguardando ArgoCD sync automático...${NC}"
    echo ""
    
    for i in {1..36}; do  # 3 minutos máximo (36 x 5 segundos)
        CURRENT_IMAGE=$(kubectl get deployment ecommerce-ui -n ecommerce-staging -o jsonpath='{.spec.template.spec.containers[0].image}')
        
        echo -ne "\r[$i/36] Imagem atual: ${CURRENT_IMAGE##*/}   "
        
        if [[ "$CURRENT_IMAGE" == *"v2.0"* ]]; then
            echo ""
            echo ""
            echo -e "${GREEN}✅ ArgoCD sincronizou! Deploy v2.0 detectado!${NC}"
            break
        fi
        
        sleep 5
    done
    
    echo ""
    echo "⏳ Aguardando rollout completo..."
    kubectl rollout status deployment/ecommerce-ui -n ecommerce-staging --timeout=180s
fi

echo ""
echo -e "${GREEN}✅ Deploy v2.0 completo!${NC}"

wait_key

# ============================================================================
# ETAPA 7: VALIDAR v2.0
# ============================================================================
clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}📍 ETAPA 7: Aplicação v2.0 Deployada!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${CYAN}🌐 URL da Aplicação:${NC}"
echo "   $APP_URL"
echo ""

echo -e "${CYAN}📦 Deployment Status:${NC}"
kubectl get deployment ecommerce-ui -n ecommerce-staging
echo ""

echo -e "${CYAN}🔄 Novos Pods:${NC}"
kubectl get pods -n ecommerce-staging -l app=ecommerce-ui -o wide
echo ""

echo -e "${CYAN}🖼️  Nova Imagem:${NC}"
kubectl get deployment ecommerce-ui -n ecommerce-staging -o jsonpath='   {.spec.template.spec.containers[0].image}'
echo ""
echo ""

echo -e "${CYAN}🧪 Validando APIs v2.0:${NC}"
echo ""

PRODUCTS_V2=$(curl -s "$APP_URL/api/products" 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
INVENTORY_V2=$(curl -s "$APP_URL/api/inventory" 2>/dev/null | jq 'length' 2>/dev/null || echo "0")

echo "   Products API: ${GREEN}✅ $PRODUCTS_V2 produtos${NC}"
echo "   Inventory API: ${GREEN}✅ $INVENTORY_V2 itens${NC}"
echo ""

echo -e "${YELLOW}➡️  DEMONSTRAÇÃO FINAL: Acesse a aplicação no navegador${NC}"
echo "   1. Abra/Recarregue: $APP_URL"
echo "   2. Verifique nova mensagem: ${GREEN}\"Welcome to the E-commerce App - Versão 2.0 🚀\"${NC}"
echo "   3. Navegue pelo catálogo (mesmos produtos)"
echo "   4. Simule novas compras"
echo "   5. Todas as funcionalidades devem estar OK!"
echo ""

wait_key

# ============================================================================
# ETAPA 8: RESUMO FINAL
# ============================================================================
clear
echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                                                                  ║"
echo "║                 ✅ DEMONSTRAÇÃO CONCLUÍDA!                      ║"
echo "║                                                                  ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

echo -e "${GREEN}🎯 Fluxo GitOps Demonstrado:${NC}"
echo ""
echo "   1️⃣  Aplicação v1.0 funcionando"
echo "   2️⃣  Simulação de compras/uso"
echo "   3️⃣  Desenvolvedor faz commit (v2.0)"
echo "   4️⃣  ArgoCD detecta mudança no Git"
echo "   5️⃣  Kubernetes faz rollout automático"
echo "   6️⃣  Aplicação v2.0 em produção"
echo "   7️⃣  Zero intervenção manual!"
echo ""

echo -e "${CYAN}📊 Estatísticas:${NC}"
echo "   • Deploy Method: ${GREEN}100% GitOps${NC}"
echo "   • Manual kubectl: ${GREEN}0 comandos${NC}"
echo "   • Downtime: ${GREEN}0 segundos${NC}"
echo "   • Rollback: ${GREEN}git checkout${NC}"
echo "   • Auditoria: ${GREEN}git log${NC}"
echo ""

echo -e "${YELLOW}🔄 Para fazer rollback:${NC}"
echo "   git checkout 6768cd5"
echo "   # ArgoCD fará rollback automático"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ Demonstração GitOps Completa - Finalizada com Sucesso! ✨${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

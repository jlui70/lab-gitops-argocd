#!/bin/bash
# Script de Demonstração GitOps - Deploy v1.0 → v2.0
# Este script demonstra o processo completo de GitOps

set -e

APP_URL="http://aea55d7dff98f43afa1b5a3ce75aa411-126944.us-east-1.elb.amazonaws.com/"
NAMESPACE="ecommerce-staging"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║         DEMONSTRAÇÃO GITOPS - E-COMMERCE v1.0 → v2.0          ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# Função para aguardar tecla
wait_key() {
    echo ""
    echo "⏸️  Pressione ENTER para continuar..."
    read
}

# Passo 1: Mostrar v1.0
echo "📍 PASSO 1: Aplicação v1.0 em Produção"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "URL: $APP_URL"
kubectl get deployment ecommerce-ui -n $NAMESPACE -o jsonpath='Imagem atual: {.spec.template.spec.containers[0].image}'
echo ""
echo "Pods em execução:"
kubectl get pods -n $NAMESPACE -l app=ecommerce-ui -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,AGE:.metadata.creationTimestamp
wait_key

# Passo 2: Mostrar código v1.0
echo ""
echo "📍 PASSO 2: Código Atual (v1.0)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Arquivo: ecommerce-app-v2/client/src/pages/Home.js"
echo ""
grep -A 2 "Welcome to the E-commerce App" /home/luiz7/Projects/backup_github/istio-eks-terraform-gitops-argocd/ecommerce-app-v2/client/src/pages/Home.js | head -3
wait_key

# Passo 3: Build e Push v2.0
echo ""
echo "📍 PASSO 3: Build e Push Imagem v2.0"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Obs: Build já foi feito anteriormente. Mostrando detalhes:"
echo ""
docker images | grep ecommerce-ui | grep v2.0
echo ""
echo "Imagem já enviada para ECR:"
echo "794038226274.dkr.ecr.us-east-1.amazonaws.com/ecommerce/ecommerce-ui:v2.0"
wait_key

# Passo 4: Atualizar manifest Git
echo ""
echo "📍 PASSO 4: Atualizar Manifest no Git"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Arquivo: k8s-manifests/base/ecommerce-ui.yaml"
echo ""
echo "Verificando últimos commits:"
cd /home/luiz7/Projects/backup_github/istio-eks-terraform-gitops-argocd
git log --oneline --graph -3
echo ""
echo "✅ Commit v2.0 já está no repositório Git"
wait_key

# Passo 5: Aguardar ArgoCD Sync
echo ""
echo "📍 PASSO 5: ArgoCD Detecta Mudança (Auto-Sync)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ArgoCD faz polling do Git a cada 3 minutos"
echo "Verificando status atual..."
echo ""
kubectl get application ecommerce-staging -n argocd -o jsonpath='Status: {.status.sync.status}
Revisão Git: {.status.sync.revision}
'
wait_key

# Passo 6: Acompanhar Rollout
echo ""
echo "📍 PASSO 6: Kubernetes Rollout Automático"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Deployment sendo atualizado..."
echo ""
kubectl get deployment ecommerce-ui -n $NAMESPACE -o jsonpath='Imagem nova: {.spec.template.spec.containers[0].image}'
echo ""
echo ""
kubectl get pods -n $NAMESPACE -l app=ecommerce-ui -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,AGE:.metadata.creationTimestamp
wait_key

# Passo 7: Testar v2.0
echo ""
echo "📍 PASSO 7: Validação v2.0"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testando APIs..."
echo ""
echo "✅ Products API:"
curl -s $APP_URL/api/products 2>/dev/null | jq 'if type == "array" then "   " + (length | tostring) + " products disponíveis" else "   Erro" end' 2>/dev/null || echo "   ⚠️  API offline"
echo ""
echo "✅ Inventory API:"
curl -s $APP_URL/api/inventory 2>/dev/null | jq 'if type == "array" then "   " + (length | tostring) + " itens no inventário" else "   Erro" end' 2>/dev/null || echo "   ⚠️  API offline"
echo ""
echo "🌐 Acesse a aplicação: $APP_URL"
echo "   Verifique a mensagem: 'Welcome to the E-commerce App - Versão 2.0 🚀'"
wait_key

# Resumo Final
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    DEMONSTRAÇÃO CONCLUÍDA ✅                     ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Fluxo GitOps Completo:"
echo "  1️⃣  Código modificado (Home.js)"
echo "  2️⃣  Build da imagem v2.0"
echo "  3️⃣  Push para ECR"
echo "  4️⃣  Commit no Git (manifest)"
echo "  5️⃣  ArgoCD detecta mudança (auto)"
echo "  6️⃣  Kubernetes faz rollout (auto)"
echo "  7️⃣  Aplicação v2.0 em produção 🚀"
echo ""
echo "🎯 Zero intervenção manual no cluster!"
echo "🎯 100% automatizado via GitOps!"
echo ""

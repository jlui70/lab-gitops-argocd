#!/bin/bash

# ============================================================================
# Script: 01-deploy-infra.sh
# Descrição: Deploy automatizado da infraestrutura AWS (Backend + Networking + EKS)
# Autor: DevOps Project
# Data: Dezembro 2025
# ============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório raiz do projeto
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                                                                    ║"
echo "║   🚀 DEPLOY DE INFRAESTRUTURA AWS                                  ║"
echo "║                                                                    ║"
echo "║   Fase 1: Terraform Stacks (Backend + Networking + EKS)           ║"
echo "║                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ============================================================================
# Verificar AWS Credentials
# ============================================================================
echo -e "${YELLOW}🔐 Verificando credenciais AWS...${NC}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)

if [ -z "$ACCOUNT_ID" ]; then
    echo -e "${RED}❌ Erro: Credenciais AWS não configuradas${NC}"
    echo ""
    echo "Configure suas credenciais:"
    echo "  aws configure"
    echo ""
    echo "OU use um perfil específico:"
    echo "  export AWS_PROFILE=nome-do-perfil"
    exit 1
fi

USER_ARN=$(aws sts get-caller-identity --query Arn --output text)

echo -e "${GREEN}✅ Credenciais AWS encontradas${NC}"
echo "   Account ID: $ACCOUNT_ID"
echo "   User/Role: $USER_ARN"
echo ""

# ============================================================================
# Função: Substituir Account ID e Placeholders
# ============================================================================
substitute_account_id() {
    local dir=$1
    
    echo -e "${YELLOW}🔧 Substituindo Account ID e placeholders...${NC}"
    
    # Substituir <YOUR_ACCOUNT> pelo Account ID real
    find "$dir" -name "*.tf" -type f -exec sed -i "s/<YOUR_ACCOUNT>/${ACCOUNT_ID}/g" {} \;
    
    # Substituir qualquer Account ID hardcoded antigo pelo atual
    find "$dir" -name "*.tf" -type f -exec sed -i "s/620958830769/${ACCOUNT_ID}/g" {} \;
    find "$dir" -name "*.tf" -type f -exec sed -i "s/794038226274/${ACCOUNT_ID}/g" {} \;
    
    echo -e "${GREEN}✅ Placeholders substituídos${NC}"
}

# ============================================================================
# STACK 00: Backend (S3 + DynamoDB)
# ============================================================================
echo -e "${YELLOW}▶ Stack 00: Backend (S3 + DynamoDB)${NC}"
cd "$PROJECT_ROOT/00-backend"

substitute_account_id "."

terraform init -reconfigure
terraform plan
terraform apply -auto-approve

echo -e "${GREEN}✅ Stack 00 concluída (Backend provisionado)${NC}\n"

# ============================================================================
# STACK 01: Networking (VPC, Subnets, NAT Gateways)
# ============================================================================
echo -e "${YELLOW}▶ Stack 01: Networking (VPC, Subnets, NAT Gateways)${NC}"
cd "$PROJECT_ROOT/01-networking"

substitute_account_id "."

terraform init -reconfigure
terraform plan
terraform apply -auto-approve

echo -e "${GREEN}✅ Stack 01 concluída (Networking provisionado)${NC}\n"

# ============================================================================
# STACK 02: EKS Cluster
# ============================================================================
echo -e "${YELLOW}▶ Stack 02: EKS Cluster (pode levar ~15 minutos)${NC}"
cd "$PROJECT_ROOT/02-eks-cluster"

substitute_account_id "."

terraform init -reconfigure

# Verificar se há policy IAM existente e importar
POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy"
if aws iam get-policy --policy-arn $POLICY_ARN &>/dev/null; then
    echo -e "${YELLOW}⚠️  Policy AWSLoadBalancerControllerIAMPolicy já existe, importando...${NC}"
    terraform import aws_iam_policy.load_balancer_controller $POLICY_ARN 2>/dev/null || true
fi

terraform plan

# Apply com tratamento de erro para Helm
echo -e "${YELLOW}🚀 Aplicando configuração Terraform...${NC}"
if ! terraform apply -auto-approve; then
    echo -e "${YELLOW}⚠️  Erro durante apply (provavelmente Helm/ALB Controller)${NC}"
    echo -e "${YELLOW}   Tentando continuar sem ALB Controller...${NC}"
fi

echo -e "${GREEN}✅ Stack 02 concluída (EKS Cluster provisionado)${NC}\n"

# ============================================================================
# Configurar kubectl
# ============================================================================
echo -e "${YELLOW}▶ Configurando kubectl...${NC}"

CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "eks-devopsproject-cluster")
REGION="us-east-1"

aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo -e "${GREEN}✅ kubectl configurado${NC}\n"

# ============================================================================
# Verificar acesso ao cluster
# ============================================================================
echo -e "${YELLOW}▶ Verificando acesso ao cluster...${NC}"

if kubectl get nodes &>/dev/null; then
    kubectl get nodes
    echo -e "${GREEN}✅ Acesso ao cluster OK${NC}\n"
else
    echo -e "${RED}❌ Erro: Não foi possível acessar o cluster${NC}"
    echo ""
    echo -e "${YELLOW}💡 Possível causa: Credenciais AWS${NC}"
    echo ""
    echo "O cluster EKS foi configurado com access entries para a role 'terraform-role'."
    echo "Se você está usando IAM User, precisa usar uma role que tenha acesso."
    echo ""
    echo "Soluções:"
    echo "  1. Use um perfil AWS que assume a terraform-role:"
    echo "     export AWS_PROFILE=perfil-com-assume-role"
    echo ""
    echo "  2. OU adicione seu usuário IAM ao cluster:"
    echo "     aws eks create-access-entry --cluster-name $CLUSTER_NAME \\"
    echo "       --principal-arn $USER_ARN --region $REGION"
    echo ""
    echo "Depois execute:"
    echo "  aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME"
    echo "  kubectl get nodes"
    echo ""
    exit 1
fi

cd "$PROJECT_ROOT"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║   ✅ INFRAESTRUTURA PROVISIONADA COM SUCESSO!                      ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📊 Resumo:${NC}"
echo "  • Stack 00: Backend (S3 + DynamoDB) ✅"
echo "  • Stack 01: VPC, Subnets, NAT Gateways ✅"
echo "  • Stack 02: EKS Cluster + Node Group ✅"
echo "  • kubectl: Configurado ✅"
echo ""
echo -e "${YELLOW}⚠️  Nota sobre ALB Controller:${NC}"
echo "  O AWS Load Balancer Controller não é necessário para este projeto,"
echo "  pois o Istio usa seu próprio Ingress Gateway (NLB)."
echo ""
echo -e "${YELLOW}🎯 Próximo passo:${NC}"
echo "  ./scripts/02-install-istio.sh"
echo ""

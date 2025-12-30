#!/bin/bash

# ============================================================================
# Script: destroy-all.sh
# Descrição: Destroy completo de toda a infraestrutura
# Autor: DevOps Project
# Data: Dezembro 2025
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# ============================================================================
# Verificações iniciais
# ============================================================================

echo -e "${BLUE}🔍 Verificando AWS credentials...${NC}"
if ! aws sts get-caller-identity &>/dev/null; then
    echo -e "${RED}❌ Erro: Credenciais AWS não configuradas${NC}"
    echo "Configure: aws configure --profile SEU_PERFIL"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
echo -e "${GREEN}✅ AWS Account: $ACCOUNT_ID | Region: $REGION${NC}"

# ============================================================================
# Confirmação
# ============================================================================

echo -e "${RED}"
echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║                                                                    ║"
echo "║   ⚠️  DESTRUIR TODA A INFRAESTRUTURA                               ║"
echo "║                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${YELLOW}⚠️  Este script irá destruir:${NC}"
echo "   • Namespace ecommerce (aplicação)"
echo "   • Istio Service Mesh"
echo "   • EKS Cluster + Node Group"
echo "   • VPC + Subnets + NAT Gateways"
echo "   • (Opcional) S3 Backend + DynamoDB"
echo ""
read -p "Tem certeza que deseja continuar? (s/N): " confirm

if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

# ============================================================================
# Step 1: Deletar aplicação do Kubernetes
# ============================================================================

echo -e "\n${YELLOW}[1/5] 🗑️  Deletando aplicação do Kubernetes...${NC}"

# Parar port-forwards antes
pkill -f 'kubectl port-forward' 2>/dev/null || true

# Deletar ArgoCD namespace (GitOps)
if kubectl get namespace argocd &>/dev/null; then
    kubectl delete namespace argocd --timeout=5m
    echo -e "${GREEN}✅ Namespace argocd deletado${NC}"
else
    echo -e "${BLUE}ℹ️  Namespace argocd já não existe${NC}"
fi

# Deletar namespaces da aplicação
for ns in ecommerce ecommerce-staging ecommerce-production; do
    if kubectl get namespace $ns &>/dev/null; then
        kubectl delete namespace $ns --timeout=5m
        echo -e "${GREEN}✅ Namespace $ns deletado${NC}"
    else
        echo -e "${BLUE}ℹ️  Namespace $ns já não existe${NC}"
    fi
done

# ============================================================================
# Step 2: Deletar Istio
# ============================================================================

echo -e "\n${YELLOW}[2/5] 🗑️  Removendo Istio...${NC}"

# Verificar se istioctl está instalado
if command -v istioctl &>/dev/null; then
    istioctl uninstall --purge -y 2>/dev/null || true
    echo -e "${GREEN}✅ Istio uninstall executado${NC}"
else
    echo -e "${BLUE}ℹ️  istioctl não encontrado, deletando via kubectl${NC}"
fi

# Deletar namespace istio-system
if kubectl get namespace istio-system &>/dev/null; then
    kubectl delete namespace istio-system --timeout=5m
    echo -e "${GREEN}✅ Namespace istio-system deletado${NC}"
else
    echo -e "${BLUE}ℹ️  Namespace istio-system já não existe${NC}"
fi

# Aguardar e limpar LoadBalancers
echo -e "${BLUE}⏳ Aguardando remoção de LoadBalancers...${NC}"
sleep 30

# Deletar Load Balancers órfãos
echo -e "${BLUE}🔍 Verificando Load Balancers órfãos...${NC}"
LB_ARNS=$(aws elbv2 describe-load-balancers --region $REGION \
    --query 'LoadBalancers[?contains(LoadBalancerName, `istio`) || contains(LoadBalancerName, `k8s`)].LoadBalancerArn' \
    --output text 2>/dev/null || echo "")

if [ -n "$LB_ARNS" ]; then
    echo -e "${YELLOW}⚠️  Deletando Load Balancers órfãos...${NC}"
    for lb_arn in $LB_ARNS; do
        echo "Deletando: $lb_arn"
        aws elbv2 delete-load-balancer --load-balancer-arn "$lb_arn" --region $REGION || true
    done
    echo "Aguardando LoadBalancers serem deletados (60s)..."
    sleep 60
fi

# Deletar Classic Load Balancers (ELB)
ELB_NAMES=$(aws elb describe-load-balancers --region $REGION \
    --query 'LoadBalancerDescriptions[?contains(LoadBalancerName, `istio`) || contains(LoadBalancerName, `k8s`)].LoadBalancerName' \
    --output text 2>/dev/null || echo "")

if [ -n "$ELB_NAMES" ]; then
    echo -e "${YELLOW}⚠️  Deletando Classic Load Balancers órfãos...${NC}"
    for elb_name in $ELB_NAMES; do
        echo "Deletando: $elb_name"
        aws elb delete-load-balancer --load-balancer-name "$elb_name" --region $REGION || true
    done
    sleep 30
fi

echo -e "${GREEN}✅ Istio removido${NC}"

# ============================================================================
# Step 3: Destruir Stack 02 (EKS Cluster)
# ============================================================================

echo -e "\n${YELLOW}[3/5] 🗑️  Destruindo Stack 02 (EKS Cluster)...${NC}"
cd "$PROJECT_ROOT/02-eks-cluster"

CLUSTER_NAME="eks-devopsproject-cluster"

# Verificar se cluster existe
if aws eks describe-cluster --name $CLUSTER_NAME --region $REGION &>/dev/null; then
    
    # Tentar destroy via Terraform
    if terraform destroy -auto-approve; then
        echo -e "${GREEN}✅ Stack 02 destruída via Terraform${NC}"
    else
        echo -e "${YELLOW}⚠️  Terraform destroy falhou, tentando via AWS CLI...${NC}"
        
        # Deletar node group via CLI
        NODEGROUP=$(aws eks list-nodegroups --cluster-name $CLUSTER_NAME --region $REGION --query 'nodegroups[0]' --output text 2>/dev/null || echo "")
        
        if [ -n "$NODEGROUP" ] && [ "$NODEGROUP" != "None" ]; then
            echo "Deletando node group: $NODEGROUP"
            aws eks delete-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $NODEGROUP --region $REGION
            echo "Aguardando node group ser deletado (pode demorar 5-10 minutos)..."
            aws eks wait nodegroup-deleted --cluster-name $CLUSTER_NAME --nodegroup-name $NODEGROUP --region $REGION
            echo -e "${GREEN}✅ Node group deletado${NC}"
        fi
        
        # Deletar cluster
        echo "Deletando cluster: $CLUSTER_NAME"
        aws eks delete-cluster --name $CLUSTER_NAME --region $REGION
        echo "Aguardando cluster ser deletado (pode demorar 5-10 minutos)..."
        aws eks wait cluster-deleted --name $CLUSTER_NAME --region $REGION
        echo -e "${GREEN}✅ Cluster deletado${NC}"
        
        # Limpar state do Terraform
        terraform destroy -auto-approve 2>/dev/null || true
        echo -e "${GREEN}✅ Stack 02 destruída via AWS CLI${NC}"
    fi
else
    echo -e "${BLUE}ℹ️  Cluster EKS já não existe${NC}"
    # Tentar limpar state mesmo assim
    terraform destroy -auto-approve 2>/dev/null || true
fi

# ============================================================================
# Step 4: Destruir Stack 01 (Networking)
# ============================================================================

echo -e "\n${YELLOW}[4/5] 🗑️  Destruindo Stack 01 (Networking)...${NC}"
cd "$PROJECT_ROOT/01-networking"

# Limpar ENIs órfãs (comum quando LoadBalancers não são deletados corretamente)
echo -e "${BLUE}🔍 Verificando ENIs (Network Interfaces) órfãs...${NC}"
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "")

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "null" ]; then
    echo "VPC ID: $VPC_ID"
    
    # Listar ENIs disponíveis na VPC
    ENI_IDS=$(aws ec2 describe-network-interfaces \
        --region $REGION \
        --filters "Name=vpc-id,Values=$VPC_ID" "Name=status,Values=available" \
        --query 'NetworkInterfaces[].NetworkInterfaceId' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$ENI_IDS" ]; then
        echo -e "${YELLOW}⚠️  Deletando ENIs órfãs...${NC}"
        for eni_id in $ENI_IDS; do
            echo "Deletando ENI: $eni_id"
            aws ec2 delete-network-interface --network-interface-id "$eni_id" --region $REGION 2>/dev/null || true
        done
        sleep 10
    else
        echo -e "${GREEN}✅ Nenhuma ENI órfã encontrada${NC}"
    fi
fi

# Verificar se existem NAT Gateways órfãos
echo -e "${BLUE}🔍 Verificando NAT Gateways...${NC}"
NAT_IDS=$(aws ec2 describe-nat-gateways \
    --region $REGION \
    --filter "Name=state,Values=available,pending,deleting" \
    --query 'NatGateways[?Tags[?Key==`Project` && Value==`eks-devopsproject`]].NatGatewayId' \
    --output text 2>/dev/null || echo "")

if [ -n "$NAT_IDS" ]; then
    echo -e "${YELLOW}⚠️  Deletando NAT Gateways órfãos via AWS CLI...${NC}"
    for nat_id in $NAT_IDS; do
        echo "Deletando NAT Gateway: $nat_id"
        aws ec2 delete-nat-gateway --nat-gateway-id $nat_id --region $REGION || true
    done
    echo "Aguardando NAT Gateways serem deletados (90s)..."
    sleep 90
fi

# Destroy via Terraform (com retry)
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo -e "${BLUE}Tentativa $((RETRY_COUNT + 1))/$MAX_RETRIES de destroy via Terraform...${NC}"
    
    if terraform destroy -auto-approve; then
        echo -e "${GREEN}✅ Stack 01 destruída${NC}"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo -e "${YELLOW}⚠️  Falha no destroy. Aguardando 30s antes de retry...${NC}"
            sleep 30
            
            # Tentar limpar ENIs novamente
            if [ -n "$VPC_ID" ]; then
                ENI_IDS=$(aws ec2 describe-network-interfaces \
                    --region $REGION \
                    --filters "Name=vpc-id,Values=$VPC_ID" "Name=status,Values=available" \
                    --query 'NetworkInterfaces[].NetworkInterfaceId' \
                    --output text 2>/dev/null || echo "")
                
                if [ -n "$ENI_IDS" ]; then
                    echo -e "${YELLOW}Tentando remover ENIs novamente...${NC}"
                    for eni_id in $ENI_IDS; do
                        aws ec2 delete-network-interface --network-interface-id "$eni_id" --region $REGION 2>/dev/null || true
                    done
                    sleep 10
                fi
            fi
        else
            echo -e "${RED}❌ Erro ao destruir Stack 01 após $MAX_RETRIES tentativas${NC}"
            echo ""
            echo -e "${YELLOW}Tentando limpeza forçada com script especializado...${NC}"
            
            # Usar script de limpeza forçada se disponível
            if [ -f "$PROJECT_ROOT/force-cleanup-vpc.sh" ] && [ -n "$VPC_ID" ]; then
                echo -e "${BLUE}Executando force-cleanup-vpc.sh...${NC}"
                if "$PROJECT_ROOT/force-cleanup-vpc.sh" "$VPC_ID" "$REGION" <<< "s"; then
                    echo -e "${GREEN}✅ VPC limpa via script especializado${NC}"
                    # Tentar terraform destroy novamente para limpar state
                    terraform destroy -auto-approve 2>/dev/null || true
                    echo -e "${GREEN}✅ Stack 01 destruída${NC}"
                    break
                fi
            fi
            
            echo ""
            echo -e "${RED}Soluções manuais:${NC}"
            echo "1. Execute o script de limpeza forçada:"
            echo "   ./force-cleanup-vpc.sh $VPC_ID"
            echo ""
            echo "2. Ou verifique recursos manualmente:"
            echo "   # Load Balancers"
            echo "   aws elbv2 describe-load-balancers --region $REGION"
            echo ""
            echo "   # ENIs"
            echo "   aws ec2 describe-network-interfaces --region $REGION --filters Name=vpc-id,Values=$VPC_ID"
            echo ""
            echo "   # Security Groups"
            echo "   aws ec2 describe-security-groups --region $REGION --filters Name=vpc-id,Values=$VPC_ID"
            echo ""
            echo "3. Após limpar, execute:"
            echo "   cd 01-networking && terraform destroy -auto-approve"
            exit 1
        fi
    fi
done

# ============================================================================
# Step 5: Limpar repositórios ECR
# ============================================================================

echo -e "\n${YELLOW}[5/6] 🗑️  Limpando repositórios ECR...${NC}"

REPOS=$(aws ecr describe-repositories \
    --region $REGION \
    --query 'repositories[?starts_with(repositoryName, `ecommerce/`)].repositoryName' \
    --output text 2>/dev/null || echo "")

if [ -n "$REPOS" ]; then
    echo -e "${BLUE}Repositórios ECR encontrados:${NC}"
    for repo in $REPOS; do
        echo "  - $repo"
    done
    
    echo ""
    read -p "Deletar repositórios ECR? (s/N): " delete_ecr
    
    if [[ "$delete_ecr" =~ ^[Ss]$ ]]; then
        for repo in $REPOS; do
            echo "  → Deletando: $repo"
            aws ecr delete-repository \
                --region $REGION \
                --repository-name "$repo" \
                --force 2>/dev/null && echo -e "${GREEN}    ✅ Deletado${NC}" || echo -e "${YELLOW}    ⚠️  Erro (pode já estar deletado)${NC}"
        done
        echo -e "${GREEN}✅ Repositórios ECR removidos${NC}"
    else
        echo -e "${BLUE}ℹ️  Repositórios ECR preservados${NC}"
    fi
else
    echo -e "${BLUE}ℹ️  Nenhum repositório ECR encontrado${NC}"
fi

# ============================================================================
# Step 6: Destruir Stack 00 (Backend) - OPCIONAL
# ============================================================================

echo -e "\n${YELLOW}[6/6] 🗑️  Backend (S3 + DynamoDB)...${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE: Destruir o backend remove o Terraform state!${NC}"
echo "   Você NÃO poderá fazer 'terraform destroy' posteriormente."
echo "   Apenas destrua se não precisar mais do projeto."
echo ""
read -p "Deseja destruir o Backend? (s/N): " destroy_backend

if [[ "$destroy_backend" =~ ^[Ss]$ ]]; then
    echo -e "\n${YELLOW}Destruindo Stack 00 (Backend)...${NC}"
    cd "$PROJECT_ROOT/00-backend"
    
    # Esvaziar bucket S3 antes de deletar
    BUCKET_NAME="eks-devopsproject-state-files-${ACCOUNT_ID}"
    if aws s3 ls "s3://${BUCKET_NAME}" &>/dev/null; then
        echo "Esvaziando bucket S3: $BUCKET_NAME"
        aws s3 rm "s3://${BUCKET_NAME}" --recursive
    fi
    
    # Destroy backend
    if terraform destroy -auto-approve; then
        echo -e "${GREEN}✅ Stack 00 destruída${NC}"
        
        # Limpar arquivos de state local
        cd "$PROJECT_ROOT"
        find . -name "terraform.tfstate*" -type f -delete
        find . -name ".terraform.lock.hcl" -type f -delete
        echo -e "${GREEN}✅ Arquivos de state local removidos${NC}"
    else
        echo -e "${RED}❌ Erro ao destruir Stack 00${NC}"
    fi
else
    echo -e "${BLUE}ℹ️  Backend preservado (S3 + DynamoDB mantidos)${NC}"
    echo -e "${YELLOW}   Para redeploy: basta executar ./scripts/01-deploy-infra.sh${NC}"
fi

# ============================================================================
# Resumo Final
# ============================================================================

cd "$PROJECT_ROOT"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║   ✅ INFRAESTRUTURA DESTRUÍDA COM SUCESSO!                         ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

if [[ ! "$destroy_backend" =~ ^[Ss]$ ]]; then
    echo -e "${BLUE}📝 Backend preservado. Para redeploy:${NC}"
    echo ""
    echo "   cd /home/luiz7/Projects/istio-eks-terraform-complete"
    echo "   ./scripts/01-deploy-infra.sh"
    echo "   ./scripts/02-install-istio.sh"
    echo "   ./scripts/03-deploy-app.sh"
    echo "   ./scripts/04-start-monitoring.sh"
    echo ""
else
    echo -e "${BLUE}📝 Backend destruído. Para redeploy completo:${NC}"
    echo ""
    echo "   cd /home/luiz7/Projects/istio-eks-terraform-complete"
    echo "   ./scripts/01-deploy-infra.sh  # Recriará backend automaticamente"
    echo "   ./scripts/02-install-istio.sh"
    echo "   ./scripts/03-deploy-app.sh"
    echo "   ./scripts/04-start-monitoring.sh"
    echo ""
fi

echo -e "${GREEN}✅ Processo concluído!${NC}"

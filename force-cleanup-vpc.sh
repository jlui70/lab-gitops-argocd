#!/bin/bash

# ============================================================================
# Script: force-cleanup-vpc.sh
# Descrição: Limpeza forçada de VPC órfã (quando Terraform falha)
# Uso: ./force-cleanup-vpc.sh <vpc-id>
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

VPC_ID="${1}"
REGION="${2:-us-east-1}"

if [ -z "$VPC_ID" ]; then
    echo -e "${RED}❌ Uso: $0 <vpc-id> [region]${NC}"
    echo ""
    echo "Exemplo: $0 vpc-0eb542c31f93e9668 us-east-1"
    exit 1
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🔧 LIMPEZA FORÇADA DE VPC                                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}VPC ID: $VPC_ID${NC}"
echo -e "${YELLOW}Region: $REGION${NC}"
echo ""
read -p "Confirma a limpeza forçada? (s/N): " confirm

if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

echo ""

# ============================================================================
# 1. Deletar Security Groups órfãos (exceto default)
# ============================================================================
echo -e "${YELLOW}[1/5] Removendo Security Groups...${NC}"
SG_IDS=$(aws ec2 describe-security-groups \
    --region $REGION \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'SecurityGroups[?GroupName!=`default`].GroupId' \
    --output text 2>/dev/null || echo "")

if [ -n "$SG_IDS" ]; then
    for sg_id in $SG_IDS; do
        echo "  → Removendo regras do SG: $sg_id"
        
        # Remover regras de ingress (referencias a outros SGs)
        INGRESS_RULES=$(aws ec2 describe-security-groups \
            --region $REGION \
            --group-ids $sg_id \
            --query 'SecurityGroups[0].IpPermissions' 2>/dev/null)
        
        if [ "$INGRESS_RULES" != "null" ] && [ "$INGRESS_RULES" != "[]" ]; then
            aws ec2 revoke-security-group-ingress \
                --region $REGION \
                --group-id $sg_id \
                --ip-permissions "$INGRESS_RULES" 2>/dev/null || true
        fi
        
        # Remover regras de egress
        EGRESS_RULES=$(aws ec2 describe-security-groups \
            --region $REGION \
            --group-ids $sg_id \
            --query 'SecurityGroups[0].IpPermissionsEgress' 2>/dev/null)
        
        if [ "$EGRESS_RULES" != "null" ] && [ "$EGRESS_RULES" != "[]" ]; then
            aws ec2 revoke-security-group-egress \
                --region $REGION \
                --group-id $sg_id \
                --ip-permissions "$EGRESS_RULES" 2>/dev/null || true
        fi
        
        sleep 2
        
        echo "  → Deletando SG: $sg_id"
        aws ec2 delete-security-group --region $REGION --group-id $sg_id 2>/dev/null || true
    done
    echo -e "${GREEN}✅ Security Groups removidos${NC}"
else
    echo -e "${BLUE}ℹ️  Nenhum Security Group para remover${NC}"
fi

sleep 3

# ============================================================================
# 2. Deletar VPC Endpoints
# ============================================================================
echo -e "\n${YELLOW}[2/5] Removendo VPC Endpoints...${NC}"
ENDPOINT_IDS=$(aws ec2 describe-vpc-endpoints \
    --region $REGION \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'VpcEndpoints[].VpcEndpointId' \
    --output text 2>/dev/null || echo "")

if [ -n "$ENDPOINT_IDS" ]; then
    echo "  → Deletando endpoints: $ENDPOINT_IDS"
    aws ec2 delete-vpc-endpoints --region $REGION --vpc-endpoint-ids $ENDPOINT_IDS
    echo "  → Aguardando remoção (30s)..."
    sleep 30
    echo -e "${GREEN}✅ VPC Endpoints removidos${NC}"
else
    echo -e "${BLUE}ℹ️  Nenhum VPC Endpoint para remover${NC}"
fi

# ============================================================================
# 3. Deletar ENIs órfãs
# ============================================================================
echo -e "\n${YELLOW}[3/5] Removendo ENIs...${NC}"
ENI_IDS=$(aws ec2 describe-network-interfaces \
    --region $REGION \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'NetworkInterfaces[].NetworkInterfaceId' \
    --output text 2>/dev/null || echo "")

if [ -n "$ENI_IDS" ]; then
    for eni_id in $ENI_IDS; do
        echo "  → Deletando ENI: $eni_id"
        aws ec2 delete-network-interface --region $REGION --network-interface-id $eni_id 2>/dev/null || true
    done
    sleep 5
    echo -e "${GREEN}✅ ENIs removidas${NC}"
else
    echo -e "${BLUE}ℹ️  Nenhuma ENI para remover${NC}"
fi

# ============================================================================
# 4. Deletar Route Tables (exceto main)
# ============================================================================
echo -e "\n${YELLOW}[4/5] Removendo Route Tables...${NC}"
RT_IDS=$(aws ec2 describe-route-tables \
    --region $REGION \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' \
    --output text 2>/dev/null || echo "")

if [ -n "$RT_IDS" ]; then
    for rt_id in $RT_IDS; do
        # Desassociar de subnets primeiro
        ASSOC_IDS=$(aws ec2 describe-route-tables \
            --region $REGION \
            --route-table-ids $rt_id \
            --query 'RouteTables[].Associations[?!Main].RouteTableAssociationId' \
            --output text 2>/dev/null || echo "")
        
        for assoc_id in $ASSOC_IDS; do
            echo "  → Desassociando: $assoc_id"
            aws ec2 disassociate-route-table --region $REGION --association-id $assoc_id 2>/dev/null || true
        done
        
        echo "  → Deletando Route Table: $rt_id"
        aws ec2 delete-route-table --region $REGION --route-table-id $rt_id 2>/dev/null || true
    done
    echo -e "${GREEN}✅ Route Tables removidas${NC}"
else
    echo -e "${BLUE}ℹ️  Nenhuma Route Table para remover${NC}"
fi

sleep 3

# ============================================================================
# 5. Tentar deletar VPC
# ============================================================================
echo -e "\n${YELLOW}[5/5] Tentando deletar VPC...${NC}"
if aws ec2 delete-vpc --region $REGION --vpc-id $VPC_ID 2>/dev/null; then
    echo -e "${GREEN}✅ VPC deletada com sucesso!${NC}"
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ VPC LIMPA COM SUCESSO!                                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    exit 0
else
    echo -e "${RED}❌ Ainda não foi possível deletar a VPC${NC}"
    echo ""
    echo -e "${YELLOW}Verificando recursos restantes:${NC}"
    
    echo -e "\n${BLUE}Security Groups:${NC}"
    aws ec2 describe-security-groups \
        --region $REGION \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query 'SecurityGroups[*].[GroupId,GroupName]' \
        --output table 2>/dev/null || echo "Nenhum"
    
    echo -e "\n${BLUE}ENIs:${NC}"
    aws ec2 describe-network-interfaces \
        --region $REGION \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query 'NetworkInterfaces[*].[NetworkInterfaceId,Status,Description]' \
        --output table 2>/dev/null || echo "Nenhuma"
    
    echo -e "\n${BLUE}Subnets:${NC}"
    aws ec2 describe-subnets \
        --region $REGION \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query 'Subnets[*].[SubnetId,CidrBlock]' \
        --output table 2>/dev/null || echo "Nenhuma"
    
    echo -e "\n${BLUE}Internet Gateways:${NC}"
    aws ec2 describe-internet-gateways \
        --region $REGION \
        --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
        --query 'InternetGateways[*].InternetGatewayId' \
        --output table 2>/dev/null || echo "Nenhum"
    
    echo ""
    echo -e "${YELLOW}⚠️  Se ainda houver recursos, você pode:${NC}"
    echo "   1. Aguardar alguns minutos e executar este script novamente"
    echo "   2. Deletar os recursos manualmente via Console AWS"
    echo "   3. Usar AWS CLI para deletar recursos específicos"
    exit 1
fi

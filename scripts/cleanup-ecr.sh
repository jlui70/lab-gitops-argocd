#!/bin/bash

# ============================================================================
# Script: cleanup-ecr.sh
# Descrição: Remove todos os repositórios ECR do projeto
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REGION="${1:-us-east-1}"

echo -e "${BLUE}🗑️  Limpando repositórios ECR...${NC}"
echo ""

# Listar todos os repositórios com prefixo 'ecommerce/'
REPOS=$(aws ecr describe-repositories \
    --region $REGION \
    --query 'repositories[?starts_with(repositoryName, `ecommerce/`)].repositoryName' \
    --output text 2>/dev/null || echo "")

if [ -z "$REPOS" ]; then
    echo -e "${BLUE}ℹ️  Nenhum repositório ECR encontrado${NC}"
    exit 0
fi

echo -e "${YELLOW}Repositórios encontrados:${NC}"
for repo in $REPOS; do
    echo "  - $repo"
done

echo ""
read -p "Deletar todos esses repositórios? (s/N): " confirm

if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

echo ""
for repo in $REPOS; do
    echo -e "${YELLOW}Deletando: $repo${NC}"
    aws ecr delete-repository \
        --region $REGION \
        --repository-name "$repo" \
        --force 2>/dev/null && echo -e "${GREEN}  ✅ Deletado${NC}" || echo -e "${RED}  ❌ Erro${NC}"
done

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ ECR LIMPO COM SUCESSO!                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"

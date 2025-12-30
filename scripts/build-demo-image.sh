#!/bin/bash

# Script para construir imagem demo do ecommerce-ui com versão
# Uso: ./build-demo-image.sh <version> <color>
# Exemplo: ./build-demo-image.sh v1.0.0 "#3498db"
#          ./build-demo-image.sh v2.0 "#e74c3c"

set -e

VERSION=${1:-v1.0.0}
COLOR=${2:-#3498db}

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Obter configurações AWS
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecommerce/ecommerce-ui"

echo -e "${YELLOW}🐳 Construindo imagem ecommerce-ui${NC}"
echo "   Version: $VERSION"
echo "   Color: $COLOR"
echo "   ECR: $ECR_REPO:$VERSION"

# Determinar qual diretório usar baseado na versão
if [[ "$VERSION" == *"v2"* ]] || [[ "$VERSION" == *"2.0"* ]]; then
    BUILD_DIR="microservices-v2/ecommerce-ui"
    echo "   Source: microservices-v2 (Versão 2.0 🚀)"
else
    BUILD_DIR="microservices/ecommerce-ui"
    echo "   Source: microservices (Versão 1.0)"
fi

# Verificar se o diretório existe
if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${RED}❌ Erro: Diretório $BUILD_DIR não encontrado${NC}"
    exit 1
fi

# Criar repositório ECR se não existir
aws ecr describe-repositories --repository-names "ecommerce/ecommerce-ui" --region $AWS_REGION >/dev/null 2>&1 || \
    aws ecr create-repository --repository-name "ecommerce/ecommerce-ui" --region $AWS_REGION --image-tag-mutability MUTABLE >/dev/null 2>&1

# Login no ECR
echo -e "${YELLOW}🔐 Login no ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com 2>&1 | grep -i "login succeeded" || echo "   (Login realizado - ignorando warnings WSL)"

# Navegar para o diretório do microserviço
cd $BUILD_DIR

# Construir a imagem Docker
echo -e "${YELLOW}🔨 Construindo imagem Docker...${NC}"
docker build -t ${ECR_REPO}:${VERSION} .

# Fazer push para ECR
echo -e "${YELLOW}📤 Enviando para ECR...${NC}"
docker push ${ECR_REPO}:${VERSION}

# Também taguear como 'latest' se for v2
if [[ "$VERSION" == *"v2"* ]] || [[ "$VERSION" == *"2.0"* ]]; then
    docker tag ${ECR_REPO}:${VERSION} ${ECR_REPO}:latest
    docker push ${ECR_REPO}:latest
    echo -e "${GREEN}✅ Imagem construída e enviada com sucesso!${NC}"
    echo "   ${ECR_REPO}:${VERSION}"
    echo "   ${ECR_REPO}:latest"
else
    echo -e "${GREEN}✅ Imagem construída e enviada com sucesso!${NC}"
    echo "   ${ECR_REPO}:${VERSION}"
fi

cd ../..

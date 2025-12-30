#!/bin/bash

# Script para construir e fazer push das imagens Docker para o ECR
# Este script deve ser executado ANTES de fazer o deploy dos microserviços

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}║   🐳 CONSTRUIR E PUSH DE IMAGENS DOCKER PARA ECR                  ║${NC}"
echo -e "${BLUE}║                                                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Obter ID da conta AWS
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
ECR_BASE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecommerce"

echo -e "${YELLOW}📋 Configuração:${NC}"
echo "  AWS Account ID: $AWS_ACCOUNT_ID"
echo "  AWS Region: $AWS_REGION"
echo "  ECR Base: $ECR_BASE"
echo ""

# Login no ECR
echo -e "${YELLOW}🔐 Fazendo login no ECR...${NC}"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Lista de microserviços
SERVICES=(
  "ecommerce-ui"
  "product-catalog"
  "order-management"
  "product-inventory"
  "profile-management"
  "shipping-handling"
  "contact-support"
)

# Criar repositórios ECR se não existirem
echo -e "\n${YELLOW}📦 Criando repositórios ECR (se não existirem)...${NC}"
for SERVICE in "${SERVICES[@]}"; do
  aws ecr describe-repositories --repository-names "ecommerce/$SERVICE" --region $AWS_REGION >/dev/null 2>&1 || \
    aws ecr create-repository --repository-name "ecommerce/$SERVICE" --region $AWS_REGION >/dev/null 2>&1
  echo -e "${GREEN}✅ ecommerce/$SERVICE${NC}"
done

echo -e "\n${YELLOW}⚠️  ATENÇÃO:${NC} Os Dockerfiles dos microserviços ainda não possuem código real."
echo "As imagens serão baseadas em nginx para demonstração."
echo ""
read -p "Deseja continuar e construir imagens temporárias com nginx? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[SsYy]$ ]]; then
  echo -e "${YELLOW}Operação cancelada.${NC}"
  exit 0
fi

# Construir e fazer push das imagens
echo -e "\n${YELLOW}🔨 Construindo e fazendo push das imagens...${NC}\n"

for SERVICE in "${SERVICES[@]}"; do
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${YELLOW}📦 Processando: $SERVICE${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  
  # Verificar se o Dockerfile existe
  if [ -f "microservices/$SERVICE/Dockerfile" ]; then
    echo -e "  ${GREEN}✓${NC} Dockerfile encontrado"
    cd "microservices/$SERVICE"
  else
    echo -e "  ${RED}✗${NC} Dockerfile não encontrado, usando nginx temporário"
    # Criar diretório temporário
    mkdir -p "/tmp/docker-build-$SERVICE"
    cd "/tmp/docker-build-$SERVICE"
    
    # Criar Dockerfile temporário baseado em nginx
    cat > Dockerfile <<EOF
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF
    
    # Criar index.html temporário
    cat > index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>$SERVICE</title></head>
<body>
  <h1>Microservice: $SERVICE</h1>
  <p>Versão temporária - substitua com código real</p>
  <p>Timestamp: $(date)</p>
</body>
</html>
EOF
  fi
  
  # Build da imagem
  IMAGE_TAG="${ECR_BASE}/${SERVICE}:latest"
  echo -e "  🔨 Construindo imagem: $IMAGE_TAG"
  docker build -t $IMAGE_TAG . --quiet
  
  # Push para ECR
  echo -e "  📤 Enviando para ECR..."
  docker push $IMAGE_TAG --quiet
  
  # Criar também a tag staging-latest
  STAGING_TAG="${ECR_BASE}/${SERVICE}:staging-latest"
  docker tag $IMAGE_TAG $STAGING_TAG
  docker push $STAGING_TAG --quiet
  
  # Criar também a tag prod-v1.0.0
  PROD_TAG="${ECR_BASE}/${SERVICE}:prod-v1.0.0"
  docker tag $IMAGE_TAG $PROD_TAG
  docker push $PROD_TAG --quiet
  
  echo -e "  ${GREEN}✅ $SERVICE - push concluído${NC}"
  echo ""
  
  cd - >/dev/null
done

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║   ✅ TODAS AS IMAGENS FORAM ENVIADAS PARA O ECR!                   ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}📋 Próximos passos:${NC}"
echo "  1. Atualizar os manifestos K8s com o ACCOUNT_ID correto:"
echo "     find k8s-manifests -type f -name '*.yaml' -exec sed -i 's/ACCOUNT_ID/$AWS_ACCOUNT_ID/g' {} \;"
echo ""
echo "  2. Fazer commit e push para o repositório GitHub"
echo ""
echo "  3. Sincronizar as aplicações no ArgoCD:"
echo "     argocd app sync ecommerce-staging"
echo ""

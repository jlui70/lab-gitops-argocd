#!/bin/bash

# ============================================================================
# Script: migrate-real-app.sh
# Descrição: Migra aplicação ecommerce real para ECR com v1.0.0 e v2.0.0
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"
ECR_PREFIX="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/ecommerce"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Migração: Aplicação Real Ecommerce → ECR (v1.0.0 e v2.0.0)      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════╝${NC}"

# Login ECR
echo -e "\n${YELLOW}🔐 Login no ECR...${NC}"
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Microservices
SERVICES=(
    "ecommerce-ui"
    "product-catalog"
    "order-management"
    "product-inventory"
    "profile-management"
    "shipping-and-handling"
    "contact-support-team"
)

# ============================================================================
# Fase 1: Copiar v1.0.0 do DockerHub → ECR
# ============================================================================

echo -e "\n${YELLOW}📦 Fase 1: Copiando v1.0.0 do DockerHub → ECR...${NC}"

for service in "${SERVICES[@]}"; do
    echo -e "\n${BLUE}Processing $service...${NC}"
    
    # Determinar tag source
    if [ "$service" = "ecommerce-ui" ]; then
        SOURCE_TAG="latest"
    else
        SOURCE_TAG="1.0.0"
    fi
    
    SOURCE_IMAGE="rslim087/${service}:${SOURCE_TAG}"
    TARGET_IMAGE="${ECR_PREFIX}/${service}:v1.0.0"
    
    echo "  Pulling: $SOURCE_IMAGE"
    docker pull $SOURCE_IMAGE
    
    echo "  Tagging: $TARGET_IMAGE"
    docker tag $SOURCE_IMAGE $TARGET_IMAGE
    
    echo "  Pushing: $TARGET_IMAGE"
    docker push $TARGET_IMAGE
    
    echo -e "${GREEN}  ✅ $service v1.0.0 copiado${NC}"
done

echo -e "\n${GREEN}✅ Fase 1 completa: v1.0.0 disponível no ECR${NC}"

# ============================================================================
# Fase 2: Criar v2.0.0 modificado (azul → vermelho)
# ============================================================================

echo -e "\n${YELLOW}🎨 Fase 2: Criando v2.0.0 com mudanças visuais...${NC}"

# Para ecommerce-ui, modificar CSS usando container temporário
echo -e "\n${BLUE}Criando ecommerce-ui v2.0.0 (tema vermelho)...${NC}"

# Criar container temporário para extrair arquivos
CONTAINER_ID=$(docker create rslim087/ecommerce-ui:latest)
mkdir -p /tmp/ecommerce-ui-v2
docker cp $CONTAINER_ID:/usr/share/nginx/html /tmp/ecommerce-ui-v2/
docker rm $CONTAINER_ID

# Modificar CSS (azul #3498db → vermelho #e74c3c)
echo "  Modificando cores azul → vermelho..."
find /tmp/ecommerce-ui-v2/html -name "*.css" -type f -exec sed -i 's/#3498db/#e74c3c/g; s/#2980b9/#c0392b/g; s/rgb(52, 152, 219)/rgb(231, 76, 60)/g' {} \;
find /tmp/ecommerce-ui-v2/html -name "*.js" -type f -exec sed -i 's/#3498db/#e74c3c/g; s/#2980b9/#c0392b/g' {} \;

# Adicionar marca de versão no title
sed -i 's/<title>.*<\/title>/<title>Ecommerce v2.0.0<\/title>/' /tmp/ecommerce-ui-v2/html/index.html 2>/dev/null || true

# Criar nova imagem com conteúdo modificado
cat > /tmp/Dockerfile.v2 << 'EOF'
FROM nginx:alpine
COPY html /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 4000
CMD ["nginx", "-g", "daemon off;"]
EOF

# Copiar nginx.conf original
docker cp $CONTAINER_ID:/etc/nginx/conf.d/default.conf /tmp/ecommerce-ui-v2/nginx.conf 2>/dev/null || echo "server { listen 4000; location / { root /usr/share/nginx/html; index index.html; try_files \$uri /index.html; } }" > /tmp/ecommerce-ui-v2/nginx.conf

cd /tmp/ecommerce-ui-v2
docker build -t ${ECR_PREFIX}/ecommerce-ui:v2.0.0 -f /tmp/Dockerfile.v2 .
docker push ${ECR_PREFIX}/ecommerce-ui:v2.0.0
cd - > /dev/null

rm -rf /tmp/ecommerce-ui-v2

echo -e "${GREEN}✅ ecommerce-ui v2.0.0 criado (tema vermelho)${NC}"

# Para os outros microservices, apenas copiar como v2.0.0 (sem mudanças visuais)
for service in "product-catalog" "order-management" "product-inventory" "profile-management" "shipping-and-handling" "contact-support-team"; do
    echo -e "\n${BLUE}Copiando $service como v2.0.0...${NC}"
    docker tag ${ECR_PREFIX}/${service}:v1.0.0 ${ECR_PREFIX}/${service}:v2.0.0
    docker push ${ECR_PREFIX}/${service}:v2.0.0
    echo -e "${GREEN}✅ $service v2.0.0 copiado${NC}"
done

echo -e "\n${GREEN}✅ Fase 2 completa: v2.0.0 disponível no ECR${NC}"

# ============================================================================
# Resumo
# ============================================================================

echo -e "\n${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    ✅ MIGRAÇÃO COMPLETA!                           ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}Imagens disponíveis no ECR:${NC}"
for service in "${SERVICES[@]}"; do
    echo "  • ${ECR_PREFIX}/${service}:v1.0.0"
    echo "  • ${ECR_PREFIX}/${service}:v2.0.0"
done

echo -e "\n${YELLOW}Próximos passos:${NC}"
echo "  1. Atualizar k8s-manifests/base/*.yaml com as novas imagens ECR"
echo "  2. Configurar portas corretas (4000)"
echo "  3. Adicionar variáveis de ambiente para comunicação entre serviços"
echo "  4. git commit && git push"
echo "  5. ArgoCD irá sincronizar automaticamente"


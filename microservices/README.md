# Microservices Source Code

Este diretório contém o código-fonte de todos os microserviços da aplicação E-commerce.

## 🏗️ Estrutura

```
microservices/
├── ecommerce-ui/          # Frontend React
├── product-catalog/       # API de catálogo de produtos
├── order-management/      # API de gerenciamento de pedidos
├── product-inventory/     # API de controle de estoque
├── profile-management/    # API de perfis de usuário
├── shipping-handling/     # API de logística e entrega
└── contact-support/       # API de suporte ao cliente
```

## 🐳 Build das Imagens Docker

### Build Individual
```bash
# Exemplo: Product Catalog
cd product-catalog
docker build -t ecommerce/product-catalog:latest .
```

### Build de Todos os Serviços
```bash
# Usar script automatizado (criar)
./scripts/build-all-images.sh
```

### Build e Push para ECR
```bash
# Configurar ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build e push
docker build -t <account-id>.dkr.ecr.us-east-1.amazonaws.com/ecommerce/product-catalog:v1.0.0 .
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/ecommerce/product-catalog:v1.0.0
```

## 📦 Portas dos Serviços

| Serviço | Porta |
|---------|-------|
| ecommerce-ui | 4000 |
| product-catalog | 3001 |
| order-management | 3002 |
| product-inventory | 3003 |
| profile-management | 3004 |
| shipping-handling | 3005 |
| contact-support | 3006 |

## 🔒 Boas Práticas Implementadas

- ✅ Multi-stage builds (reduz tamanho da imagem)
- ✅ Non-root user (segurança)
- ✅ Health checks (observabilidade)
- ✅ .dockerignore (otimização)
- ✅ Production dependencies only
- ✅ Security headers (nginx)

## 🚀 Desenvolvimento Local

```bash
# Instalar dependências
npm install

# Executar em modo dev
npm run dev

# Testes
npm test

# Build local
npm run build
```

## 📝 Notas

- Os Dockerfiles usam imagens Alpine para reduzir tamanho
- Cada serviço tem seu próprio health check endpoint `/health`
- As imagens são otimizadas para produção
- Para desenvolvimento local, usar `docker-compose.yml` (criar se necessário)

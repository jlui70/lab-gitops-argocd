# 📜 Scripts - GitOps Demo v2.0

## 🎯 Scripts de Demonstração

### 🚀 Script Principal

#### `demo-update-v2.sh`
**Uso:** `./scripts/demo-update-v2.sh`

Demonstração completa de GitOps mostrando atualização da v1.0 para v2.0.

**O que faz:**
1. Verifica versão atual (v1.0)
2. Mostra alteração do desenvolvedor
3. Build da imagem Docker v2.0.0
4. Push para AWS ECR
5. Atualiza manifesto Kubernetes
6. ArgoCD sincroniza automaticamente
7. Valida deployment

**Tempo:** 3-5 minutos

**Pré-requisitos:**
- Cluster EKS rodando
- AWS credentials configuradas
- Docker rodando
- Código na versão 1.0

---

## 🛠️ Scripts Auxiliares

### `update-to-v2.sh`
**Uso:** `./scripts/update-to-v2.sh`

Atualiza **apenas o código fonte** para versão 2.0.

**Alterações:**
- `Home.js`: Adiciona "Versão 2.0 🚀"
- `package.json`: version = "2.0.0"

**Quando usar:**
- Preparar código antes de build manual
- Testar mudanças localmente
- Preparar para commit/push manual

---

### `rollback-to-v1.sh`
**Uso:** `./scripts/rollback-to-v1.sh`

Reverte código fonte para versão 1.0.

**Alterações:**
- `Home.js`: Remove "Versão 2.0 🚀"
- `package.json`: version = "1.0.0"

**Quando usar:**
- Resetar para estado inicial
- Preparar nova demonstração
- Reverter mudanças de teste

---

## 📊 Fluxo de Uso

### Para Demonstração Completa:

```bash
# 1. Garantir que está na v1.0
./scripts/rollback-to-v1.sh

# 2. Deploy inicial (se necessário)
cd ..
./rebuild-all-with-gitops.sh

# 3. Demonstrar atualização
./scripts/demo-update-v2.sh
```

### Para Testes Locais:

```bash
# Atualizar código
./scripts/update-to-v2.sh

# Build local
cd microservices/ecommerce-ui
docker build -t test:v2 .

# Reverter quando terminar
cd ../..
./scripts/rollback-to-v1.sh
```

---

## 🔄 Ciclo de Demonstração

```
Estado Inicial (v1.0)
         ↓
  update-to-v2.sh
         ↓
  demo-update-v2.sh
         ↓
Estado Final (v2.0)
         ↓
  rollback-to-v1.sh
         ↓
Estado Inicial (v1.0)
```

---

## 🎬 Outros Scripts do Projeto

### `01-deploy-infra.sh`
Deploy da infraestrutura (VPC + EKS)

### `02-install-istio.sh`
Instala Istio e ferramentas de observabilidade

### `03-deploy-app.sh`
Deploy da aplicação (método tradicional)

### `04-start-monitoring.sh`
Inicia port-forwards para monitoramento

### `build-and-push-images.sh`
Build e push de todos os microserviços

### `build-demo-image.sh`
Build de imagem demo com HTML customizado

---

## 💡 Dicas

### Verificar Estado Atual:
```bash
# Ver versão no código
grep "Welcome to the E-commerce App" ../microservices/ecommerce-ui/src/pages/Home.js

# Ver versão no package.json
grep '"version":' ../microservices/ecommerce-ui/package.json
```

### Logs Durante Execução:
```bash
# Seguir logs do pod
kubectl logs -f -n ecommerce-staging -l app=ecommerce-ui

# Ver eventos
kubectl get events -n ecommerce-staging --sort-by='.lastTimestamp'
```

### Forçar Sync ArgoCD:
```bash
kubectl patch application ecommerce-staging -n argocd --type merge -p '{"operation":{"sync":{}}}'
```

---

## 📚 Documentação Relacionada

- **DEMO-V2-GUIDE.md** - Guia completo detalhado
- **QUICK-DEMO-V2.md** - Resumo executivo
- **PRE-DEMO-CHECKLIST.md** - Checklist pré-demo
- **SETUP-COMPLETE-V2.md** - Setup completo

---

## ⚠️ Notas Importantes

1. **Sempre comece com v1.0**
   - Rode `rollback-to-v1.sh` antes de cada demo

2. **Ordem importa**
   - Update código → Build → Push → Deploy

3. **ArgoCD precisa estar rodando**
   - Cluster EKS deve estar ativo

4. **Tempo de propagação**
   - ArgoCD pode levar 30-60s para detectar mudanças

---

**✅ Scripts testados e prontos para uso!**

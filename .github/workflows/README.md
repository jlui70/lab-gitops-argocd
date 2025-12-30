# GitHub Actions Workflows

Este diretório contém os workflows de CI/CD do projeto usando GitHub Actions.

## 📁 Estrutura de Workflows

```
.github/workflows/
├── setup-ecr.yml          # Criar repositórios ECR (executar uma vez)
├── ecommerce-ui.yml       # CI/CD para Frontend React
├── product-catalog.yml    # CI/CD para Product Catalog API
└── (outros microserviços)
```

## 🚀 Fluxo CI/CD

### **Pipeline Completo:**

```
1. Code Push/PR
   ↓
2. Build & Test
   - Docker build
   - Container health check
   - Security scan (Trivy)
   ↓
3. Deploy Staging (auto)
   - Build & push to ECR
   - Update Kustomize manifests
   - ArgoCD sync (auto)
   ↓
4. Deploy Production (manual approval)
   - Build & push to ECR with version tag
   - Update Kustomize manifests
   - ArgoCD sync (manual)
   - Create GitHub Release
```

## 🔧 Configuração Inicial

### 1. Criar Repositórios ECR

Execute o workflow `setup-ecr.yml` manualmente:

```bash
# Via GitHub UI:
Actions → Create ECR Repositories → Run workflow

# Via gh CLI:
gh workflow run setup-ecr.yml
```

### 2. Configurar GitHub Secrets

Adicione os seguintes secrets em: `Settings → Secrets and variables → Actions`

**Required Secrets:**
```
AWS_ACCESS_KEY_ID        # AWS access key com permissões ECR
AWS_SECRET_ACCESS_KEY    # AWS secret key
```

**Optional Secrets (para notificações):**
```
SLACK_WEBHOOK_URL        # Webhook para notificações Slack
```

### 3. Configurar Environments

Crie dois environments: `Settings → Environments`

**Staging:**
- Nome: `staging`
- Protection rules: Nenhuma (deploy automático)

**Production:**
- Nome: `production`
- Protection rules:
  - ✅ Required reviewers (adicione reviewers)
  - ✅ Wait timer: 5 minutes (opcional)

## 📊 Workflows Detalhados

### **setup-ecr.yml**
**Quando:** Manual (workflow_dispatch)  
**O que faz:**
- Cria todos os repositórios ECR necessários
- Configura scan de segurança automático
- Define lifecycle policy (manter últimas 10 imagens)

### **ecommerce-ui.yml**
**Quando:** Push/PR em `microservices/ecommerce-ui/**`  
**Jobs:**
1. **build-and-test**: Build + testes + security scan
2. **deploy-staging**: Deploy automático em staging
3. **deploy-production**: Deploy manual em produção

### **product-catalog.yml**
**Quando:** Push/PR em `microservices/product-catalog/**`  
**Jobs:** Similar ao ecommerce-ui

## 🎯 Estratégias de Branching

### **Develop Branch**
```bash
git checkout develop
git commit -m "feat: add new feature"
git push
```
→ Deploy automático em **staging**

### **Main Branch**
```bash
git checkout main
git merge develop
git push
```
→ Deploy em **staging** + aguarda aprovação para **production**

### **Release Tags**
```bash
git tag -a v1.2.0 -m "Release 1.2.0"
git push origin v1.2.0
```
→ Cria release versionada

## 🔐 Segurança

### **Trivy Security Scan**
Cada build escaneia vulnerabilidades:
- Severidade: CRITICAL, HIGH
- Falha no build se encontrar vulnerabilidades críticas

### **Container Testing**
- Health check endpoint `/health`
- Verifica se container inicia corretamente
- Timeout de 10-15 segundos

### **Image Signing (TODO)**
```yaml
- name: Sign image with Cosign
  run: cosign sign $IMAGE_URL
```

## 📈 Monitoramento de Workflows

### Ver status dos workflows
```bash
# Via GitHub UI
Actions tab

# Via gh CLI
gh run list
gh run view <run-id>
```

### Logs de workflow
```bash
gh run view <run-id> --log
```

### Re-run failed workflows
```bash
gh run rerun <run-id>
```

## 🔄 Rollback

### Reverter para versão anterior

**Opção 1: Via ArgoCD**
```bash
argocd app history ecommerce-production
argocd app rollback ecommerce-production <revision>
```

**Opção 2: Reverter commit Git**
```bash
# Ver histórico
git log k8s-manifests/production/kustomization.yaml

# Reverter
git revert <commit-sha>
git push
```

**Opção 3: Update manual de tag**
```bash
cd k8s-manifests/production
kustomize edit set image <ecr-url>:<old-tag>
git commit -m "rollback: revert to previous version"
git push
```

## 🚨 Troubleshooting

### Workflow falha no push ECR
```bash
# Verificar se ECR repository existe
aws ecr describe-repositories --repository-names ecommerce/product-catalog

# Verificar credenciais AWS
aws sts get-caller-identity
```

### Kustomize edit não funciona
```bash
# Instalar kustomize localmente para testar
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
```

### ArgoCD não detecta mudanças
```bash
# Verificar se commit foi feito corretamente
git log k8s-manifests/staging/

# Forçar refresh no ArgoCD
argocd app get ecommerce-staging --refresh
```

## 📝 Adicionar Novo Microserviço

1. Crie Dockerfile em `microservices/<service-name>/`
2. Copie workflow existente:
```bash
cp .github/workflows/product-catalog.yml .github/workflows/<service-name>.yml
```
3. Edite variáveis:
```yaml
env:
  ECR_REPOSITORY: ecommerce/<service-name>
  SERVICE_NAME: <service-name>
```
4. Adicione manifest K8s em `k8s-manifests/base/<service-name>.yaml`
5. Update `k8s-manifests/base/kustomization.yaml`

## 🎨 Customizações Avançadas

### Adicionar testes unitários
```yaml
- name: Run unit tests
  run: |
    cd microservices/product-catalog
    npm test
```

### Adicionar linting
```yaml
- name: Lint Dockerfile
  uses: hadolint/hadolint-action@v3.1.0
  with:
    dockerfile: microservices/product-catalog/Dockerfile
```

### Notificações Slack
```yaml
- name: Notify Slack
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }}
```

## 📚 Referências

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Kustomize Documentation](https://kustomize.io/)
- [Trivy Security Scanner](https://github.com/aquasecurity/trivy)

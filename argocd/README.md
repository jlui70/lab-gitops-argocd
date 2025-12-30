# ArgoCD Configuration

Este diretório contém a configuração do ArgoCD para implementar GitOps no projeto.

## 📁 Estrutura

```
argocd/
├── install/
│   ├── install-argocd.sh      # Script de instalação do ArgoCD
│   ├── deploy-apps.sh          # Deploy das aplicações ArgoCD
│   └── uninstall-argocd.sh     # Remoção completa
│
└── applications/
    ├── staging-app.yaml        # Application manifest para staging
    └── production-app.yaml     # Application manifest para production
```

## 🚀 Instalação Rápida

### 1. Instalar ArgoCD no Cluster

```bash
cd argocd/install
chmod +x *.sh
./install-argocd.sh
```

Este script irá:
- ✅ Criar namespace `argocd`
- ✅ Instalar ArgoCD versão stable
- ✅ Expor ArgoCD UI via LoadBalancer
- ✅ Mostrar credenciais de acesso

### 2. Acessar ArgoCD UI

```bash
# Obter URL do ArgoCD
kubectl get svc argocd-server -n argocd

# Obter senha do admin
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**Login:**
- Username: `admin`
- Password: (obtido no comando acima)

**⚠️ IMPORTANTE:** Altere a senha após primeiro login!

### 3. Instalar ArgoCD CLI (Opcional mas recomendado)

```bash
# Linux
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# macOS
brew install argocd

# Login via CLI
argocd login <ARGOCD-SERVER> --username admin --insecure
```

### 4. Deploy das Aplicações

```bash
./deploy-apps.sh
```

Isso criará:
- ✅ Application `ecommerce-staging` (auto-sync enabled)
- ✅ Application `ecommerce-production` (manual sync)

## 🔄 Fluxo GitOps

```
Developer → Git Push → GitHub Actions → Build & Push to ECR → Update manifests
                                                                      ↓
                                                            Commit new image tags
                                                                      ↓
                                                          ArgoCD detects changes
                                                                      ↓
                                         ┌─────────────────────────────────────┐
                                         │                                     │
                              STAGING (auto)                        PRODUCTION (manual)
                                         │                                     │
                              Deploy automatically              Wait for approval
                                         │                                     │
                                    Test in staging                   Deploy to prod
```

## 📊 Gerenciamento de Aplicações

### Ver status das aplicações

```bash
# Via CLI
argocd app list
argocd app get ecommerce-staging
argocd app get ecommerce-production

# Via kubectl
kubectl get applications -n argocd
kubectl describe application ecommerce-staging -n argocd
```

### Sincronizar manualmente

```bash
# Staging (normalmente não necessário - auto-sync)
argocd app sync ecommerce-staging

# Production (sempre manual)
argocd app sync ecommerce-production
```

### Ver diferenças (Git vs Cluster)

```bash
argocd app diff ecommerce-staging
argocd app diff ecommerce-production
```

### Ver histórico de deploys

```bash
argocd app history ecommerce-staging
argocd app history ecommerce-production
```

### Rollback para versão anterior

```bash
# Ver histórico primeiro
argocd app history ecommerce-production

# Rollback para revision específica
argocd app rollback ecommerce-production <REVISION-ID>
```

## 🎯 Políticas de Sync

### **Staging** (Auto-Sync habilitado)
```yaml
syncPolicy:
  automated:
    prune: true       # Remove recursos deletados
    selfHeal: true    # Corrige drift automático
```

**Comportamento:**
- Git push → Deploy automático em ~30 segundos
- Qualquer mudança manual no cluster é revertida
- Recursos deletados do Git são removidos do cluster

### **Production** (Manual Sync)
```yaml
syncPolicy:
  automated: null  # Desabilitado
```

**Comportamento:**
- Git push → Nenhuma ação automática
- Requer aprovação manual via UI ou CLI
- Permite revisão antes do deploy

## 🔐 Segurança

### Alterar senha do admin

```bash
argocd account update-password
```

### Criar usuário adicional

```bash
# Edit argocd-cm ConfigMap
kubectl edit configmap argocd-cm -n argocd

# Adicionar:
data:
  accounts.devops: apiKey, login
```

### Configurar RBAC

```bash
# Edit argocd-rbac-cm
kubectl edit configmap argocd-rbac-cm -n argocd
```

## 🔧 Configurações Avançadas

### Conectar repositório privado

```bash
argocd repo add https://github.com/USERNAME/REPO \
  --username USERNAME \
  --password TOKEN
```

### Configurar notificações (Slack)

```bash
kubectl apply -f notifications-config.yaml
```

### Configurar Image Updater (Automação)

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml
```

## 🚨 Troubleshooting

### Application OutOfSync

```bash
# Ver diferenças
argocd app diff ecommerce-staging

# Forçar sync
argocd app sync ecommerce-staging --force
```

### ArgoCD UI não carrega

```bash
# Check pods
kubectl get pods -n argocd

# Check logs
kubectl logs -n argocd deployment/argocd-server
```

### Sync stuck

```bash
# Deletar Application e recriar
kubectl delete application ecommerce-staging -n argocd
./deploy-apps.sh
```

## 🧹 Limpeza

```bash
# Remover tudo (cuidado!)
./uninstall-argocd.sh
```

## 📚 Referências

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Getting Started Guide](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)

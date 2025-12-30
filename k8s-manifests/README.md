# Kubernetes Manifests - GitOps Structure

Estrutura de manifestos Kubernetes usando **Kustomize** para gerenciar ambientes separados (staging e produção).

## 📁 Estrutura

```
k8s-manifests/
├── base/                    # Configurações base compartilhadas
│   ├── namespace-staging.yaml
│   ├── namespace-production.yaml
│   ├── ecommerce-ui.yaml
│   ├── product-catalog.yaml
│   ├── order-management.yaml
│   ├── product-inventory.yaml
│   ├── profile-management.yaml
│   ├── shipping-handling.yaml
│   ├── contact-support.yaml
│   ├── istio-gateway.yaml
│   └── kustomization.yaml
│
├── staging/                 # Overlays para staging
│   ├── kustomization.yaml
│   ├── replicas-patch.yaml
│   └── resources-patch.yaml
│
└── production/              # Overlays para produção
    ├── kustomization.yaml
    └── hpa-patch.yaml
```

## 🎯 Diferenças entre Ambientes

### **Staging**
- ✅ Namespace: `ecommerce-staging`
- ✅ Replicas: 1 por serviço (economia)
- ✅ Resources: Menores (64Mi/50m CPU)
- ✅ Images: Tags `staging-latest`
- ✅ Sem HPA (Horizontal Pod Autoscaler)

### **Production**
- ✅ Namespace: `ecommerce-production`
- ✅ Replicas: 2 por serviço (alta disponibilidade)
- ✅ Resources: Maiores (128Mi/100m CPU)
- ✅ Images: Tags versionadas `prod-v1.0.0`
- ✅ HPA configurado (escala 2-5 replicas)

## 🚀 Deploy Manual (para teste)

### Build dos manifestos

```bash
# Staging
kubectl kustomize k8s-manifests/staging

# Production
kubectl kustomize k8s-manifests/production
```

### Apply dos manifestos

```bash
# Staging
kubectl apply -k k8s-manifests/staging

# Production (cuidado!)
kubectl apply -k k8s-manifests/production
```

### Verificar deployments

```bash
# Staging
kubectl get all -n ecommerce-staging

# Production
kubectl get all -n ecommerce-production
```

## 🔄 GitOps com ArgoCD

**IMPORTANTE:** Em produção, NÃO use `kubectl apply` diretamente! 

Use ArgoCD que sincroniza automaticamente este repositório:

```bash
# ArgoCD faz sync automático
argocd app sync ecommerce-staging
argocd app sync ecommerce-production
```

## 📝 Como Atualizar Imagens

O GitHub Actions atualiza automaticamente as tags em `kustomization.yaml`:

### Staging (Automático em cada push)
```yaml
images:
  - name: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/ecommerce/product-catalog
    newTag: staging-abc1234  # SHA do commit
```

### Production (Manual trigger ou tag)
```yaml
images:
  - name: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/ecommerce/product-catalog
    newTag: prod-v1.2.0  # Versão semântica
```

## 🔐 Secrets (TODO)

Adicionar secrets gerenciados:
- AWS Secrets Manager
- External Secrets Operator
- Sealed Secrets

## 📊 Observabilidade

Todos os pods incluem:
- ✅ Liveness Probes
- ✅ Readiness Probes
- ✅ Resource Limits
- ✅ Istio Sidecar Injection

## 🎨 Customizações por Ambiente

Para adicionar patches específicos:

1. Crie arquivo em `staging/` ou `production/`
2. Adicione em `patchesStrategicMerge:` no `kustomization.yaml`
3. Commit e push - ArgoCD aplica automaticamente!

Exemplo:
```yaml
# staging/env-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-catalog
spec:
  template:
    spec:
      containers:
      - name: product-catalog
        env:
        - name: LOG_LEVEL
          value: "debug"
```

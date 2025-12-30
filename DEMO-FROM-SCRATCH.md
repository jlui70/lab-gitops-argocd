# 🚀 Demonstração GitOps - Do Zero ao Deploy

Este guia mostra como fazer a demonstração completa do GitOps desde o clone do repositório.

## 📋 Pré-requisitos

- AWS CLI configurado
- kubectl instalado
- Acesso ao cluster EKS
- Git configurado

## 🎯 Fluxo da Demonstração

### 1️⃣ Clone do Repositório

```bash
# Clonar repositório
git clone https://github.com/jlui70/lab-gitops-argocd.git
cd lab-gitops-argocd

# Ver estrutura do projeto
ls -la
```

### 2️⃣ Configurar Acesso ao Cluster EKS

```bash
# Atualizar kubeconfig para o cluster
aws eks update-kubeconfig --region us-east-1 --name eks-cluster-istio

# Verificar acesso
kubectl get nodes
kubectl get namespaces
```

### 3️⃣ Verificar Aplicação v1.0 (Estado Inicial)

```bash
# Ver deployment atual
kubectl get deployment ecommerce-ui -n ecommerce-staging

# Ver imagem em uso
kubectl get deployment ecommerce-ui -n ecommerce-staging -o jsonpath='{.spec.template.spec.containers[0].image}'
# Deve mostrar: rslim087/ecommerce-ui:latest

# Ver pods rodando
kubectl get pods -n ecommerce-staging -l app=ecommerce-ui

# Acessar aplicação
# URL: http://<ALB-DNS>/
kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

**Na aplicação v1.0, você verá:**
- Mensagem: "Welcome to the E-commerce App" (SEM "Versão 2.0")

### 4️⃣ Verificar ArgoCD

```bash
# Ver status do ArgoCD Application
kubectl get application ecommerce-staging -n argocd

# Ver configuração do Application
kubectl get application ecommerce-staging -n argocd -o yaml | grep -A 5 "source:"

# Deve mostrar:
# repoURL: https://github.com/jlui70/lab-gitops-argocd.git
# path: k8s-manifests/staging
```

### 5️⃣ Deploy v2.0 via GitOps

```bash
# Ver código atual (v1.0)
cat ecommerce-app-v2/client/src/pages/Home.js | grep -A 2 "Welcome"

# Ver manifest atual
cat k8s-manifests/base/ecommerce-ui.yaml | grep "image:"
# Deve mostrar: rslim087/ecommerce-ui:latest

# Fazer checkout para o commit v2.0
git log --oneline | grep "Deploy v2.0"
git checkout a6f0d3d  # ou use: git checkout <commit-hash-v2.0>

# Verificar mudança no manifest
cat k8s-manifests/base/ecommerce-ui.yaml | grep "image:"
# Agora deve mostrar: 794038226274.dkr.ecr.us-east-1.amazonaws.com/ecommerce/ecommerce-ui:v2.0
```

### 6️⃣ Aguardar ArgoCD Sync (Automático)

```bash
# ArgoCD faz polling do Git a cada 3 minutos
# Para acompanhar em tempo real:

watch -n 5 'kubectl get deployment ecommerce-ui -n ecommerce-staging -o jsonpath="{.spec.template.spec.containers[0].image}"'

# Ou forçar sync imediato (opcional - não é GitOps puro):
kubectl rollout restart deployment/ecommerce-ui -n ecommerce-staging
```

### 7️⃣ Verificar Deploy v2.0

```bash
# Ver imagem atualizada
kubectl get deployment ecommerce-ui -n ecommerce-staging -o jsonpath='{.spec.template.spec.containers[0].image}'
# Deve mostrar: 794038226274.dkr.ecr.us-east-1.amazonaws.com/ecommerce/ecommerce-ui:v2.0

# Ver novos pods
kubectl get pods -n ecommerce-staging -l app=ecommerce-ui -o wide

# Aguardar rollout completo
kubectl rollout status deployment/ecommerce-ui -n ecommerce-staging

# Testar APIs
URL=$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$URL/api/products | jq '.[0]'
curl http://$URL/api/inventory | jq '.[0]'
```

**Na aplicação v2.0, você verá:**
- Mensagem: "Welcome to the E-commerce App - Versão 2.0 🚀"

### 8️⃣ Rollback para v1.0 via GitOps

```bash
# Fazer checkout para o commit v1.0 (rollback)
git log --oneline | grep "Rollback"
git checkout 6768cd5  # ou use: git checkout <commit-hash-rollback>

# Verificar manifest voltou para v1.0
cat k8s-manifests/base/ecommerce-ui.yaml | grep "image:"
# Deve mostrar novamente: rslim087/ecommerce-ui:latest

# Aguardar ArgoCD sync (3 min) ou forçar:
kubectl rollout restart deployment/ecommerce-ui -n ecommerce-staging

# Verificar rollback
kubectl rollout status deployment/ecommerce-ui -n ecommerce-staging
kubectl get deployment ecommerce-ui -n ecommerce-staging -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### 9️⃣ Validação Final

```bash
# Verificar aplicação voltou para v1.0
kubectl get pods -n ecommerce-staging -l app=ecommerce-ui

# Testar APIs ainda funcionam
curl http://$URL/api/products | jq 'length'  # Deve retornar: 12
curl http://$URL/api/inventory | jq 'length'  # Deve retornar: 12
```

## 🎬 Script Automatizado

Para facilitar a demonstração, use o script pronto:

```bash
# Executar demonstração completa
./scripts/demo-gitops-v2.sh
```

## 📊 Pontos-Chave para Apresentação

### ✅ GitOps Puro
- ❌ **NUNCA** executar `kubectl apply` manualmente
- ✅ **SEMPRE** fazer mudanças via Git
- ✅ ArgoCD detecta mudanças automaticamente (polling 3 min)
- ✅ Kubernetes aplica mudanças automaticamente (sync policy)

### ✅ Benefícios Demonstrados
1. **Rastreabilidade:** Todo deploy tem commit Git
2. **Auditoria:** `git log` mostra histórico completo
3. **Rollback Simples:** `git checkout` ou `git revert`
4. **Declarativo:** Estado desejado está no Git
5. **Automatizado:** Zero intervenção manual no cluster

### ✅ Arquitetura
- **Frontend:** React 18 + Material-UI
- **Backend:** Express.js proxy para microserviços
- **Container:** Docker multi-stage build
- **Orquestração:** Kubernetes + Istio
- **GitOps:** ArgoCD com auto-sync
- **Registry:** AWS ECR

## 🔧 Troubleshooting

### ArgoCD não sincronizou?

```bash
# Verificar status detalhado
kubectl describe application ecommerce-staging -n argocd

# Ver logs do ArgoCD
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Forçar refresh (não é sync, apenas atualiza status)
kubectl patch application ecommerce-staging -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

### Deployment travado?

```bash
# Ver eventos
kubectl get events -n ecommerce-staging --sort-by='.lastTimestamp'

# Ver logs dos pods
kubectl logs -n ecommerce-staging -l app=ecommerce-ui --tail=50

# Verificar recursos
kubectl top pods -n ecommerce-staging
```

### APIs não respondem?

```bash
# Testar conectividade entre pods
kubectl exec -it <pod-name> -n ecommerce-staging -- curl http://product-catalog:3001/api/products

# Verificar services
kubectl get svc -n ecommerce-staging

# Verificar environment variables
kubectl describe deployment ecommerce-ui -n ecommerce-staging | grep -A 10 "Environment:"
```

## 📝 Comandos Úteis

```bash
# Ver todos os commits relacionados a v2.0
git log --oneline --all --grep="v2\|V2\|Versão"

# Ver diff entre v1.0 e v2.0
git diff 6768cd5 a6f0d3d

# Ver mudanças no código
git diff 6768cd5 a6f0d3d -- ecommerce-app-v2/client/src/pages/Home.js

# Ver mudanças no manifest
git diff 6768cd5 a6f0d3d -- k8s-manifests/base/ecommerce-ui.yaml
```

## 🌐 URLs Importantes

- **Aplicação:** http://<ALB-DNS>/
- **Repositório Git:** https://github.com/jlui70/lab-gitops-argocd
- **ArgoCD UI:** (se instalado) https://<argocd-server>/

## 📚 Estrutura do Projeto

```
lab-gitops-argocd/
├── argocd/
│   └── applications/
│       ├── staging-app.yaml      # ← ArgoCD Application para staging
│       └── production-app.yaml   # ← ArgoCD Application para produção
│
├── k8s-manifests/
│   ├── base/
│   │   └── ecommerce-ui.yaml     # ← Manifest base (modificado v1↔v2)
│   ├── staging/
│   │   └── kustomization.yaml
│   └── production/
│       └── kustomization.yaml
│
├── ecommerce-app-v2/
│   ├── client/
│   │   └── src/pages/Home.js     # ← Código modificado (Versão 2.0)
│   ├── server/
│   └── Dockerfile                # ← Build multi-stage
│
└── scripts/
    ├── demo-gitops-v2.sh         # ← Script de demonstração
    └── rollback-to-v1.sh         # ← Script de rollback
```

## 🎓 Fluxo GitOps Completo

```
┌──────────────┐
│ Developer    │
│ modifica     │──┐
│ código       │  │
└──────────────┘  │
                  ▼
┌──────────────────────────────────┐
│  1. Git Commit & Push            │
│     k8s-manifests/base/*.yaml    │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│  2. ArgoCD Polling (3 min)       │
│     Detecta mudança no Git       │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│  3. ArgoCD Sync (automated)      │
│     Calcula diff: Git ↔ Cluster  │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│  4. Kubernetes Rollout           │
│     Rolling update (zero down)   │
└──────────────┬───────────────────┘
               │
               ▼
┌──────────────────────────────────┐
│  5. Aplicação v2.0 Live!         │
│     Validação automática         │
└──────────────────────────────────┘
```

---

**Status:** ✅ Pronto para demonstração  
**Repositório:** https://github.com/jlui70/lab-gitops-argocd  
**Última atualização:** 2024-12-30

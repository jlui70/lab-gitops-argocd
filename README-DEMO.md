# 🚀 Lab GitOps com ArgoCD - E-Commerce Demo

Demonstração prática de GitOps usando Kubernetes, ArgoCD, Istio e AWS EKS.

## 🎯 O Que Este Projeto Demonstra

✅ **GitOps Puro:** Deploy automático via Git (sem `kubectl apply` manual)  
✅ **ArgoCD:** Sincronização automática do estado desejado  
✅ **Rolling Updates:** Zero downtime durante deploys  
✅ **Rollback Simples:** Via `git checkout` ou `git revert`  
✅ **Rastreabilidade:** Todo deploy tem commit no Git  

## 🚀 Quick Start

```bash
# 1. Clone o repositório
git clone https://github.com/jlui70/lab-gitops-argocd.git
cd lab-gitops-argocd

# 2. Configure acesso ao cluster EKS
aws eks update-kubeconfig --region us-east-1 --name eks-cluster-istio

# 3. Veja a demonstração completa
cat DEMO-FROM-SCRATCH.md
```

## 📋 Demonstração v1.0 → v2.0

### Deploy v2.0
```bash
# Checkout para commit v2.0
git checkout a6f0d3d

# ArgoCD detecta mudança e faz deploy automaticamente (3 min)
# Ou force: kubectl rollout restart deployment/ecommerce-ui -n ecommerce-staging
```

### Rollback v1.0
```bash
# Checkout para commit v1.0
git checkout 6768cd5

# ArgoCD faz rollback automaticamente (3 min)
```

## 🏗️ Arquitetura

```
┌─────────────┐       ┌──────────────┐       ┌─────────────┐
│   GitHub    │──────▶│   ArgoCD     │──────▶│ Kubernetes  │
│ (Git Repo)  │       │ (GitOps)     │       │  (EKS)      │
└─────────────┘       └──────────────┘       └─────────────┘
      │                                              │
      │                                              ▼
      │                                       ┌─────────────┐
      │                                       │   Istio     │
      │                                       │ (Service    │
      │                                       │   Mesh)     │
      └───────────────────────────────────────┴─────────────┘
                  GitOps Flow (100% automatizado)
```

## 📁 Estrutura do Projeto

```
lab-gitops-argocd/
├── argocd/                     # ArgoCD Applications
│   └── applications/
│       ├── staging-app.yaml    # App staging
│       └── production-app.yaml # App produção
│
├── k8s-manifests/              # Kubernetes Manifests
│   ├── base/                   # Base configs
│   ├── staging/                # Overlay staging
│   └── production/             # Overlay produção
│
├── ecommerce-app-v2/           # Código fonte v2.0
│   ├── client/                 # React frontend
│   ├── server/                 # Express backend
│   └── Dockerfile              # Multi-stage build
│
├── scripts/                    # Scripts de demo
│   ├── demo-gitops-v2.sh      # Demo interativa
│   └── rollback-to-v1.sh      # Rollback rápido
│
└── DEMO-FROM-SCRATCH.md        # 📖 Guia completo
```

## 🎬 Demonstração Rápida

Execute o script interativo:

```bash
./scripts/demo-gitops-v2.sh
```

O script mostra:
1. ✅ Estado atual (v1.0)
2. ✅ Código modificado (Home.js)
3. ✅ Commit no Git
4. ✅ ArgoCD auto-sync
5. ✅ Rollout Kubernetes
6. ✅ Validação v2.0

## 🔑 Commits Importantes

```bash
# Ver commits do fluxo GitOps
git log --oneline

# Commits principais:
# a6f0d3d - Deploy v2.0 (mensagem "Versão 2.0 🚀")
# 6768cd5 - Rollback v1.0 (imagem rslim087)
```

## 🌐 URLs

- **App URL:** http://aea55d7dff98f43afa1b5a3ce75aa411-126944.us-east-1.elb.amazonaws.com/
- **Repositório:** https://github.com/jlui70/lab-gitops-argocd

## 📚 Documentação

- [DEMO-FROM-SCRATCH.md](DEMO-FROM-SCRATCH.md) - Guia completo passo a passo
- [V2-README.md](V2-README.md) - Detalhes da implementação v2.0

## 🛠️ Tecnologias

- **Kubernetes:** EKS (AWS)
- **Service Mesh:** Istio
- **GitOps:** ArgoCD
- **Frontend:** React 18 + Material-UI
- **Backend:** Express.js
- **Container:** Docker
- **Registry:** AWS ECR
- **IaC:** Terraform

## 🎓 Conceitos Demonstrados

### GitOps
- ✅ Git como fonte única da verdade
- ✅ Deploy declarativo (não imperativo)
- ✅ Sincronização automática
- ✅ Self-healing (correção automática de drift)

### DevOps
- ✅ CI/CD automatizado
- ✅ Rolling updates (zero downtime)
- ✅ Rollback rápido e seguro
- ✅ Observabilidade (Istio metrics)

### Cloud Native
- ✅ Microservices architecture
- ✅ Service mesh (Istio)
- ✅ Container orchestration (K8s)
- ✅ Infrastructure as Code (Terraform)

## 🤝 Como Usar na Sua Apresentação

1. **Clone o repo** em uma máquina limpa
2. **Configure kubectl** para seu cluster EKS
3. **Mostre v1.0** funcionando (sem "Versão 2.0")
4. **Execute git checkout** para commit v2.0
5. **Aguarde ArgoCD sync** (3 min) ou force restart
6. **Mostre v2.0** funcionando (com "Versão 2.0 🚀")
7. **Faça rollback** via git checkout
8. **Destaque:** Zero comandos kubectl apply!

## 📞 Troubleshooting

Ver [DEMO-FROM-SCRATCH.md](DEMO-FROM-SCRATCH.md) seção "Troubleshooting"

---

**Status:** ✅ Produção  
**Última atualização:** 2024-12-30  
**Autor:** Lab GitOps Demo

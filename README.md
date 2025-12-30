# 🚀 Lab GitOps - E-Commerce Platform

> **Demonstração prática de GitOps** com Kubernetes (EKS), Istio Service Mesh e ArgoCD para deploy automatizado de aplicação e-commerce.

[![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4?style=flat-square&logo=terraform)](https://www.terraform.io/)
[![Kubernetes](https://img.shields.io/badge/K8s-EKS-326CE5?style=flat-square&logo=kubernetes)](https://kubernetes.io/)
[![Istio](https://img.shields.io/badge/Service_Mesh-Istio-466BB0?style=flat-square&logo=istio)](https://istio.io/)
[![ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-EF7B4D?style=flat-square&logo=argo)](https://argoproj.github.io/cd/)

---

## 🎯 O Que Este Projeto Demonstra

✅ **GitOps Puro** - Deploy 100% automatizado via Git (sem `kubectl apply` manual)  
✅ **Infrastructure as Code** - Terraform gerencia VPC, EKS e toda infraestrutura  
✅ **Service Mesh** - Istio para controle de tráfego, observabilidade e mTLS  
✅ **Zero Downtime** - Rolling updates com 3 replicas e health checks  
✅ **Rollback Simples** - Via `git checkout` ou `git revert`  
✅ **Rastreabilidade** - Todo deploy tem commit Git com auditoria completa  

---

## 🏗️ Arquitetura

```
┌─────────────┐       ┌──────────────┐       ┌─────────────┐
│   GitHub    │──────▶│   ArgoCD     │──────▶│ Kubernetes  │
│ (Git Repo)  │       │ (GitOps)     │       │   (EKS)     │
└─────────────┘       └──────────────┘       └─────────────┘
      ▲                                              │
      │                                              ▼
      │                                       ┌─────────────┐
      │                                       │   Istio     │
      │                                       │ Service Mesh│
      │                                       └─────────────┘
      │                                              │
      └──────────────────────────────────────────────┘
                  Git como Fonte Única da Verdade
```

**Stack:**
- **Cloud:** AWS (EKS, ECR, VPC, ALB)
- **IaC:** Terraform
- **Orchestration:** Kubernetes 1.28+
- **Service Mesh:** Istio 1.27
- **GitOps:** ArgoCD
- **App:** React 18 + Express.js + 6 microserviços

---

## 🚀 Quick Start

### Pré-requisitos

```bash
# Ferramentas necessárias
- AWS CLI 2.x configurado
- kubectl 1.28+
- Terraform 1.6+
- Git 2.x+
```

### 1. Deploy Completo (15-20 min)

```bash
# Clone o repositório
git clone https://github.com/jlui70/lab-gitops-argocd.git
cd lab-gitops-argocd

# Configure AWS
aws configure
aws eks update-kubeconfig --region us-east-1 --name eks-cluster-istio

# Deploy completo: Infra + Istio + ArgoCD + App
./rebuild-all-with-gitops.sh
```

Após o deploy, acesse:
- **App E-commerce:** http://<ALB-DNS>/
- **Kiali Dashboard:** http://<ALB-DNS>:20001/kiali
- **Grafana:** http://<ALB-DNS>:3000

### 2. Demonstração GitOps (v1.0 → v2.0)

```bash
# Script interativo completo
./demo-completa-gitops.sh
```

**OU manual:**

```bash
# 1. Verificar v1.0 rodando
kubectl get deployment ecommerce-ui -n ecommerce-staging

# 2. Deploy v2.0 via GitOps
git checkout a6f0d3d  # Commit v2.0

# 3. ArgoCD detecta e aplica automaticamente (3 min)
# Ou force: kubectl rollout restart deployment/ecommerce-ui -n ecommerce-staging

# 4. Rollback para v1.0
git checkout 6768cd5  # Commit v1.0
```

### 3. Destroy (Limpeza Completa)

```bash
./destroy-all.sh
```

---

## 📁 Estrutura do Projeto

```
lab-gitops-argocd/
├── 00-backend/              # Terraform backend (S3 + DynamoDB)
├── 01-networking/           # VPC, subnets, NAT gateways
├── 02-eks-cluster/          # EKS cluster + node groups + addons
│
├── argocd/                  # ArgoCD Applications
│   └── applications/
│       ├── staging-app.yaml
│       └── production-app.yaml
│
├── k8s-manifests/           # Kubernetes manifests (GitOps source)
│   ├── base/                # Base configurations
│   ├── staging/             # Staging overlay
│   └── production/          # Production overlay
│
├── ecommerce-app-v2/        # Código fonte v2.0
│   ├── client/              # React frontend
│   ├── server/              # Express backend
│   └── Dockerfile
│
├── istio/                   # Istio configurations
│   └── manifests/
│
├── scripts/                 # Scripts auxiliares
│
├── docs/                    # 📚 Documentação completa
│   ├── CHECKLIST-PRE-APRESENTACAO.md
│   ├── DEMO-FROM-SCRATCH.md
│   ├── README-DEMO.md
│   └── ROTEIRO-APRESENTACAO-COMPLETO.md
│
├── demo-completa-gitops.sh  # 🎬 Demo interativa
├── rebuild-all-with-gitops.sh
├── destroy-all.sh
└── README.md                # 👈 Você está aqui
```

---

## 🎬 Demonstração Completa

### Fluxo GitOps: v1.0 → v2.0

```bash
# Execute o script interativo
./demo-completa-gitops.sh
```

**O que o script demonstra:**

1. ✅ **v1.0 em produção** - App funcionando com mensagem original
2. ✅ **Simular uso** - Navegação, compras, APIs
3. ✅ **Mudança de código** - Dev comita alteração (Versão 2.0 🚀)
4. ✅ **ArgoCD sync** - Detecta mudança no Git automaticamente
5. ✅ **Rolling update** - Kubernetes aplica mudança (zero downtime)
6. ✅ **v2.0 validada** - Nova versão funcionando perfeitamente
7. ✅ **Rollback** - Volta para v1.0 via Git

**Tempo total:** ~25 minutos

---

## 🔑 Commits Importantes

```bash
# Ver histórico
git log --oneline --graph

# Commits principais:
a6f0d3d - Deploy v2.0 (mensagem "Versão 2.0 🚀")
6768cd5 - Rollback v1.0 (imagem rslim087)
```

**Para testar:**

```bash
# Deploy v2.0
git checkout a6f0d3d

# Rollback v1.0
git checkout 6768cd5
```

---

## 📚 Documentação

- **[Demonstração do Zero](docs/DEMO-FROM-SCRATCH.md)** - Guia completo passo a passo
- **[Roteiro de Apresentação](docs/ROTEIRO-APRESENTACAO-COMPLETO.md)** - Timing e boas práticas
- **[Checklist Pré-Apresentação](docs/CHECKLIST-PRE-APRESENTACAO.md)** - Validação antes do demo
- **[README Demo](docs/README-DEMO.md)** - Quick reference
- **[README Original](docs/README-ORIGINAL.md)** - Documentação técnica completa

---

## 🎓 Conceitos GitOps Demonstrados

### ✅ Git como Fonte Única da Verdade

- Todo estado desejado está no Git
- Cluster Kubernetes converge para o estado declarado
- Auditoria completa via `git log`

### ✅ Deploy Declarativo (não Imperativo)

```bash
# ❌ Modo tradicional (imperativo)
kubectl apply -f deployment.yaml
kubectl set image deployment/app app=v2.0

# ✅ GitOps (declarativo)
git commit -m "Update to v2.0"
git push
# ArgoCD aplica automaticamente
```

### ✅ Sincronização Automática

- ArgoCD faz polling do Git (3 min)
- Detecta diferenças: Git ↔ Cluster
- Aplica mudanças automaticamente
- Self-healing: corrige drift

### ✅ Rollback Simples e Seguro

```bash
# Rollback via Git
git revert HEAD
git push

# OU
git checkout <commit-anterior>
git push --force
```

---

## 🛠️ Comandos Úteis

### Verificar Status

```bash
# Cluster
kubectl get nodes
kubectl get pods -A

# Aplicação
kubectl get deployment ecommerce-ui -n ecommerce-staging
kubectl get pods -n ecommerce-staging -l app=ecommerce-ui

# ArgoCD
kubectl get application -n argocd
kubectl describe application ecommerce-staging -n argocd
```

### Testar APIs

```bash
APP_URL="http://$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"

# Products API
curl -s $APP_URL/api/products | jq 'length'  # Deve retornar: 12

# Inventory API
curl -s $APP_URL/api/inventory | jq 'length'  # Deve retornar: 12
```

### Forçar Deploy

```bash
# Se ArgoCD demorar, force restart
kubectl rollout restart deployment/ecommerce-ui -n ecommerce-staging
kubectl rollout status deployment/ecommerce-ui -n ecommerce-staging
```

### Logs e Debug

```bash
# Ver logs da aplicação
kubectl logs -n ecommerce-staging -l app=ecommerce-ui --tail=50

# Ver eventos
kubectl get events -n ecommerce-staging --sort-by='.lastTimestamp'

# Descrever pod
kubectl describe pod <pod-name> -n ecommerce-staging
```

---

## 🔧 Troubleshooting

### ArgoCD não sincroniza?

```bash
# Verificar status
kubectl get application ecommerce-staging -n argocd

# Ver detalhes
kubectl describe application ecommerce-staging -n argocd

# Forçar sync
kubectl rollout restart deployment/ecommerce-ui -n ecommerce-staging
```

### Aplicação não responde?

```bash
# Verificar pods
kubectl get pods -n ecommerce-staging

# Ver logs
kubectl logs -n ecommerce-staging -l app=ecommerce-ui

# Verificar services
kubectl get svc -n ecommerce-staging
```

### Problemas com Load Balancer?

```bash
# Verificar ALB
kubectl get svc istio-ingressgateway -n istio-system

# Ver eventos do service
kubectl describe svc istio-ingressgateway -n istio-system
```

---

## 📊 Observabilidade

Após o deploy, acesse os dashboards:

**Kiali (Service Mesh Visualization):**
```bash
# URL com port-forward
kubectl port-forward svc/kiali -n istio-system 20001:20001
# Acesse: http://localhost:20001/kiali
```

**Grafana (Metrics & Dashboards):**
```bash
kubectl port-forward svc/grafana -n istio-system 3000:3000
# Acesse: http://localhost:3000
```

**Prometheus (Metrics):**
```bash
kubectl port-forward svc/prometheus -n istio-system 9090:9090
# Acesse: http://localhost:9090
```

---

## 💰 Custos AWS (Estimativa)

| Recurso | Custo/mês | Observação |
|---------|-----------|------------|
| EKS Cluster | $73 | Cluster fee fixo |
| EC2 (2x t3.medium) | ~$60 | Node groups |
| NAT Gateways (2x) | ~$65 | Alta disponibilidade |
| ALB | ~$20 | Load balancer |
| ECR | ~$1 | Storage de imagens |
| **TOTAL** | **~$220/mês** | Estimativa us-east-1 |

**⚠️ Importante:** Execute `./destroy-all.sh` após testes para evitar custos!

---

## 🤝 Contribuindo

Este projeto é para fins educacionais e demonstração de conceitos GitOps.

**Para usar em produção:**
- [ ] Configurar HTTPS/TLS (ACM + Route53)
- [ ] Implementar Network Policies
- [ ] Configurar WAF para ALB
- [ ] Adicionar CI/CD pipeline (GitHub Actions)
- [ ] Implementar secret management (AWS Secrets Manager)
- [ ] Configurar backup/restore
- [ ] Adicionar testes automatizados
- [ ] Implementar monitoramento de custos

---

## 📞 Links Úteis

- **Repositório:** https://github.com/jlui70/lab-gitops-argocd
- **Terraform Docs:** https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Istio Docs:** https://istio.io/latest/docs/
- **ArgoCD Docs:** https://argo-cd.readthedocs.io/
- **Kubernetes Docs:** https://kubernetes.io/docs/

---

## 📄 Licença

Este projeto é open source e está disponível sob a [MIT License](LICENSE).

---

## ✨ Autor

**Lab GitOps Demo**  
Demonstração prática de GitOps para ambientes Kubernetes

**Stack:** AWS EKS • Istio • ArgoCD • Terraform • React • Express.js

---

<p align="center">
  <sub>Construído com ❤️ para demonstração de conceitos GitOps</sub>
</p>

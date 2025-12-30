# Projeto EKS + Istio + GitOps - Stack DevOps Completa

<p align="center">
  <img src="https://img.shields.io/badge/IaC-Terraform-623CE4?style=for-the-badge&logo=terraform&logoColor=white" />
  <img src="https://img.shields.io/badge/Kubernetes-K8s-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" />
  <img src="https://img.shields.io/badge/Service_Mesh-Istio-466BB0?style=for-the-badge&logo=istio&logoColor=white" />
  <img src="https://img.shields.io/badge/GitOps-ArgoCD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white" />
  <img src="https://img.shields.io/badge/CI/CD-GitHub_Actions-2088FF?style=for-the-badge&logo=github-actions&logoColor=white" />
  <img src="https://img.shields.io/badge/Cloud-AWS-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white" />
  <img src="https://img.shields.io/badge/Observability-Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white" />
  <img src="https://img.shields.io/badge/Monitoring-Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white" />
</p>

> **Stack DevOps Completa:** Terraform (IaC) + EKS (Kubernetes) + Istio (Service Mesh) + ArgoCD (GitOps) + GitHub Actions (CI/CD) + Observabilidade Total para deploy de aplicação E-commerce com 7 microserviços em ambientes Staging e Production.

---

## 🎯 Objetivo do Projeto

Demonstrar uma **stack completa de DevOps/GitOps production-grade** com:

- ✅ **Infraestrutura como Código** - Terraform para VPC, EKS, Networking
- ✅ **Service Mesh** - Istio para controle de tráfego, mTLS e observabilidade
- ✅ **GitOps** - ArgoCD para Continuous Deployment declarativo
- ✅ **CI/CD** - GitHub Actions para build, test e deploy automatizado
- ✅ **Multi-ambiente** - Staging (auto-deploy) e Production (manual approval)
- ✅ **Observabilidade Total** - Prometheus, Grafana, Kiali, Jaeger
- ✅ **Rollback em 30s** - Múltiplas estratégias de rollback
- ✅ **Segurança** - Scanning, secrets management, RBAC, network policies

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                      AWS CLOUD (us-east-1)                      │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  VPC (10.0.0.0/22)                                        │  │
│  │                                                           │  │
│  │  ┌──────────────┐        ┌──────────────┐                │  │
│  │  │ Public 1a    │        │ Public 1b    │                │  │
│  │  │ 10.0.0.0/26  │        │ 10.0.0.64/26 │                │  │
│  │  │ NAT Gateway  │        │ NAT Gateway  │                │  │
│  │  └──────┬───────┘        └───────┬──────┘                │  │
│  │         │                        │                        │  │
│  │  ┌──────┴────────────────────────┴──────┐                │  │
│  │  │     Internet Gateway                 │                │  │
│  │  └──────────────────────────────────────┘                │  │
│  │         │                        │                        │  │
│  │  ┌──────┴───────┐        ┌───────┴──────┐                │  │
│  │  │ Private 1a   │        │ Private 1b   │                │  │
│  │  │ 10.0.1.0/26  │        │ 10.0.1.64/26 │                │  │
│  │  │              │        │              │                │  │
│  │  │ ┌──────────────────────────────────┐ │                │  │
│  │  │ │   EKS Cluster (v1.32)            │ │                │  │
│  │  │ │                                  │ │                │  │
│  │  │ │   ┌─────────────────────────┐   │ │                │  │
│  │  │ │   │ Istio Control Plane     │   │ │                │  │
│  │  │ │   │  - istiod               │   │ │                │  │
│  │  │ │   │  - Ingress Gateway (NLB)│   │ │                │  │
│  │  │ │   └─────────────────────────┘   │ │                │  │
│  │  │ │                                  │ │                │  │
│  │  │ │   ┌─────────────────────────┐   │ │                │  │
│  │  │ │   │ Namespace: ecommerce    │   │ │                │  │
│  │  │ │   │  + Frontend (React)     │   │ │                │  │
│  │  │ │   │  + Product Catalog v1   │   │ │                │  │
│  │  │ │   │  + Product Catalog v2   │   │ │                │  │
│  │  │ │   │  + MongoDB              │   │ │                │  │
│  │  │ │   │                         │   │ │                │  │
│  │  │ │   │  Canary: 80% v1 / 20% v2│   │ │                │  │
│  │  │ │   └─────────────────────────┘   │ │                │  │
│  │  │ │                                  │ │                │  │
│  │  │ │   ┌─────────────────────────┐   │ │                │  │
│  │  │ │   │ Observability Stack     │   │ │                │  │
│  │  │ │   │  - Prometheus           │   │ │                │  │
│  │  │ │   │  - Grafana              │   │ │                │  │
│  │  │ │   │  - Kiali                │   │ │                │  │
│  │  │ │   │  - Jaeger               │   │ │                │  │
│  │  │ │   └─────────────────────────┘   │ │                │  │
│  │  │ │                                  │ │                │  │
│  │  │ │   3x Nodes t3.medium             │ │                │  │
│  │  │ └──────────────────────────────────┘ │                │  │
│  │  └──────────────────────────────────────┘                │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## � Novidade: GitOps Implementation

Este projeto agora inclui **implementação completa de GitOps** com ArgoCD e GitHub Actions!

### **O que há de novo:**

- 🔄 **ArgoCD** - Continuous Deployment declarativo (Git → Kubernetes)
- 🤖 **GitHub Actions** - CI/CD pipeline completo (Build → Test → Deploy)
- 🌍 **Multi-ambiente** - Staging (auto-deploy) e Production (manual approval)
- 🐳 **Dockerfiles** - Production-ready para todos os microserviços
- 📦 **Kustomize** - Gerenciamento de manifests por ambiente
- ↩️ **Rollback rápido** - 30 segundos via ArgoCD
- 🔐 **Segurança** - Scanning, secrets, RBAC

### **Quick Start GitOps:**

```bash
# Deploy completo (infra + GitOps)
./scripts/deploy-gitops-stack.sh

# Ver status
./scripts/get-status.sh
```

**📚 Documentação GitOps completa:** [GITOPS-GUIDE.md](GITOPS-GUIDE.md)  
**🚀 Quick Start:** [QUICK-START.md](QUICK-START.md)  
**📊 Resumo da Implementação:** [IMPLEMENTATION-SUMMARY.md](IMPLEMENTATION-SUMMARY.md)

---

## 📦 Componentes do Projeto

### **Terraform Stacks:**

| Stack | Descrição | Recursos | Tempo |
|-------|-----------|----------|-------|
| **00-backend** | S3 + DynamoDB para state | 3 | ~1 min |
| **01-networking** | VPC + Subnets + NAT Gateways | 21 | ~2 min |
| **02-eks-cluster** | EKS + Node Group + Add-ons | 39 | ~15 min |

### **GitOps Components:** ✨ NOVO

| Componente | Descrição | Localização |
|------------|-----------|-------------|
| **ArgoCD** | GitOps continuous deployment | `argocd/` |
| **GitHub Actions** | CI/CD pipelines | `.github/workflows/` |
| **Kustomize Manifests** | K8s configs por ambiente | `k8s-manifests/` |
| **Dockerfiles** | Container definitions | `microservices/` |
| **Automation Scripts** | Deploy e status scripts | `scripts/` |

### **Istio Components:**

- 🕸️ **Istio Service Mesh** (v1.27.0)
  - Control Plane (istiod)
  - Ingress Gateway (Network Load Balancer)
  - Sidecar Injection automático

- 📊 **Observability Stack:**
  - **Prometheus** - Coleta de métricas
  - **Grafana** - Visualização de dashboards
  - **Kiali** - Topologia de serviços e tráfego
  - **Jaeger** - Distributed tracing

### **Aplicação E-commerce:**

- **Frontend** (React) - Interface do usuário
- **Product Catalog v1** - Versão original (80% do tráfego)
- **Product Catalog v2** - Nova versão (20% do tráfego - Canary)
- **MongoDB** - Banco de dados

---

## 🚀 Deploy Automatizado em 4 Comandos

### **Opção 1: Deploy Completo Automatizado** ⭐ RECOMENDADO

```bash
# Clone o repositório
git clone https://github.com/jlui70/lab-istio-mesh-kiali-eks-terraform
cd istio-eks-terraform-complete

# Configure perfil AWS (IMPORTANTE!)
export AWS_PROFILE=devopsproject  # Perfil que assume terraform-role

# Execute deploy automatizado
./rebuild-all.sh
```

**⏱️ Tempo total:** ~35 minutos  
**💰 Custo AWS:** ~$2 USD (se destruir após 2 horas)

### **Opção 2: Deploy Passo a Passo**

```bash
# 1. Deploy infraestrutura (VPC + EKS)
./scripts/01-deploy-infra.sh       # ~15 min

# 2. Instalar Istio Service Mesh
./scripts/02-install-istio.sh      # ~5 min

# 3. Deploy aplicação E-commerce
./scripts/03-deploy-app.sh         # ~3 min

# 4. Iniciar dashboards de observabilidade
./scripts/04-start-monitoring.sh   # ~1 min
```

---

## 📋 Pré-requisitos

Certifique-se de ter instalado:

- ✅ **AWS Account** com permissões administrativas
- ✅ **AWS CLI** configurado (v2.x)
- ✅ **Terraform** (v1.9+)
- ✅ **kubectl** (compatível com EKS 1.32)
- ✅ **istioctl** (v1.27.0)

### **Configuração AWS Profile**

```bash
# Verifique seu perfil AWS
aws sts get-caller-identity

# IMPORTANTE: Use perfil que assume terraform-role
# O cluster é configurado com access entries para terraform-role
export AWS_PROFILE=devopsproject
```

> ⚠️ **CRÍTICO:** O cluster EKS é criado com access entries para `terraform-role`. Se você usar IAM User diretamente, precisará trocar para um perfil que assume essa role após o deploy para acessar o cluster via kubectl.

---

## 💰 Estimativa de Custos AWS

| Cenário | Duração | Custo Estimado |
|---------|---------|----------------|
| **Teste Rápido** | 2 horas | ~$2 USD |
| **Estudo Completo** | 8 horas | ~$8 USD |
| **24/7 (não recomendado)** | 1 mês | ~$180 USD |

**Principais componentes:**
- 3x EC2 t3.medium (workers) - ~$50/mês
- EKS Cluster - ~$73/mês
- 2x NAT Gateways - ~$65/mês
- Network Load Balancer - ~$20/mês
- Transferência de dados - variável

> ⚠️ **IMPORTANTE:** Execute `./destroy-all.sh` após os testes para evitar custos contínuos!

---

## 🌐 Acessando os Dashboards

Após deploy completo, acesse:

```bash
# Prometheus (métricas)
http://localhost:9090

# Grafana (dashboards)
http://localhost:3000
# User: admin | Pass: admin

# Kiali (topologia e canary deployment)
http://localhost:20001
# Graph → Namespace: ecommerce → Display: Traffic Distribution

# Jaeger (distributed tracing)
http://localhost:16686
```

---

## 🎨 Demonstração: Canary Deployment 80/20

### **Passo 1: Gerar tráfego**

```bash
./test-canary-visual.sh
```

### **Passo 2: Visualizar no Kiali**

1. Abra **http://localhost:20001**
2. Vá em **Graph**
3. Selecione namespace **ecommerce**
4. Em **Display**, marque **Traffic Distribution**
5. Você verá:
   - 80% do tráfego indo para `product-catalog-v1`
   - 20% do tráfego indo para `product-catalog-v2`

### **Passo 3: Validar Métricas no Prometheus**

Abra **http://localhost:9090** e execute as queries:

**Ver todas as requisições do namespace ecommerce:**
```promql
istio_requests_total{destination_service_namespace="ecommerce"}
```

**Ver distribuição de tráfego por versão (Canary 80/20):**
```promql
sum by (destination_service_name, destination_version) (
  istio_requests_total{destination_service_namespace="ecommerce"}
)
```

**Ver taxa de requisições (últimos 5 min):**
```promql
rate(istio_requests_total{destination_service_namespace="ecommerce"}[5m])
```

**Ver latência p99:**
```promql
histogram_quantile(0.99, 
  sum(rate(istio_request_duration_milliseconds_bucket{
    destination_service_namespace="ecommerce"
  }[5m])) by (le, destination_service_name)
)
```

---

## 🗑️ Destruir Infraestrutura

Para evitar custos AWS contínuos:

```bash
./destroy-all.sh
```

**O script remove automaticamente:**
- ✅ Namespace ecommerce (aplicação)
- ✅ Istio Service Mesh
- ✅ EKS Cluster + Node Group
- ✅ VPC + Subnets + NAT Gateways
- ❓ Backend (S3 + DynamoDB) - pergunta antes de deletar

**⏱️ Tempo:** ~15-20 minutos

**💰 Custo após destroy:** $0/mês

---

## 📚 Documentação Adicional

- **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Soluções para 10 problemas comuns
- **[QUICK-START.md](./QUICK-START.md)** - Referência rápida de comandos
- **[DEMO-CANARY.md](./DEMO-CANARY.md)** - Guia completo de demonstração Canary
- **[OBSERVABILITY.md](./OBSERVABILITY.md)** - Dashboards e métricas
- **[PROJECT-STATUS.md](./PROJECT-STATUS.md)** - Histórico do projeto
- **[PRE-COMMIT-CHECKLIST.md](./PRE-COMMIT-CHECKLIST.md)** - Checklist para contribuidores

---

## 🔧 Troubleshooting

### **Erro: "Kubernetes cluster unreachable"**

**Causa:** Perfil AWS incorreto.

**Solução:**
```bash
export AWS_PROFILE=devopsproject  # Perfil que assume terraform-role
aws eks update-kubeconfig --region us-east-1 --name eks-devopsproject-cluster
kubectl get nodes
```

Veja mais soluções em [TROUBLESHOOTING.md](./TROUBLESHOOTING.md).

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o repositório
2. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'feat: Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

---

## 🙏 Créditos e Agradecimentos

Este projeto foi inspirado e baseado no excelente trabalho de:

### **Rayan Slim**
- 📹 **Canal YouTube:** [@RayanSlim087](https://www.youtube.com/@RayanSlim087)
- 🎓 Referência principal para arquitetura Istio Service Mesh
- 🌟 Agradecimento especial pela didática e conteúdo de qualidade

**Adaptações realizadas neste projeto:**
- ✅ Automação completa com scripts bash
- ✅ Integração com Terraform para infraestrutura AWS
- ✅ Documentação em português
- ✅ Troubleshooting guide completo
- ✅ Scripts de destroy robustos

---

## 📜 Licença

Este projeto está sob licença **MIT**. Veja o arquivo [LICENSE](./LICENSE) para mais detalhes.

---

## 📞 Contato e Suporte

### 🌐 Conecte-se Comigo

- 📹 **YouTube:** [DevOps Project](https://www.youtube.com/@devops-project)
- 💼 **Portfólio:** [devopsproject.com.br](https://devopsproject.com.br/)
- 💻 **GitHub:** [@jlui70](https://github.com/jlui70)

---

### 🌟 Gostou do Projeto?

Se este projeto foi útil para você:

- ⭐ Dê uma **estrela** no repositório
- 🔄 **Compartilhe** com a comunidade
- 📹 **Inscreva-se** no canal do YouTube
- 🤝 **Contribua** com melhorias

<div align="center">

**🚀 Production-grade infrastructure com Terraform + Istio**

[![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4?style=for-the-badge&logo=terraform)](https://www.terraform.io/)
[![Istio](https://img.shields.io/badge/Service_Mesh-Istio-466BB0?style=for-the-badge&logo=istio)](https://istio.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-K8s-326CE5?style=for-the-badge&logo=kubernetes)](https://kubernetes.io/)
[![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?style=for-the-badge&logo=amazon-aws)](https://aws.amazon.com/)

</div>

---

<p align="center">
  <strong>Desenvolvido com ❤️ para a comunidade brasileira de DevOps, SRE e Cloud Engineering</strong>
</p>

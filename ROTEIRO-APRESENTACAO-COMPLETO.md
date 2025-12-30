# 🎬 Roteiro de Apresentação GitOps

Guia rápido para executar a demonstração completa do zero.

## 📋 Pré-requisitos

- ✅ Scripts validados: `destroy-all.sh` e `rebuild-all-with-gitops.sh`
- ✅ Repositório: https://github.com/jlui70/lab-gitops-argocd
- ✅ AWS CLI e kubectl configurados

## 🚀 Fluxo da Apresentação

### 1️⃣ PREPARAÇÃO (Antes da Apresentação)

```bash
# Executar destroy (se necessário)
./destroy-all.sh

# Executar rebuild completo
./rebuild-all-with-gitops.sh
# ⏰ Tempo estimado: 15-20 minutos
```

### 2️⃣ INÍCIO DA APRESENTAÇÃO

**Mostrar v1.0 funcionando:**

```bash
# Abrir navegador na URL
http://aea55d7dff98f43afa1b5a3ce75aa411-126944.us-east-1.elb.amazonaws.com/

# Verificar estado
kubectl get deployment ecommerce-ui -n ecommerce-staging
kubectl get pods -n ecommerce-staging -l app=ecommerce-ui
```

**Pontos para destacar:**
- ✅ Aplicação e-commerce funcionando
- ✅ Mensagem: "Welcome to the E-commerce App" (SEM "Versão 2.0")
- ✅ Todas as APIs funcionando: Products, Inventory, Orders, etc

**Simular uso:**
- Navegar pelo catálogo
- Ver detalhes de produtos
- Adicionar ao carrinho
- Simular compra

### 3️⃣ EXPLICAR ARQUITETURA GITOPS

**Mostrar estrutura:**
```bash
# Mostrar arquivos ArgoCD
cat argocd/applications/staging-app.yaml

# Destacar:
# - repoURL: https://github.com/jlui70/lab-gitops-argocd.git
# - syncPolicy.automated
# - prune: true, selfHeal: true
```

**Explicar fluxo:**
```
Developer → Git Commit → ArgoCD Detect → Kubernetes Apply → Production
    ↑                                                           ↓
    └──────────────── Git is Source of Truth ─────────────────┘
```

### 4️⃣ DEMONSTRAR MUDANÇA DE CÓDIGO

**Mostrar código atual:**
```bash
cat ecommerce-app-v2/client/src/pages/Home.js | grep -A 2 "Welcome"
```

**Explicar:**
- "Vamos simular que um desenvolvedor fez uma mudança"
- "Ele quer adicionar 'Versão 2.0 🚀' na mensagem"
- "A mudança já está em um commit no Git"

**Mostrar histórico:**
```bash
git log --oneline --graph -5

# Destacar:
# a6f0d3d - Deploy v2.0 - Welcome message com Versão 2.0 🚀
# 6768cd5 - Rollback to v1.0 - Restore rslim087 original image
```

### 5️⃣ EXECUTAR DEPLOY v2.0 VIA GITOPS

**Opção A - Script Automatizado (RECOMENDADO):**
```bash
./demo-completa-gitops.sh
```
- ✅ Script interativo guia toda a apresentação
- ✅ Mostra cada etapa claramente
- ✅ Aguarda confirmação entre passos

**Opção B - Manual (Para mais controle):**
```bash
# Fazer checkout para v2.0
git checkout a6f0d3d

# Mostrar mudança no manifest
cat k8s-manifests/base/ecommerce-ui.yaml | grep "image:"

# Aguardar ArgoCD (3 min) ou forçar:
kubectl rollout restart deployment/ecommerce-ui -n ecommerce-staging

# Acompanhar rollout
kubectl rollout status deployment/ecommerce-ui -n ecommerce-staging
```

### 6️⃣ VALIDAR v2.0

**Verificar deployment:**
```bash
kubectl get deployment ecommerce-ui -n ecommerce-staging -o wide
kubectl get pods -n ecommerce-staging -l app=ecommerce-ui
```

**Destacar mudanças:**
- ✅ Imagem mudou: `794038226274.dkr.ecr.us-east-1.amazonaws.com/ecommerce/ecommerce-ui:v2.0`
- ✅ Rolling update sem downtime
- ✅ 3 replicas sempre disponíveis

**Mostrar aplicação:**
```bash
# Abrir navegador (mesma URL)
http://aea55d7dff98f43afa1b5a3ce75aa411-126944.us-east-1.elb.amazonaws.com/
```

**Pontos para destacar:**
- ✅ Mensagem agora mostra: "Welcome to the E-commerce App - Versão 2.0 🚀"
- ✅ Todas as APIs continuam funcionando
- ✅ Produtos, carrinho, tudo OK
- ✅ Zero downtime durante deploy

**Simular uso v2.0:**
- Navegar novamente
- Fazer novas compras
- Mostrar que tudo funciona igual

### 7️⃣ DEMONSTRAR RASTREABILIDADE

```bash
# Mostrar auditoria via Git
git log --oneline --all

# Mostrar diff entre v1.0 e v2.0
git diff 6768cd5 a6f0d3d

# Mostrar mudança específica no código
git diff 6768cd5 a6f0d3d -- ecommerce-app-v2/client/src/pages/Home.js

# Mostrar mudança no manifest
git diff 6768cd5 a6f0d3d -- k8s-manifests/base/ecommerce-ui.yaml
```

### 8️⃣ DEMONSTRAR ROLLBACK (OPCIONAL)

**Se houver tempo, mostrar rollback:**
```bash
# Fazer rollback via Git
git checkout 6768cd5

# ArgoCD detecta e reverte automaticamente (3 min)
# Ou forçar:
kubectl rollout restart deployment/ecommerce-ui -n ecommerce-staging

# Validar volta para v1.0
kubectl get deployment ecommerce-ui -n ecommerce-staging -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### 9️⃣ CONCLUSÃO

**Destacar benefícios do GitOps:**

✅ **Automatização Total:**
- Zero comandos `kubectl apply` manuais
- ArgoCD cuida de tudo automaticamente

✅ **Rastreabilidade:**
- Todo deploy tem commit Git
- Histórico completo via `git log`
- Fácil auditoria

✅ **Rollback Simples:**
- `git checkout` ou `git revert`
- ArgoCD aplica automaticamente
- Rápido e seguro

✅ **Declarativo:**
- Git é a fonte única da verdade
- Estado desejado no repositório
- Cluster converge para o estado desejado

✅ **Self-Healing:**
- ArgoCD detecta drift automaticamente
- Corrige mudanças manuais
- Mantém consistência

**Arquitetura demonstrada:**
- ✅ Kubernetes (EKS)
- ✅ Istio Service Mesh
- ✅ ArgoCD GitOps
- ✅ Terraform IaC
- ✅ Docker Containers
- ✅ AWS ECR
- ✅ React + Express

## 🎯 Timing Sugerido

| Etapa | Tempo | Descrição |
|-------|-------|-----------|
| Preparação | 15-20 min | Executar rebuild-all-with-gitops.sh |
| Intro + v1.0 | 5 min | Mostrar app funcionando, simular compras |
| Explicar GitOps | 5 min | Arquitetura, conceitos, ArgoCD config |
| Demo código | 3 min | Mostrar código, commits, mudanças |
| Deploy v2.0 | 5 min | Checkout, aguardar sync, rollout |
| Validar v2.0 | 5 min | Mostrar app v2.0, simular compras |
| Rastreabilidade | 3 min | Git log, diff, auditoria |
| Rollback (opt) | 5 min | Demonstrar rollback se houver tempo |
| Conclusão | 2 min | Resumir benefícios GitOps |
| **TOTAL** | **35-45 min** | Apresentação completa |

## 📌 Dicas para Apresentação

### ✅ DO's (Faça)

1. **Preparar ambiente antes:**
   - Execute `rebuild-all-with-gitops.sh` antes de começar
   - Confirme v1.0 está funcionando
   - Tenha a URL da aplicação pronta

2. **Usar script automatizado:**
   - `./demo-completa-gitops.sh` guia toda a apresentação
   - Interativo, aguarda confirmação entre passos
   - Mais profissional e organizado

3. **Destacar GitOps:**
   - Enfatize: ZERO comandos kubectl apply
   - Git como fonte única da verdade
   - Automatização completa

4. **Mostrar aplicação funcionando:**
   - Navegue pela UI
   - Simule compras reais
   - Mostre que não é só teoria

5. **Ter backup plan:**
   - Se ArgoCD demorar, force: `kubectl rollout restart`
   - Tenha URLs salvas
   - Commits decorados (a6f0d3d, 6768cd5)

### ❌ DON'Ts (Não faça)

1. **Não execute comandos não testados ao vivo**
2. **Não faça mudanças de código ao vivo** (use commits prontos)
3. **Não aguarde 3 min do ArgoCD** (force restart se necessário)
4. **Não entre em detalhes técnicos** desnecessários
5. **Não mostre erros** (teste tudo antes!)

## 🔧 Troubleshooting Rápido

### Problema: ArgoCD não sincroniza

```bash
# Forçar sync
kubectl rollout restart deployment/ecommerce-ui -n ecommerce-staging
```

### Problema: Aplicação não responde

```bash
# Verificar pods
kubectl get pods -n ecommerce-staging -l app=ecommerce-ui

# Ver logs
kubectl logs -n ecommerce-staging -l app=ecommerce-ui --tail=50
```

### Problema: URL não abre

```bash
# Pegar URL correta
kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Problema: Imagem não atualiza

```bash
# Verificar ArgoCD status
kubectl get application ecommerce-staging -n argocd

# Verificar manifest
cat k8s-manifests/base/ecommerce-ui.yaml | grep "image:"
```

## 📞 Links Úteis

- **Repositório:** https://github.com/jlui70/lab-gitops-argocd
- **Guia Completo:** [DEMO-FROM-SCRATCH.md](DEMO-FROM-SCRATCH.md)
- **README:** [README-DEMO.md](README-DEMO.md)
- **Detalhes v2.0:** [V2-README.md](V2-README.md)

## 🎬 Scripts Disponíveis

```bash
./destroy-all.sh              # Destruir tudo (cuidado!)
./rebuild-all-with-gitops.sh  # Rebuild completo (15-20 min)
./demo-completa-gitops.sh     # Demo interativa completa ⭐
./scripts/demo-gitops-v2.sh   # Demo v2.0 (para ref deploy já feito)
./scripts/rollback-to-v1.sh   # Rollback rápido para v1.0
```

---

**Boa sorte na apresentação! 🚀**

_Última atualização: 2024-12-30_

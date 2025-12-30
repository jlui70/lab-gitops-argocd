# 🚀 Demo GitOps v1.0 → v2.0 - Guia Rápido

## 📋 Estrutura do Projeto

```
istio-eks-terraform-gitops-argocd/
├── microservices/          # ✅ VERSÃO 1.0 (original, intocada)
│   └── ecommerce-ui/
│       └── src/pages/Home.js  → "Welcome to the E-commerce App"
│
├── microservices-v2/       # 🚀 VERSÃO 2.0 (modificada)
│   └── ecommerce-ui/
│       └── src/pages/Home.js  → "Welcome to the E-commerce App - Versão 2.0 🚀"
│
└── scripts/
    └── deploy-v2-simple.sh    # Script para deploy v2.0
```

## 🎯 Workflow de Demonstração

### 1️⃣ Deploy Inicial (v1.0)

O backup já tem tudo funcionando. Se precisar re-deployar:

```bash
./rebuild-all-with-gitops.sh
```

✅ **Resultado:** App rodando com mensagem original
- URL: http://aea55d7dff98f43afa1b5a3ce75aa411-126944.us-east-1.elb.amazonaws.com/
- Mensagem: "Welcome to the E-commerce App"

### 2️⃣ Demo: Upgrade para v2.0 via GitOps

```bash
./scripts/deploy-v2-simple.sh
```

**O que o script faz:**

1. 🐳 **Build** da imagem do `microservices-v2/ecommerce-ui`
2. 📤 **Push** para ECR com tag `v2.0.0`
3. 📝 **Atualiza** manifesto `k8s-manifests/base/ecommerce-ui.yaml`
4. 🚀 **Git push** → Triggers ArgoCD auto-sync
5. ⏳ **Aguarda** ~3 minutos para ArgoCD detectar e deployar

✅ **Resultado:** App atualizado automaticamente via GitOps
- Mensagem: "Welcome to the E-commerce App - Versão 2.0 🚀"

### 3️⃣ Monitorar Deployment

```bash
kubectl rollout status deployment/ecommerce-ui -n ecommerce-staging
kubectl get pods -n ecommerce-staging -l app=ecommerce-ui
```

## 🎬 Roteiro de Apresentação

### **Cenário:** Demonstrar GitOps puro com ArgoCD

1. **Mostrar app v1.0 rodando**
   - Acessar URL
   - Mostrar mensagem original

2. **Explicar mudança fictícia**
   - "Desenvolvedor pediu para adicionar indicador de versão"
   - Mostrar código em `microservices-v2/ecommerce-ui/src/pages/Home.js`

3. **Executar deploy v2.0**
   ```bash
   ./scripts/deploy-v2-simple.sh
   ```

4. **Explicar o que acontece:**
   - ✅ Build da nova imagem
   - ✅ Push para ECR
   - ✅ Commit + Push no Git
   - ✅ ArgoCD detecta mudança automaticamente
   - ✅ Deploy automático sem intervenção manual

5. **Aguardar ~3 minutos**
   - Mostrar ArgoCD UI (opcional)
   - Explicar GitOps principles

6. **Validar v2.0**
   - Refresh da página
   - Mostrar nova mensagem "Versão 2.0 🚀"

## 🔑 Pontos-Chave do GitOps

✅ **Git como fonte da verdade**
- Mudanças commitadas no Git
- Manifesto atualizado no repositório

✅ **Automação completa**
- Sem `kubectl apply` manual
- ArgoCD faz sync automaticamente

✅ **Auditabilidade**
- Todo change tem commit
- Histórico rastreável

✅ **Declarativo**
- Estado desejado no Git
- ArgoCD garante convergência

## 📂 Diferenças entre Versões

| Arquivo | v1.0 (microservices) | v2.0 (microservices-v2) |
|---------|---------------------|-------------------------|
| Home.js | "Welcome to the E-commerce App" | "Welcome to the E-commerce App - Versão 2.0 🚀" |
| package.json | version: "1.0.0" | version: "2.0.0" |
| Imagem Docker | rslim087/ecommerce-ui:latest | 794038226274.dkr.ecr.us-east-1.amazonaws.com/ecommerce/ecommerce-ui:v2.0.0 |

## 🛠️ Comandos Úteis

### Ver logs do ArgoCD
```bash
kubectl logs -n argocd deployment/argocd-application-controller -f
```

### Status do app no ArgoCD
```bash
kubectl get application -n argocd staging-app -o yaml
```

### Forçar sync manual (se necessário)
```bash
argocd app sync staging-app
```

### Rollback para v1.0
```bash
# Reverter manifesto
git revert HEAD~1
git push origin main
# ArgoCD vai sync automaticamente
```

## 🎉 Resumo

Esta estrutura permite:

✅ **Backup seguro** - `microservices/` nunca é modificado
✅ **Demonstração clara** - v2.0 em diretório separado
✅ **GitOps puro** - Deploy via Git + ArgoCD
✅ **Fácil reversão** - Basta fazer git revert
✅ **Reproduzível** - Mesmo fluxo em qualquer máquina

**O backup validado permanece intacto. A versão 2.0 é apenas uma cópia modificada para demonstração!** 🎯

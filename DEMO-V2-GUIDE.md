# 🎬 ROTEIRO DE DEMONSTRAÇÃO - GitOps com Versão 2.0

## 📋 Visão Geral

Este roteiro demonstra um fluxo completo de GitOps, mostrando como uma alteração no código (versão 1.0 → 2.0) é automaticamente deployada via ArgoCD.

---

## 🚀 Fase 1: Deploy Inicial (Versão 1.0)

### 1.1 Executar Deploy Completo

```bash
./rebuild-all-with-gitops.sh
```

**O que acontece:**
- ✅ Deploy da infraestrutura (VPC + EKS)
- ✅ Instalação do Istio + Observabilidade
- ✅ Instalação do ArgoCD
- ✅ Build e push da imagem v1.0.0
- ✅ Deploy via ArgoCD
- ✅ Monitoramento ativo

**Tempo estimado:** ~40 minutos

### 1.2 Validar Versão 1.0

1. Acesse a aplicação (URL fornecida no final do script)
2. Faça login/cadastro
3. **Observe:** Mensagem `"Welcome to the E-commerce App"` (sem número de versão)

---

## 🎯 Fase 2: Demonstração GitOps - Atualização para v2.0

### 2.1 Cenário

**Situação:** Um desenvolvedor fez uma alteração no código para mostrar a versão 2.0 da aplicação.

**Alteração:**
```javascript
// ANTES (v1.0)
<h1>Welcome to the E-commerce App</h1>

// DEPOIS (v2.0)
<h1>Welcome to the E-commerce App - Versão 2.0 🚀</h1>
```

### 2.2 Executar Script de Atualização

```bash
./scripts/demo-update-v2.sh
```

**O que o script faz:**

1. **📋 Verifica versão atual** (v1.0.0 no cluster)

2. **👨‍💻 Mostra alteração do código**
   - Arquivo: `microservices/ecommerce-ui/src/pages/Home.js`
   - Mudança: Adição de "Versão 2.0 🚀"

3. **🐳 Build da imagem Docker**
   - Tag: `v2.0.0`
   - Tag: `staging-latest`

4. **📤 Push para ECR**
   - Imagem enviada para AWS ECR

5. **📝 Atualiza manifesto K8s**
   - Arquivo: `k8s-manifests/staging/ecommerce-ui-deployment.yaml`
   - Nova imagem: `v2.0.0`

6. **🎯 ArgoCD sincroniza automaticamente**
   - Detecta mudança no manifesto
   - Faz rollout do novo deployment

7. **✅ Valida deployment**
   - Aguarda pods ficarem prontos
   - Confirma nova versão

**Tempo estimado:** ~3-5 minutos

### 2.3 Validar Versão 2.0

1. Recarregue a aplicação no navegador
2. Faça login novamente (se necessário)
3. **Observe:** Mensagem `"Welcome to the E-commerce App - Versão 2.0 🚀"`

---

## 🎬 Pontos de Demonstração

### Durante a Demo, Destacar:

1. **GitOps em Ação**
   - Código → Build → Push → ArgoCD detecta → Deploy automático
   
2. **ArgoCD Dashboard**
   - Mostrar sincronização em tempo real
   - Status: Synced / Healthy
   
3. **Zero Downtime**
   - Aplicação continua funcionando durante update
   - Rollout progressivo

4. **Rastreabilidade**
   - Versão da imagem claramente identificada
   - Histórico de deploys no ArgoCD

---

## 🔄 Scripts Auxiliares

### Alternar entre versões (para testes):

**Atualizar para v2.0:**
```bash
./scripts/update-to-v2.sh
```

**Reverter para v1.0:**
```bash
./scripts/rollback-to-v1.sh
```

**Fazer build e push manualmente:**
```bash
cd microservices/ecommerce-ui
docker build -t <ECR_REPO>/ecommerce-ui:v2.0.0 .
docker push <ECR_REPO>/ecommerce-ui:v2.0.0
```

---

## 📊 URLs de Acesso

Após o deploy inicial (`rebuild-all-with-gitops.sh`), você terá:

- **🛒 Aplicação:** http://[GATEWAY-URL]
- **🎯 ArgoCD:** https://[ARGOCD-URL]
  - User: `admin`
  - Pass: (fornecido no output do script)
- **📊 Prometheus:** http://localhost:9090
- **📈 Grafana:** http://localhost:3000
- **🕸️ Kiali:** http://localhost:20001
- **🔍 Jaeger:** http://localhost:16686

---

## 🎤 Pontos de Fala para Apresentação

### Introdução
> "Vamos demonstrar um fluxo completo de GitOps. Começamos com a versão 1.0 já deployada no cluster EKS. Agora um desenvolvedor fez uma alteração simples no código para mostrar que estamos na versão 2.0."

### Durante a Execução do Script
> "O script está automatizando tudo que um desenvolvedor faria manualmente: build da imagem, push para o registro (ECR), e atualização do manifesto Kubernetes."

### ArgoCD Sync
> "Notem que o ArgoCD detectou automaticamente que o manifesto mudou. Ele está comparando o estado desejado (git) com o estado atual (cluster) e aplicando as mudanças necessárias."

### Validação Final
> "E pronto! A aplicação foi atualizada automaticamente. Vamos acessar e ver a nova versão 2.0. Todo esse processo foi automático, sem intervenção manual no cluster."

---

## ✅ Checklist da Demonstração

- [ ] Cluster EKS ativo e acessível
- [ ] Versão 1.0 deployada e funcionando
- [ ] Código em `Home.js` está na versão 1.0
- [ ] Script `demo-update-v2.sh` testado
- [ ] Credenciais AWS configuradas
- [ ] Docker rodando (para build)
- [ ] Navegador aberto com a aplicação
- [ ] ArgoCD dashboard aberto em outra aba

---

## 🐛 Troubleshooting

### Imagem não atualiza
```bash
# Verificar se a imagem foi enviada
aws ecr describe-images --repository-name ecommerce/ecommerce-ui --region us-east-1

# Forçar sync do ArgoCD
kubectl patch application ecommerce-staging -n argocd --type merge -p '{"operation":{"sync":{}}}'
```

### Pods não ficam prontos
```bash
# Ver logs do pod
kubectl logs -n ecommerce-staging -l app=ecommerce-ui --tail=50

# Ver eventos
kubectl get events -n ecommerce-staging --sort-by='.lastTimestamp'
```

### Rollback necessário
```bash
# Reverter imagem
kubectl set image deployment/ecommerce-ui ecommerce-ui=<ECR_REPO>/ecommerce-ui:v1.0.0 -n ecommerce-staging
```

---

## 🎉 Conclusão

Este fluxo demonstra:
- ✅ GitOps funcional com ArgoCD
- ✅ CI/CD automatizado
- ✅ Deploy sem downtime
- ✅ Rastreabilidade completa
- ✅ Fácil rollback se necessário

**Pronto para impressionar! 🚀**

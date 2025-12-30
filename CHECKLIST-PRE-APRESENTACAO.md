# ✅ Checklist Pré-Apresentação GitOps

Use este checklist antes de começar sua apresentação para garantir que tudo está funcionando.

## 📋 Antes da Apresentação (1 dia antes)

### Ambiente AWS
- [ ] Confirmar acesso AWS CLI funcionando
- [ ] Verificar quotas/limites da conta AWS
- [ ] Confirmar região us-east-1 disponível
- [ ] Testar `aws sts get-caller-identity`

### Repositório Git
- [ ] Fork/clone de https://github.com/jlui70/lab-gitops-argocd.git funcionando
- [ ] Git configurado localmente
- [ ] Acesso push ao repositório confirmado
- [ ] Commits v1.0 e v2.0 existem

### Ferramentas
- [ ] kubectl instalado e funcionando
- [ ] aws-cli versão 2.x instalada
- [ ] jq instalado (para parsing JSON)
- [ ] curl instalado
- [ ] Git versão 2.x+

## 🔧 Preparação Técnica (2-3 horas antes)

### 1. Destruir Ambiente Anterior (se existir)

```bash
cd lab-gitops-argocd
./destroy-all.sh
```

**Validar:**
- [ ] Terraform destroy completo (00-backend, 01-networking, 02-eks-cluster)
- [ ] VPC removida
- [ ] Load Balancers removidos
- [ ] EKS cluster removido
- [ ] ECR limpo (ou pelo menos imagens antigas removidas)

**⏰ Tempo:** ~10-15 minutos

### 2. Rebuild Completo

```bash
./rebuild-all-with-gitops.sh
```

**Validar durante execução:**
- [ ] Terraform 00-backend criado
- [ ] Terraform 01-networking OK (VPC, subnets, NAT)
- [ ] Terraform 02-eks-cluster OK (cluster + node groups)
- [ ] Istio instalado (namespace istio-system)
- [ ] ArgoCD instalado (namespace argocd)
- [ ] Aplicação e-commerce deployada
- [ ] Todos os microserviços rodando

**⏰ Tempo:** ~15-20 minutos

### 3. Validação Completa

#### 3.1 Cluster EKS
```bash
# Nodes saudáveis
kubectl get nodes
# Devem mostrar: Ready

# Namespaces existem
kubectl get namespaces | grep -E "(istio|argocd|ecommerce)"
# Deve mostrar: istio-system, argocd, ecommerce-staging
```

**Checklist:**
- [ ] 2-3 nodes Ready
- [ ] Namespace istio-system existe
- [ ] Namespace argocd existe
- [ ] Namespace ecommerce-staging existe

#### 3.2 Istio
```bash
# Istio pods rodando
kubectl get pods -n istio-system
# Todos devem estar Running

# Ingress Gateway com External IP
kubectl get svc istio-ingressgateway -n istio-system
# Deve ter EXTERNAL-IP (AWS ELB)
```

**Checklist:**
- [ ] istiod pod Running
- [ ] istio-ingressgateway pod Running
- [ ] istio-ingressgateway service tem EXTERNAL-IP

#### 3.3 ArgoCD
```bash
# ArgoCD pods rodando
kubectl get pods -n argocd
# Todos devem estar Running

# ArgoCD Application existe
kubectl get application ecommerce-staging -n argocd
# Deve mostrar status Synced
```

**Checklist:**
- [ ] argocd-server pod Running
- [ ] argocd-application-controller pod Running
- [ ] Application ecommerce-staging existe
- [ ] Application status: Synced
- [ ] Application health: Healthy

#### 3.4 Aplicação E-commerce
```bash
# Deployment existe e está pronto
kubectl get deployment ecommerce-ui -n ecommerce-staging
# READY deve ser 3/3

# Pods rodando
kubectl get pods -n ecommerce-staging -l app=ecommerce-ui
# Todos devem estar Running

# Imagem v1.0
kubectl get deployment ecommerce-ui -n ecommerce-staging -o jsonpath='{.spec.template.spec.containers[0].image}'
# Deve ser: rslim087/ecommerce-ui:latest
```

**Checklist:**
- [ ] Deployment ecommerce-ui existe
- [ ] 3/3 replicas Ready
- [ ] Todos os pods Running
- [ ] Imagem é rslim087/ecommerce-ui:latest (v1.0)

#### 3.5 Microserviços Backend
```bash
# Verificar todos os microserviços
kubectl get deployments -n ecommerce-staging
```

**Checklist:**
- [ ] product-catalog Running
- [ ] product-inventory Running
- [ ] order-management Running
- [ ] shipping-and-handling Running
- [ ] contact-support-team Running
- [ ] profile-management Running

#### 3.6 Testar Aplicação
```bash
# Obter URL
APP_URL="http://$(kubectl get svc istio-ingressgateway -n istio-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo $APP_URL

# Testar home page
curl -s $APP_URL | grep -i "html"

# Testar API products
curl -s $APP_URL/api/products | jq 'length'
# Deve retornar: 12

# Testar API inventory
curl -s $APP_URL/api/inventory | jq 'length'
# Deve retornar: 12
```

**Checklist:**
- [ ] URL acessível via curl
- [ ] Home page retorna HTML
- [ ] API /api/products retorna 12 produtos
- [ ] API /api/inventory retorna 12 itens
- [ ] Abrir no navegador e ver interface funcionando
- [ ] Mensagem mostra "Welcome to the E-commerce App" (SEM "Versão 2.0")

#### 3.7 Testar Navegação Completa
**No navegador, testar:**
- [ ] Home page carrega
- [ ] Catálogo de produtos carrega
- [ ] Imagens dos produtos aparecem
- [ ] Detalhes de produto funcionam
- [ ] Orders page funciona
- [ ] Inventory page funciona
- [ ] Shipping page funciona
- [ ] Contact page funciona
- [ ] Profile page funciona

### 4. Preparar Estado v1.0

```bash
# Garantir que está no commit v1.0
cd lab-gitops-argocd
git checkout 6768cd5

# Verificar manifest
cat k8s-manifests/base/ecommerce-ui.yaml | grep "image:"
# Deve mostrar: rslim087/ecommerce-ui:latest

# Se cluster estiver em v2.0, fazer rollback
CURRENT_IMAGE=$(kubectl get deployment ecommerce-ui -n ecommerce-staging -o jsonpath='{.spec.template.spec.containers[0].image}')
if [[ "$CURRENT_IMAGE" == *"v2.0"* ]]; then
  kubectl rollout restart deployment/ecommerce-ui -n ecommerce-staging
  kubectl rollout status deployment/ecommerce-ui -n ecommerce-staging
fi
```

**Checklist:**
- [ ] Git HEAD em commit 6768cd5 (v1.0)
- [ ] Manifest aponta para rslim087/ecommerce-ui:latest
- [ ] Cluster rodando v1.0 (verificar no navegador)

## 📝 Checklist Final (30 min antes)

### Informações Anotadas
- [ ] URL da aplicação: ___________________________________
- [ ] Commit v1.0: 6768cd5
- [ ] Commit v2.0: a6f0d3d
- [ ] Repositório: https://github.com/jlui70/lab-gitops-argocd

### Testes Finais
- [ ] Abrir aplicação no navegador (v1.0)
- [ ] Navegar por 2-3 produtos
- [ ] Simular compra teste
- [ ] Confirmar mensagem SEM "Versão 2.0"

### Backup Plans
- [ ] Script `demo-completa-gitops.sh` testado
- [ ] Screenshots da aplicação v1.0 e v2.0 salvos
- [ ] Comandos importantes anotados
- [ ] Saber forçar rollout: `kubectl rollout restart deployment/ecommerce-ui -n ecommerce-staging`

### Documentação Pronta
- [ ] ROTEIRO-APRESENTACAO-COMPLETO.md aberto
- [ ] Terminal configurado (fonte, tamanho)
- [ ] Navegador com tab da aplicação pronto
- [ ] Segundo terminal para comandos kubectl (opcional)

## 🎬 Checklist Durante Apresentação

### Início
- [ ] Mostrar v1.0 funcionando
- [ ] Simular uso/compras
- [ ] Explicar arquitetura GitOps

### Deploy v2.0
- [ ] Mostrar código atual (Home.js)
- [ ] Mostrar git log
- [ ] Fazer git checkout a6f0d3d
- [ ] Aguardar ArgoCD ou forçar restart
- [ ] Validar rollout completo

### Validação v2.0
- [ ] Mostrar aplicação com "Versão 2.0 🚀"
- [ ] Simular novas compras
- [ ] Mostrar APIs funcionando
- [ ] Destacar zero downtime

### Conclusão
- [ ] Resumir benefícios GitOps
- [ ] Mostrar rastreabilidade (git log/diff)
- [ ] Demonstrar rollback (se houver tempo)
- [ ] Q&A

## 🚨 Problemas Comuns e Soluções

### Problema: Rebuild falha

**Solução:**
1. Verificar quotas AWS
2. Limpar recursos manualmente via console AWS
3. Re-executar destroy-all.sh
4. Tentar rebuild novamente

### Problema: ArgoCD não sync

**Solução:**
```bash
# Forçar restart
kubectl rollout restart deployment/ecommerce-ui -n ecommerce-staging
```

### Problema: Aplicação não responde

**Solução:**
```bash
# Ver logs
kubectl logs -n ecommerce-staging -l app=ecommerce-ui --tail=50

# Verificar pods
kubectl get pods -n ecommerce-staging -l app=ecommerce-ui

# Verificar eventos
kubectl get events -n ecommerce-staging --sort-by='.lastTimestamp'
```

### Problema: Imagem não atualiza

**Solução:**
1. Verificar commit Git atual
2. Verificar manifest: `cat k8s-manifests/base/ecommerce-ui.yaml`
3. Forçar pull: `kubectl rollout restart deployment/ecommerce-ui -n ecommerce-staging`
4. Verificar ArgoCD: `kubectl describe application ecommerce-staging -n argocd`

## ⏰ Timeline Recomendado

| Tempo | Atividade |
|-------|-----------|
| D-1 | Testar rebuild completo em ambiente de teste |
| H-3 | Executar destroy-all.sh |
| H-2.5 | Executar rebuild-all-with-gitops.sh |
| H-2 | Validação completa (todos os checklists acima) |
| H-1 | Testes finais, anotações, backup plans |
| H-0.5 | Review rápido, última verificação v1.0 |
| H-0 | 🎬 Iniciar apresentação |

## 📞 Contatos de Emergência

- [ ] AWS Support: ___________________________________
- [ ] Time técnico: ___________________________________
- [ ] Backup presenter: ___________________________________

---

**Status:** [ ] Pronto para apresentação  
**Data:** _________________  
**Hora:** _________________  
**Validado por:** _________________

**Boa sorte! 🚀**

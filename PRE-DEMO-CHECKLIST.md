# ✅ CHECKLIST PRÉ-DEMONSTRAÇÃO

## 📋 Antes de Iniciar a Demo

### 1. Ambiente AWS
- [ ] Credenciais AWS configuradas (`aws sts get-caller-identity`)
- [ ] Região correta: `us-east-1`
- [ ] Permissões: EKS, ECR, VPC, IAM

### 2. Ferramentas Locais
- [ ] Docker Desktop rodando (`docker ps`)
- [ ] kubectl instalado (`kubectl version`)
- [ ] AWS CLI instalado (`aws --version`)
- [ ] Terraform instalado (`terraform --version`)

### 3. Código Preparado
- [ ] Código está na **versão 1.0**
  ```bash
  grep "Welcome to the E-commerce App<" microservices/ecommerce-ui/src/pages/Home.js
  ```
  Deve retornar: `<h1>Welcome to the E-commerce App</h1>` (sem "Versão 2.0")

- [ ] package.json em v1.0.0
  ```bash
  grep '"version": "1.0.0"' microservices/ecommerce-ui/package.json
  ```

### 4. Scripts
- [ ] Scripts têm permissão de execução
  ```bash
  ls -lh scripts/{demo-update-v2.sh,update-to-v2.sh,rollback-to-v1.sh}
  ```
  Todos devem mostrar `-rwxr-xr-x`

### 5. Documentação
- [ ] `DEMO-V2-GUIDE.md` revisado
- [ ] `QUICK-DEMO-V2.md` revisado
- [ ] URLs de acesso anotadas

---

## 🚀 Durante a Demo

### Fase 1: Deploy Inicial (SE NECESSÁRIO)
Se o cluster não está rodando:
```bash
./rebuild-all-with-gitops.sh
```
⏱️ Tempo: ~40 minutos

### Fase 2: Validar v1.0
- [ ] Aplicação acessível
- [ ] Login/cadastro funcionando
- [ ] Mensagem mostra: `"Welcome to the E-commerce App"` (sem versão)

### Fase 3: Demo GitOps Update
```bash
./scripts/demo-update-v2.sh
```
- [ ] Script executa sem erros
- [ ] Build concluído
- [ ] Push para ECR ok
- [ ] ArgoCD sincronizou
- [ ] Pods reiniciados

### Fase 4: Validar v2.0
- [ ] Recarregar aplicação
- [ ] Login novamente
- [ ] Mensagem mostra: `"Welcome to the E-commerce App - Versão 2.0 🚀"`

---

## 🎤 Pontos-Chave para Mencionar

1. **GitOps Workflow**
   > "O código é a fonte da verdade. Mudamos o código, e o ArgoCD garante que o cluster reflita isso."

2. **Automação**
   > "Build, push, deploy - tudo automatizado. Zero intervenção manual no cluster."

3. **Rastreabilidade**
   > "Cada versão é taggeada. Podemos auditar quando e quem fez cada mudança."

4. **Rollback**
   > "Se algo der errado, voltar é simples. ArgoCD mantém histórico completo."

---

## 🐛 Plano B (Troubleshooting)

### Se o build falhar:
```bash
# Limpar cache Docker
docker system prune -a -f

# Tentar novamente
./scripts/demo-update-v2.sh
```

### Se ArgoCD não sincronizar:
```bash
# Forçar sync manual
kubectl patch application ecommerce-staging -n argocd --type merge -p '{"operation":{"sync":{}}}'
```

### Se precisar resetar para v1.0:
```bash
./scripts/rollback-to-v1.sh
kubectl set image deployment/ecommerce-ui ecommerce-ui=<ECR>/ecommerce-ui:v1.0.0 -n ecommerce-staging
```

---

## 📊 Métricas de Sucesso

- [ ] Deploy v1.0 → v2.0 em < 5 minutos
- [ ] Zero downtime durante update
- [ ] Todos os pods healthy
- [ ] Aplicação respondendo com nova versão

---

## 🎯 Comandos de Validação Rápida

```bash
# Ver versão atual no cluster
kubectl get deployment ecommerce-ui -n ecommerce-staging -o jsonpath='{.spec.template.spec.containers[0].image}'

# Ver pods rodando
kubectl get pods -n ecommerce-staging -l app=ecommerce-ui

# Ver status ArgoCD
kubectl get application ecommerce-staging -n argocd

# Ver imagens no ECR
aws ecr describe-images --repository-name ecommerce/ecommerce-ui --region us-east-1 | grep imageTag
```

---

## 📝 Notas Finais

### Tempo Total da Demo
- Explicação inicial: 2-3 min
- Executar script: 3-5 min
- Validação e Q&A: 2-3 min
- **Total: ~10 minutos**

### Backup de URLs
Anotar aqui antes da demo:
```
Aplicação:   http://_______________
ArgoCD:      https://_______________
Prometheus:  http://localhost:9090
Grafana:     http://localhost:3000
Kiali:       http://localhost:20001
```

---

## ✅ Checklist Final

Antes de começar a apresentação:
- [ ] Cluster EKS rodando e acessível
- [ ] Aplicação v1.0 funcionando
- [ ] Docker rodando localmente
- [ ] Terminal pronto com script
- [ ] Navegador com app aberto
- [ ] ArgoCD dashboard em outra aba (opcional)
- [ ] Este checklist impresso/aberto

---

**🎬 VOCÊ ESTÁ PRONTO! BOA SORTE! 🚀**

---

*Use este checklist para garantir que nada seja esquecido durante a demonstração.*

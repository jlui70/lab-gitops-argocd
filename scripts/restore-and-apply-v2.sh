#!/bin/bash

# ============================================================================
# Script: restore-and-apply-v2.sh
# Descrição: Restaura backup validado e aplica mudanças da versão 2.0
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_FILE="/home/luiz7/Projects/backup_github/istio-eks-terraform-gitops-backup-20251230-125612.tar.gz"
RESTORE_BASE="/home/luiz7/Projects/backup_github"
PROJECT_NAME="istio-eks-terraform-gitops-argocd"
RESTORE_DIR="$RESTORE_BASE/${PROJECT_NAME}"
TEMP_EXTRACT="/tmp/istio-restore-$$"

echo -e "${BLUE}"
cat << "EOF"
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║   🔄 RESTAURAR BACKUP + APLICAR V2.0                              ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Verificar se backup existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}❌ Backup não encontrado: $BACKUP_FILE${NC}"
    exit 1
fi

echo -e "${CYAN}📦 Backup: ${NC}$(basename $BACKUP_FILE)"
echo -e "${CYAN}📁 Destino: ${NC}$RESTORE_DIR"
echo ""

# Confirmação
echo -e "${YELLOW}⚠️  ATENÇÃO: Isso vai:${NC}"
echo "   1. Criar backup do projeto atual"
echo "   2. Restaurar o projeto validado"
echo "   3. Aplicar mudanças da versão 2.0"
echo ""
read -p "Deseja continuar? (s/N): " confirm

if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo "Operação cancelada."
    exit 0
fi

# ============================================================================
# Step 1: Backup do projeto atual
# ============================================================================

echo ""
echo -e "${BLUE}[1/4] 💾 Fazendo backup do projeto atual...${NC}"
echo ""

if [ -d "$RESTORE_DIR" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_CURRENT="$RESTORE_BASE/${PROJECT_NAME}_before_restore_${TIMESTAMP}"
    
    echo "Movendo projeto atual para: $BACKUP_CURRENT"
    mv "$RESTORE_DIR" "$BACKUP_CURRENT"
    echo -e "${GREEN}✅ Backup do projeto atual criado${NC}"
else
    echo "Projeto atual não existe, pulando backup."
fi

# ============================================================================
# Step 2: Extrair backup validado
# ============================================================================

echo ""
echo -e "${BLUE}[2/4] 📦 Extraindo backup validado...${NC}"
echo ""

mkdir -p "$TEMP_EXTRACT"
cd "$TEMP_EXTRACT"

tar -xzf "$BACKUP_FILE"

# Encontrar diretório extraído
EXTRACTED_DIR=$(find . -maxdepth 1 -type d ! -name '.' | head -1)

if [ -z "$EXTRACTED_DIR" ]; then
    echo -e "${RED}❌ Erro ao extrair backup${NC}"
    exit 1
fi

# Mover para destino final
mv "$EXTRACTED_DIR" "$RESTORE_DIR"
cd "$RESTORE_DIR"

echo -e "${GREEN}✅ Projeto validado restaurado${NC}"

# ============================================================================
# Step 3: Salvar arquivos v2.0 do projeto atual
# ============================================================================

echo ""
echo -e "${BLUE}[3/4] 📝 Salvando mudanças da versão 2.0...${NC}"
echo ""

# Se existe backup do projeto atual, copiar mudanças de lá
if [ -d "$BACKUP_CURRENT" ]; then
    echo "Copiando arquivos modificados para v2.0..."
    
    # Copiar scripts da v2.0
    [ -f "$BACKUP_CURRENT/scripts/demo-update-v2.sh" ] && cp "$BACKUP_CURRENT/scripts/demo-update-v2.sh" scripts/
    [ -f "$BACKUP_CURRENT/scripts/update-to-v2.sh" ] && cp "$BACKUP_CURRENT/scripts/update-to-v2.sh" scripts/
    [ -f "$BACKUP_CURRENT/scripts/rollback-to-v1.sh" ] && cp "$BACKUP_CURRENT/scripts/rollback-to-v1.sh" scripts/
    [ -f "$BACKUP_CURRENT/scripts/backup-project.sh" ] && cp "$BACKUP_CURRENT/scripts/backup-project.sh" scripts/
    
    # Copiar documentação v2.0
    [ -f "$BACKUP_CURRENT/DEMO-V2-GUIDE.md" ] && cp "$BACKUP_CURRENT/DEMO-V2-GUIDE.md" ./
    [ -f "$BACKUP_CURRENT/QUICK-DEMO-V2.md" ] && cp "$BACKUP_CURRENT/QUICK-DEMO-V2.md" ./
    [ -f "$BACKUP_CURRENT/PRE-DEMO-CHECKLIST.md" ] && cp "$BACKUP_CURRENT/PRE-DEMO-CHECKLIST.md" ./
    [ -f "$BACKUP_CURRENT/SETUP-COMPLETE-V2.md" ] && cp "$BACKUP_CURRENT/SETUP-COMPLETE-V2.md" ./
    [ -f "$BACKUP_CURRENT/IMPLEMENTATION-COMPLETE-V2.md" ] && cp "$BACKUP_CURRENT/IMPLEMENTATION-COMPLETE-V2.md" ./
    [ -f "$BACKUP_CURRENT/scripts/README-DEMO-SCRIPTS.md" ] && cp "$BACKUP_CURRENT/scripts/README-DEMO-SCRIPTS.md" scripts/
    
    # Copiar mudanças no ecommerce-ui
    [ -f "$BACKUP_CURRENT/microservices/ecommerce-ui/Dockerfile" ] && cp "$BACKUP_CURRENT/microservices/ecommerce-ui/Dockerfile" microservices/ecommerce-ui/
    [ -f "$BACKUP_CURRENT/microservices/ecommerce-ui/package.json" ] && cp "$BACKUP_CURRENT/microservices/ecommerce-ui/package.json" microservices/ecommerce-ui/
    [ -d "$BACKUP_CURRENT/microservices/ecommerce-ui/public" ] && cp -r "$BACKUP_CURRENT/microservices/ecommerce-ui/public" microservices/ecommerce-ui/
    
    # Preservar backup do Home.js original se existir
    [ -f "$BACKUP_CURRENT/microservices/ecommerce-ui/src/pages/Home.js.v1-original" ] && \
        cp "$BACKUP_CURRENT/microservices/ecommerce-ui/src/pages/Home.js.v1-original" microservices/ecommerce-ui/src/pages/
    
    # Tornar scripts executáveis
    chmod +x scripts/demo-update-v2.sh 2>/dev/null || true
    chmod +x scripts/update-to-v2.sh 2>/dev/null || true
    chmod +x scripts/rollback-to-v1.sh 2>/dev/null || true
    chmod +x scripts/backup-project.sh 2>/dev/null || true
    
    echo -e "${GREEN}✅ Arquivos v2.0 aplicados${NC}"
else
    echo -e "${YELLOW}⚠️  Backup atual não encontrado, pulando cópia de arquivos v2.0${NC}"
fi

# ============================================================================
# Step 4: Limpeza
# ============================================================================

echo ""
echo -e "${BLUE}[4/4] 🧹 Limpeza...${NC}"
echo ""

rm -rf "$TEMP_EXTRACT"
echo -e "${GREEN}✅ Limpeza concluída${NC}"

# ============================================================================
# Resumo Final
# ============================================================================

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║   ✅ RESTAURAÇÃO CONCLUÍDA!                                        ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}📊 Status:${NC}"
echo "   ✅ Projeto validado restaurado"
echo "   ✅ Mudanças v2.0 aplicadas"
echo "   ✅ Scripts prontos"
echo ""

if [ -d "$BACKUP_CURRENT" ]; then
    echo -e "${YELLOW}💾 Backup anterior salvo em:${NC}"
    echo "   $BACKUP_CURRENT"
    echo ""
fi

echo -e "${GREEN}🚀 Próximos passos:${NC}"
echo ""
echo "   1. Testar rebuild:"
echo "      cd $RESTORE_DIR"
echo "      ./rebuild-all-with-gitops.sh"
echo ""
echo "   2. Após deploy, testar versão 2.0:"
echo "      ./scripts/demo-update-v2.sh"
echo ""

echo -e "${CYAN}💡 Dica: O projeto agora está com:${NC}"
echo "   - Base validada e funcionando"
echo "   - Scripts v2.0 prontos"
echo "   - Documentação completa"
echo ""

#!/bin/bash

# ============================================================================
# Script: backup-project.sh
# Descrição: Cria backup completo do projeto
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_NAME=$(basename "$PROJECT_ROOT")
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$HOME/backups"
BACKUP_NAME="${PROJECT_NAME}_backup_${TIMESTAMP}"
BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"

echo -e "${BLUE}"
cat << "EOF"
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║   💾 BACKUP DO PROJETO                                            ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}📂 Projeto: ${NC}$PROJECT_NAME"
echo -e "${CYAN}📁 Origem: ${NC}$PROJECT_ROOT"
echo -e "${CYAN}💾 Destino: ${NC}$BACKUP_FILE"
echo ""

# Criar diretório de backup se não existir
mkdir -p "$BACKUP_DIR"

echo -e "${YELLOW}🔍 Verificando arquivos...${NC}"
echo ""

# Contar arquivos
TOTAL_FILES=$(find "$PROJECT_ROOT" -type f | wc -l)
echo "  📄 Total de arquivos: $TOTAL_FILES"

# Calcular tamanho
TOTAL_SIZE=$(du -sh "$PROJECT_ROOT" | cut -f1)
echo "  📊 Tamanho total: $TOTAL_SIZE"
echo ""

# Confirmar
read -p "Deseja continuar com o backup? (s/N): " confirm

if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
    echo "Backup cancelado."
    exit 0
fi

echo ""
echo -e "${BLUE}🗜️  Compactando projeto...${NC}"
echo ""

cd "$(dirname "$PROJECT_ROOT")"

# Criar backup excluindo node_modules, .git objects, etc
tar -czf "$BACKUP_FILE" \
    --exclude='node_modules' \
    --exclude='.git/objects' \
    --exclude='*.log' \
    --exclude='.terraform' \
    --exclude='terraform.tfstate*' \
    --exclude='.DS_Store' \
    --exclude='*.swp' \
    --exclude='*.tmp' \
    "$(basename "$PROJECT_ROOT")" 2>&1 | while read line; do
    echo "  $line"
done

echo ""
echo -e "${GREEN}✅ Backup criado com sucesso!${NC}"
echo ""

# Informações do backup
BACKUP_SIZE=$(du -sh "$BACKUP_FILE" | cut -f1)
echo -e "${CYAN}📦 Arquivo de backup:${NC}"
echo "  Localização: $BACKUP_FILE"
echo "  Tamanho: $BACKUP_SIZE"
echo ""

# Listar backups anteriores
echo -e "${CYAN}📚 Backups existentes:${NC}"
ls -lh "$BACKUP_DIR" | grep "${PROJECT_NAME}_backup" | awk '{print "  " $9 " - " $5}' || echo "  Nenhum backup anterior"
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}║   ✅ BACKUP CONCLUÍDO!                                             ║${NC}"
echo -e "${GREEN}║                                                                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}💡 Para restaurar o backup:${NC}"
echo "   cd ~/backups"
echo "   tar -xzf $BACKUP_NAME.tar.gz -C /destino/desejado"
echo ""

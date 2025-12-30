#!/bin/bash

# ============================================================================
# Script: update-to-v2.sh
# Descrição: Atualiza o código fonte para versão 2.0
# Uso: ./scripts/update-to-v2.sh
# ============================================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔄 Atualizando código para Versão 2.0..."
echo ""

# Atualizar Home.js
echo "📝 Atualizando Home.js..."
sed -i 's/<h1>Welcome to the E-commerce App<\/h1>/<h1>Welcome to the E-commerce App - Versão 2.0 🚀<\/h1>/g' microservices/ecommerce-ui/src/pages/Home.js

# Atualizar package.json
echo "📦 Atualizando package.json para versão 2.0.0..."
sed -i 's/"version": "1.0.0"/"version": "2.0.0"/g' microservices/ecommerce-ui/package.json

echo ""
echo "✅ Código atualizado para Versão 2.0!"
echo ""
echo "Alterações:"
echo "  - Home.js: Mensagem atualizada com 'Versão 2.0 🚀'"
echo "  - package.json: version = 2.0.0"
echo ""

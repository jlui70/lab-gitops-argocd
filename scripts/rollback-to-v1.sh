#!/bin/bash

# ============================================================================
# Script: rollback-to-v1.sh
# Descrição: Reverte o código fonte para versão 1.0
# Uso: ./scripts/rollback-to-v1.sh
# ============================================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔄 Revertendo código para Versão 1.0..."
echo ""

# Reverter Home.js
echo "📝 Revertendo Home.js..."
sed -i 's/<h1>Welcome to the E-commerce App - Versão 2.0 🚀<\/h1>/<h1>Welcome to the E-commerce App<\/h1>/g' microservices/ecommerce-ui/src/pages/Home.js

# Reverter package.json
echo "📦 Revertendo package.json para versão 1.0.0..."
sed -i 's/"version": "2.0.0"/"version": "1.0.0"/g' microservices/ecommerce-ui/package.json

echo ""
echo "✅ Código revertido para Versão 1.0!"
echo ""
echo "Alterações:"
echo "  - Home.js: Mensagem original sem versão"
echo "  - package.json: version = 1.0.0"
echo ""

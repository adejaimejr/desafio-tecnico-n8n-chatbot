#!/bin/bash
set -e

# Script para iniciar o frontend React localmente
# Executa npm install (se necessário) e inicia o servidor de desenvolvimento

FRONTEND_DIR="$(dirname "$0")/frontend"

echo "🚀 Iniciando Frontend ChatBot..."
echo ""

# Verificar se a pasta frontend existe
if [ ! -d "$FRONTEND_DIR" ]; then
    echo "❌ Pasta frontend não encontrada!"
    exit 1
fi

cd "$FRONTEND_DIR"

# Verificar se node_modules existe, senão instalar
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependências..."
    npm install
    echo ""
fi

# Criar .env se não existir
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    echo "📝 Criando .env a partir do .env.example..."
    cp .env.example .env
    echo ""
fi

echo "✅ Frontend pronto!"
echo ""
echo "🌐 Iniciando servidor de desenvolvimento..."
echo "   URL: http://localhost:5173"
echo ""
echo "   Pressione Ctrl+C para parar"
echo ""

# Iniciar servidor de desenvolvimento
npm run dev

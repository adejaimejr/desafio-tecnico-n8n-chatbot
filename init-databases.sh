#!/bin/sh
set -e

# Script para criar databases separados:
#   - n8n: para uso interno do N8N (lê variável DB_POSTGRESDB_DATABASE)
#   - chatbot: para as tabelas do chatbot (lê variável CHATBOT_DATABASE)
#
# As variáveis são passadas automaticamente pelo docker-compose.yml
# a partir do arquivo .env

# Definir valores padrão caso variáveis não estejam definidas
N8N_DB="${DB_POSTGRESDB_DATABASE:-n8n}"
CHATBOT_DB="${CHATBOT_DATABASE:-chatbot}"

echo "🔧 Criando databases..."
echo "   - N8N database: $N8N_DB"
echo "   - Chatbot database: $CHATBOT_DB"

# Criar database n8n (ignora erro se já existe)
psql --username "$POSTGRES_USER" -c "CREATE DATABASE $N8N_DB;" 2>/dev/null || echo "Database '$N8N_DB' já existe, continuando..."

# Criar database chatbot (ignora erro se já existe)
psql --username "$POSTGRES_USER" -c "CREATE DATABASE $CHATBOT_DB;" 2>/dev/null || echo "Database '$CHATBOT_DB' já existe, continuando..."

# Garantir permissões
psql --username "$POSTGRES_USER" -c "GRANT ALL PRIVILEGES ON DATABASE $N8N_DB TO $POSTGRES_USER;"
psql --username "$POSTGRES_USER" -c "GRANT ALL PRIVILEGES ON DATABASE $CHATBOT_DB TO $POSTGRES_USER;"

echo "✅ Databases '$N8N_DB' e '$CHATBOT_DB' prontos!"

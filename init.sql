-- Schema do Banco de Dados para Chatbot N8N
-- PostgreSQL
-- Este script cria dois databases separados:
--   - n8n: para uso interno do N8N (workflows, executions, credentials)
--   - chatbot: para as tabelas do chatbot (users, interactions, agendamentos, reminders)

-- ====================================
-- DATABASE: n8n (uso interno do N8N)
-- ====================================
-- O N8N criará automaticamente suas tabelas neste database

-- ====================================
-- DATABASE: chatbot (nossas tabelas)
-- ====================================

-- Conectar ao database chatbot
\c chatbot

-- Criar extensão para UUIDs
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Tabela de Usuários
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    bloqueado BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabela de Interações (Mensagens)
CREATE TABLE IF NOT EXISTS interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    response TEXT,
    llm_message_id VARCHAR(255),
    reminder_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    responded_at TIMESTAMP
);

-- Tabela de Agendamentos
CREATE TABLE IF NOT EXISTS agendamentos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    data_agendada TIMESTAMP NOT NULL,
    status VARCHAR(50) DEFAULT 'pendente',
    mensagem TEXT,
    notificado BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT valid_status CHECK (status IN ('pendente', 'cancelado', 'realizado'))
);

-- Tabela de Lembretes (para tracking)
CREATE TABLE IF NOT EXISTS reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    interaction_id UUID REFERENCES interactions(id) ON DELETE CASCADE,
    sent_at TIMESTAMP DEFAULT NOW(),
    reminder_number INTEGER NOT NULL,
    was_responded BOOLEAN DEFAULT false,
    delivered_to_frontend BOOLEAN DEFAULT false
);

-- Índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_user_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_user_bloqueado ON users(bloqueado);
CREATE INDEX IF NOT EXISTS idx_interactions_user ON interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_interactions_active ON interactions(is_active, responded_at);
CREATE INDEX IF NOT EXISTS idx_interactions_llm_message ON interactions(llm_message_id);
CREATE INDEX IF NOT EXISTS idx_agendamentos_status ON agendamentos(status, data_agendada);
CREATE INDEX IF NOT EXISTS idx_agendamentos_data ON agendamentos(data_agendada);
CREATE INDEX IF NOT EXISTS idx_reminders_interaction ON reminders(interaction_id);
CREATE INDEX IF NOT EXISTS idx_reminders_delivered ON reminders(delivered_to_frontend, was_responded);

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para users
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para agendamentos
CREATE TRIGGER update_agendamentos_updated_at BEFORE UPDATE ON agendamentos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Inserir usuário de teste (opcional)
INSERT INTO users (nome, email, bloqueado)
VALUES
    ('Usuário Teste', 'teste@example.com', false),
    ('João Silva', 'joao@example.com', false)
ON CONFLICT (email) DO NOTHING;

-- View útil: Estatísticas de usuários
CREATE OR REPLACE VIEW user_stats AS
SELECT
    u.id,
    u.nome,
    u.email,
    u.bloqueado,
    COUNT(DISTINCT i.id) as total_interacoes,
    COUNT(DISTINCT a.id) as total_agendamentos,
    MAX(i.created_at) as ultima_interacao
FROM users u
LEFT JOIN interactions i ON u.id = i.user_id
LEFT JOIN agendamentos a ON u.id = a.user_id
GROUP BY u.id, u.nome, u.email, u.bloqueado;

-- View útil: Agendamentos pendentes para hoje
CREATE OR REPLACE VIEW agendamentos_hoje AS
SELECT
    a.id,
    a.data_agendada,
    u.nome,
    u.email,
    a.status
FROM agendamentos a
JOIN users u ON a.user_id = u.id
WHERE DATE(a.data_agendada) = CURRENT_DATE
  AND a.status = 'pendente'
  AND u.bloqueado = false
ORDER BY a.data_agendada;

-- Função útil: Verificar se usuário precisa de lembrete
CREATE OR REPLACE FUNCTION needs_reminder(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    last_interaction RECORD;
    reminder_count INTEGER;
BEGIN
    -- Buscar última interação ativa sem resposta
    SELECT * INTO last_interaction
    FROM interactions
    WHERE user_id = p_user_id
      AND is_active = true
      AND responded_at IS NULL
    ORDER BY created_at DESC
    LIMIT 1;

    IF last_interaction IS NULL THEN
        RETURN false;
    END IF;

    -- Verificar se passaram 15 minutos
    IF (NOW() - last_interaction.created_at) < INTERVAL '15 minutes' THEN
        RETURN false;
    END IF;

    -- Verificar quantos lembretes já foram enviados
    IF last_interaction.reminder_count >= 2 THEN
        RETURN false;
    END IF;

    RETURN true;
END;
$$ LANGUAGE plpgsql;

-- Comentários na estrutura
COMMENT ON TABLE users IS 'Tabela de usuários do chatbot';
COMMENT ON TABLE interactions IS 'Histórico de mensagens e respostas';
COMMENT ON TABLE agendamentos IS 'Agendamentos de conversas futuras';
COMMENT ON TABLE reminders IS 'Log de lembretes enviados';
COMMENT ON COLUMN users.bloqueado IS 'Se true, usuário não recebe mensagens do bot';
COMMENT ON COLUMN interactions.is_active IS 'Se false, conversa foi finalizada (2 lembretes sem resposta)';
COMMENT ON COLUMN interactions.reminder_count IS 'Número de lembretes enviados (máx: 2)';
COMMENT ON COLUMN interactions.llm_message_id IS 'ID da mensagem retornado pelo OpenAI/LLM para tracking';

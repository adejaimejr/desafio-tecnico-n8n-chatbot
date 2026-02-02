-- ═══════════════════════════════════════════════════════════════════
-- QUERIES ÚTEIS - Chatbot N8N
-- Execute no PgAdmin (http://localhost:5050) ou via docker exec
-- ═══════════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════════
-- CONSULTAS RÁPIDAS
-- ═══════════════════════════════════════════════════════════════════

-- Listar usuários
SELECT id, nome, email, bloqueado, created_at FROM users ORDER BY created_at DESC;

-- Listar agendamentos com usuário
SELECT a.id, u.nome, u.email, a.data_agendada, a.status, a.notificado
FROM agendamentos a
JOIN users u ON a.user_id = u.id
ORDER BY a.data_agendada DESC;

-- Últimas interações
SELECT u.email, i.message, i.reminder_count, i.is_active, i.created_at
FROM interactions i
JOIN users u ON i.user_id = u.id
ORDER BY i.created_at DESC
LIMIT 10;

-- ═══════════════════════════════════════════════════════════════════
-- SISTEMA DE LEMBRETES (15min timeout)
-- ═══════════════════════════════════════════════════════════════════

-- Interações aguardando lembrete (passaram 15min sem resposta)
SELECT
    u.email,
    i.message,
    i.reminder_count,
    COALESCE(
        (SELECT MAX(sent_at) FROM reminders WHERE interaction_id = i.id),
        i.created_at
    ) as ultimo_evento,
    EXTRACT(EPOCH FROM (NOW() - COALESCE(
        (SELECT MAX(sent_at) FROM reminders WHERE interaction_id = i.id),
        i.created_at
    )))/60 as minutos_desde_ultimo
FROM interactions i
JOIN users u ON i.user_id = u.id
WHERE i.is_active = true
  AND i.responded_at IS NULL
  AND i.reminder_count < 2
  AND u.bloqueado = false
ORDER BY i.created_at;

-- Lembretes pendentes de entrega ao frontend (polling)
SELECT
    r.id as reminder_id,
    u.email,
    r.reminder_number,
    r.sent_at,
    i.message as mensagem_original
FROM reminders r
JOIN interactions i ON r.interaction_id = i.id
JOIN users u ON i.user_id = u.id
WHERE r.delivered_to_frontend = false
  AND r.was_responded = false
ORDER BY r.sent_at DESC;

-- Histórico de lembretes de um usuário
SELECT
    r.reminder_number,
    r.sent_at,
    r.delivered_to_frontend,
    r.was_responded,
    i.message
FROM reminders r
JOIN interactions i ON r.interaction_id = i.id
JOIN users u ON i.user_id = u.id
WHERE u.email = 'teste@example.com'
ORDER BY r.sent_at DESC;

-- ═══════════════════════════════════════════════════════════════════
-- AGENDAMENTOS
-- ═══════════════════════════════════════════════════════════════════

-- Agendamentos pendentes (próximos 7 dias)
SELECT u.nome, u.email, a.data_agendada, a.mensagem, a.notificado
FROM agendamentos a
JOIN users u ON a.user_id = u.id
WHERE a.status = 'pendente'
  AND a.data_agendada BETWEEN NOW() AND NOW() + INTERVAL '7 days'
  AND u.bloqueado = false
ORDER BY a.data_agendada;

-- Agendamentos para notificar (próximas 24h, não notificados)
SELECT a.id, u.nome, u.email, a.data_agendada, a.mensagem
FROM agendamentos a
JOIN users u ON a.user_id = u.id
WHERE a.status = 'pendente'
  AND a.notificado = false
  AND a.data_agendada BETWEEN NOW() AND NOW() + INTERVAL '24 hours'
  AND u.bloqueado = false
ORDER BY a.data_agendada;

-- Contagem por status
SELECT status, COUNT(*) as total FROM agendamentos GROUP BY status;

-- ═══════════════════════════════════════════════════════════════════
-- ESTATÍSTICAS
-- ═══════════════════════════════════════════════════════════════════

-- Usar view de estatísticas (criada no init.sql)
SELECT * FROM user_stats ORDER BY total_interacoes DESC;

-- Agendamentos de hoje (view)
SELECT * FROM agendamentos_hoje;

-- Resumo geral
SELECT
    (SELECT COUNT(*) FROM users) as total_usuarios,
    (SELECT COUNT(*) FROM users WHERE bloqueado = true) as usuarios_bloqueados,
    (SELECT COUNT(*) FROM interactions) as total_interacoes,
    (SELECT COUNT(*) FROM interactions WHERE is_active = true AND responded_at IS NULL) as conversas_ativas,
    (SELECT COUNT(*) FROM agendamentos WHERE status = 'pendente') as agendamentos_pendentes,
    (SELECT COUNT(*) FROM reminders WHERE delivered_to_frontend = false) as lembretes_pendentes;

-- Taxa de resposta após lembretes
SELECT
    COUNT(*) FILTER (WHERE reminder_count = 0) as sem_lembrete,
    COUNT(*) FILTER (WHERE reminder_count = 1) as apos_1_lembrete,
    COUNT(*) FILTER (WHERE reminder_count = 2) as apos_2_lembretes,
    COUNT(*) FILTER (WHERE responded_at IS NOT NULL) as total_respondidas,
    COUNT(*) as total
FROM interactions;

-- ═══════════════════════════════════════════════════════════════════
-- BUSCA POR USUÁRIO
-- ═══════════════════════════════════════════════════════════════════

-- Buscar por email
SELECT * FROM users WHERE email = 'teste@example.com';

-- Histórico completo de um usuário
SELECT
    'interacao' as tipo,
    i.created_at as data,
    i.message as conteudo,
    i.reminder_count,
    i.is_active
FROM interactions i
WHERE i.user_id = (SELECT id FROM users WHERE email = 'teste@example.com')
UNION ALL
SELECT
    'agendamento' as tipo,
    a.created_at as data,
    a.status || ' - ' || a.data_agendada::text as conteudo,
    NULL,
    NULL
FROM agendamentos a
WHERE a.user_id = (SELECT id FROM users WHERE email = 'teste@example.com')
ORDER BY data DESC;

-- ═══════════════════════════════════════════════════════════════════
-- OPERAÇÕES (para testes)
-- ═══════════════════════════════════════════════════════════════════

-- Bloquear usuário
-- UPDATE users SET bloqueado = true WHERE email = 'teste@example.com';

-- Desbloquear usuário
-- UPDATE users SET bloqueado = false WHERE email = 'teste@example.com';

-- Marcar lembrete como entregue
-- UPDATE reminders SET delivered_to_frontend = true WHERE id = 'uuid-aqui';

-- Marcar agendamento como notificado
-- UPDATE agendamentos SET notificado = true WHERE id = 'uuid-aqui';

-- Encerrar conversa manualmente (simula 2 lembretes sem resposta)
-- UPDATE interactions SET is_active = false WHERE id = 'uuid-aqui';

-- ═══════════════════════════════════════════════════════════════════
-- LIMPEZA (CUIDADO!)
-- ═══════════════════════════════════════════════════════════════════

-- Limpar dados de um usuário específico
-- DELETE FROM users WHERE email = 'teste@example.com';

-- Reset completo (APAGA TUDO!)
-- TRUNCATE TABLE reminders, interactions, agendamentos, users RESTART IDENTITY CASCADE;

-- ═══════════════════════════════════════════════════════════════════
-- DEBUG DO REMINDER-SYSTEM
-- ═══════════════════════════════════════════════════════════════════

-- Ver interações que o cron do reminder-system deveria processar
SELECT
    i.id,
    u.email,
    i.reminder_count,
    i.created_at,
    COALESCE(
        (SELECT MAX(sent_at) FROM reminders WHERE interaction_id = i.id),
        i.created_at
    ) as referencia_tempo,
    EXTRACT(EPOCH FROM (NOW() - COALESCE(
        (SELECT MAX(sent_at) FROM reminders WHERE interaction_id = i.id),
        i.created_at
    )))/60 as minutos_passados,
    CASE
        WHEN EXTRACT(EPOCH FROM (NOW() - COALESCE(
            (SELECT MAX(sent_at) FROM reminders WHERE interaction_id = i.id),
            i.created_at
        )))/60 >= 15 THEN 'PRONTO PARA LEMBRETE'
        ELSE 'AGUARDANDO'
    END as status_lembrete
FROM interactions i
JOIN users u ON i.user_id = u.id
WHERE i.is_active = true
  AND i.responded_at IS NULL
  AND i.reminder_count < 2
  AND u.bloqueado = false
ORDER BY minutos_passados DESC;

-- ═══════════════════════════════════════════════════════════════════
-- MANUTENÇÃO
-- ═══════════════════════════════════════════════════════════════════

-- Tamanho das tabelas
SELECT
    tablename,
    pg_size_pretty(pg_total_relation_size('public.' || tablename)) as tamanho
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size('public.' || tablename) DESC;

-- Verificar índices
SELECT indexname, tablename FROM pg_indexes WHERE schemaname = 'public';

-- ═══════════════════════════════════════════════════════════════════
-- BACKUP (executar no terminal)
-- ═══════════════════════════════════════════════════════════════════
-- docker exec chatbot-postgres pg_dump -U n8n chatbot > backup_$(date +%Y%m%d).sql
-- docker exec -i chatbot-postgres psql -U n8n chatbot < backup.sql

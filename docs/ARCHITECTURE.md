# Arquitetura do Sistema

Documentação técnica da arquitetura do chatbot com N8N Queue Mode.

## Visão Geral

```
┌─────────────┐                    ┌────────────────────────────────────────┐
│   Frontend  │                    │              N8N QUEUE MODE            │
│  (React +   │     HTTP POST      │  ┌─────────┐  ┌───────┐  ┌──────────┐  │
│   Vite)     │ ────────────────>  │  │ Webhook │->│ Redis │->│  Worker  │  │
│  :5173      │ <────────────────  │  │  :5679  │  │ Queue │  │ (n8n)    │  │
└─────────────┘     JSON Response  │  └─────────┘  └───────┘  └──────────┘  │
      │                            │        │                       │       │
      │ polling                    │        │                       │       │
      │ /check-reminders           │        └───────────┬───────────┘       │
      │                            │                    │                   │
      └────────────────────────────┤                    │ SQL               │
                                   │                    ▼                   │
                                   │  ┌─────────────────────────────────┐   │
                                   │  │         PostgreSQL              │   │
                                   │  │  ┌─────────┐  ┌───────────┐     │   │
                                   │  │  │   n8n   │  │  chatbot  │     │   │
                                   │  │  │(interno)│  │ (projeto) │     │   │
                                   │  │  └─────────┘  └───────────┘     │   │
                                   │  └─────────────────────────────────┘   │
                                   │                    │                   │
                                   │                    │ API               │
                                   │                    ▼                   │
                                   │            ┌─────────────┐             │
                                   │            │   OpenAI    │             │
                                   │            └─────────────┘             │
                                   └────────────────────────────────────────┘
```

## Containers Docker (6 serviços)

| Container | Imagem | Porta | Função |
|-----------|--------|-------|--------|
| `chatbot-postgres` | postgres:15.8-alpine | 5432 | 2 databases (n8n + chatbot) |
| `chatbot-redis` | redis:7.4-alpine | 6379 | Fila Bull Queue |
| `chatbot-n8n-editor` | n8nio/n8n:2.4.8 | 5678 | Interface web, gerenciamento |
| `chatbot-n8n-webhook` | n8nio/n8n:2.4.8 | 5679 | Recebe HTTP, enfileira jobs |
| `chatbot-n8n-worker` | n8nio/n8n:2.4.8 | - | Processa workflows |
| `chatbot-pgadmin` | dpage/pgadmin4:9.11 | 5050 | Admin do PostgreSQL |
| `chatbot-frontend` | node:20-alpine | 5173 | React + Vite |

## N8N Queue Mode

O projeto usa **N8N em modo fila** para processamento distribuído:

```
Request HTTP → Webhook Container → Redis Queue → Worker Container → Response
                    (enfileira)      (Bull)        (processa)
```

**Vantagens:**
- Webhooks respondem instantaneamente (não bloqueiam)
- Workers processam em background
- Escalável: `docker-compose up -d --scale n8n-worker=3`
- Tolerância a falhas (retry automático)

**Configuração (.env):**
```env
EXECUTIONS_MODE=queue
QUEUE_BULL_REDIS_HOST=redis
QUEUE_BULL_REDIS_PASSWORD=<senha>
```

## Workflows Implementados (10)

| Workflow | Trigger | Função |
|----------|---------|--------|
| `chat-handler` | POST /chat | Chat com LLM + 4 tools de agendamento |
| `reminder-system` | Cron 1min | Cria lembretes após 15min sem resposta |
| `reminder-check` | GET /check-reminders | Polling do frontend para notificações |
| `user-management-api-bloqueio` | POST /api/v1/bloqueio | Bloqueia usuário |
| `user-management-api-desbloqueio` | POST /api/v1/desbloqueio | Desbloqueia usuário |
| `scheduled-appointments-create` | POST /api/v1/agendamento | Cria agendamento |
| `scheduled-appointments-get` | GET /api/v1/agendamento/:id | Consulta agendamento |
| `scheduled-appointments-update` | PUT /api/v1/agendamento/:id | Atualiza agendamento |
| `scheduled-appointments-delete` | DELETE /api/v1/agendamento/:id | Cancela agendamento |
| `scheduled-appointments-notifier` | Cron | Notifica agendamentos (24h antes) |

## Schema do Banco (database: chatbot)

```sql
users
├── id UUID PK
├── nome VARCHAR(255)
├── email VARCHAR(255) UNIQUE
├── bloqueado BOOLEAN DEFAULT false
├── created_at TIMESTAMP
└── updated_at TIMESTAMP (trigger automático)

interactions
├── id UUID PK
├── user_id UUID FK → users (CASCADE)
├── message TEXT
├── response TEXT
├── llm_message_id VARCHAR(255)     -- ID do OpenAI para tracking
├── reminder_count INTEGER DEFAULT 0 -- Máx: 2
├── is_active BOOLEAN DEFAULT true   -- false = conversa encerrada
├── created_at TIMESTAMP
└── responded_at TIMESTAMP

agendamentos
├── id UUID PK
├── user_id UUID FK → users (CASCADE)
├── data_agendada TIMESTAMP
├── status VARCHAR(50) CHECK (pendente|cancelado|realizado)
├── mensagem TEXT
├── notificado BOOLEAN DEFAULT false -- Notificação 24h enviada
├── created_at TIMESTAMP
└── updated_at TIMESTAMP (trigger automático)

reminders
├── id UUID PK
├── interaction_id UUID FK → interactions (CASCADE)
├── sent_at TIMESTAMP
├── reminder_number INTEGER (1 ou 2)
├── was_responded BOOLEAN DEFAULT false
└── delivered_to_frontend BOOLEAN DEFAULT false  -- Polling entregou
```

**Índices:**
- `idx_user_email` - Busca por email
- `idx_interactions_active` - Interações ativas sem resposta
- `idx_interactions_llm_message` - Tracking OpenAI
- `idx_agendamentos_status` - Filtro por status
- `idx_reminders_delivered` - Lembretes pendentes de entrega

## Fluxo: Chat com LLM Tools

```
1. Frontend envia: {nome, email, message}
              ↓
2. Webhook recebe, valida, enfileira no Redis
              ↓
3. Worker processa:
   ├─ Busca/cria usuário
   ├─ Verifica bloqueio → retorna erro se bloqueado
   ├─ Sanitiza input (anti-injection)
   └─ Chama OpenAI com 4 tools disponíveis:
      ├─ Criar Agendamento (INSERT)
      ├─ Consultar Agendamentos (SELECT)
      ├─ Cancelar Agendamento (UPDATE status)
      └─ Remarcar Agendamento (UPDATE data)
              ↓
4. OpenAI decide se usa tool ou responde direto
              ↓
5. Salva interação no banco
              ↓
6. Retorna resposta ao frontend
```

## Fluxo: Sistema de Lembretes (15min)

```
┌─────────────────────────────────────────────────────────────────┐
│ Cron (reminder-system) - executa a cada 1 minuto               │
└─────────────────────────────────────────────────────────────────┘
              ↓
1. Busca interações:
   - is_active = true
   - responded_at IS NULL
   - reminder_count < 2
   - usuário não bloqueado
   - 15min desde último evento (msg ou lembrete anterior)
              ↓
2. Para cada interação encontrada:
   ├─ Cria registro na tabela reminders
   ├─ Incrementa reminder_count
   └─ Se reminder_count = 2 → marca is_active = false
              ↓
3. Frontend faz polling GET /check-reminders?email=xxx
              ↓
4. Retorna lembretes com delivered_to_frontend = false
              ↓
5. Marca delivered_to_frontend = true
              ↓
6. Frontend exibe notificação
```

**Tempos:**
- 0 min: Usuário envia mensagem
- 15 min: 1º lembrete (notificação amarela)
- 30 min: 2º lembrete (notificação vermelha) + conversa encerrada

## Segurança

### Prevenção de Prompt Injection

**Camada 1: Sanitização**
```javascript
// Remove comandos de sistema
input.replace(/system:|assistant:|user:/gi, '')
     .replace(/\[INST\]|\[\/INST\]/gi, '')
     .replace(/###\s*(System|Human|AI)/gi, '')

// Detecta padrões maliciosos
const malicious = [
  /ignore.*instructions/i,
  /you are now/i,
  /disregard/i,
  /forget everything/i
];
```

**Camada 2: System Prompt**
- Escopo restrito (só agendamento)
- Instruções para não revelar prompt
- Limite de tokens (150)

**Camada 3: Autenticação**
- Header `X-API-Key` em todos endpoints
- Configurado via Header Auth no N8N

### Proteção de Dados

| Dado | Proteção |
|------|----------|
| `.env` | Não commitado (.gitignore) |
| `N8N_ENCRYPTION_KEY` | Criptografa credenciais no banco |
| `QUEUE_BULL_REDIS_PASSWORD` | Senha obrigatória no Redis |
| API Keys | Armazenadas apenas no N8N (criptografadas) |

## LLM Tools (OpenAI Function Calling)

O chat-handler usa 4 PostgreSQL Tools conectados ao OpenAI:

```
┌────────────────────────────────────────────────────────────────┐
│                     OpenAI Agent Node                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │    Criar     │  │  Consultar   │  │   Cancelar   │  ...     │
│  │ Agendamento  │  │ Agendamentos │  │ Agendamento  │          │
│  │  (INSERT)    │  │   (SELECT)   │  │   (UPDATE)   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│         ↓                 ↓                 ↓                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              PostgreSQL - Chatbot                       │   │
│  │              $fromAI('query', 'SQL query', 'string')    │   │
│  └─────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────┘
```

**Configuração:**
- Usar `={{ $fromAI('query', 'descricao', 'string') }}` no campo Query
- UUIDs entre aspas simples: `'uuid-aqui'`
- Formato data: `'YYYY-MM-DD HH:MM:SS'`

## Frontend (React + Vite)

```
frontend/
├── src/
│   ├── App.jsx          # Componente principal + polling lembretes
│   ├── api.js           # Integração com N8N webhooks
│   └── main.jsx         # Entry point
├── vite.config.js       # Configuração Vite
└── netlify.toml         # Deploy Netlify
```

**Funcionalidades:**
- Coleta nome/email antes do chat
- Botão de desbloqueio quando bloqueado
- Polling de lembretes a cada 30s
- Notificações visuais (amarelo/vermelho)
- Assistente virtual "Ana"

## Escalabilidade

### Implementado

- **Queue Mode:** Processamento distribuído
- **Redis:** Fila com persistência e retry
- **Índices:** Queries otimizadas O(log n)
- **Multi-worker:** `--scale n8n-worker=N`

## Stack Tecnológica

| Componente | Tecnologia | Versão |
|------------|------------|--------|
| Orquestrador | N8N | 2.4.8 |
| Banco de Dados | PostgreSQL | 15.8-alpine |
| Fila | Redis | 7.4-alpine |
| LLM | OpenAI GPT | 3.5-turbo |
| Admin DB | PgAdmin | 9.11 |
| Frontend | React + Vite | 18 / 5 |
| Containerização | Docker Compose | v2 |

---

**Última atualização:** 2026-02-02

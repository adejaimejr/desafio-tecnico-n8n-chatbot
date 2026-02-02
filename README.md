# Chatbot de Agendamento com N8N 🤖

Sistema completo de chatbot com agendamento, bloqueio de contatos e lembretes automáticos, construído com N8N.

## 🎯 Funcionalidades

- ✅ Chat interativo com LLM (OpenAI)
- ✅ Sistema de agendamento de conversas
- ✅ Bloqueio e desbloqueio de usuários
- ✅ Lembretes automáticos após 15 minutos (máx. 2 lembretes)
- ✅ API REST completa (6 endpoints)
- ✅ Prevenção de Prompt Injection
- ✅ **N8N Queue Mode** - Processamento distribuído com Redis
- ✅ **Escalável horizontalmente** - Múltiplos workers
- ✅ Setup automatizado com Docker Compose

## 🚀 Quick Start (5 minutos)

### 📋 Credenciais do Projeto

Anote estas credenciais, você vai precisar delas:

| Serviço | URL | Usuário/Email | Senha | Database |
|---------|-----|---------------|-------|----------|
| **N8N** | http://localhost:5678 | *Você cria na 1ª vez* | *Você define* | - |
| **PgAdmin** | http://localhost:5050 | admin@chatbot.com | Admin@123 | - |
| **PostgreSQL (N8N)** | localhost:5432 | n8n | n8n_password | `n8n` |
| **PostgreSQL (Chatbot)** | localhost:5432 | n8n | n8n_password | `chatbot` |

**📌 Estrutura dos Databases:**
- **`n8n`** - Usado internamente pelo N8N (workflows, executions, credentials)
- **`chatbot`** - Nossas 4 tabelas: users, interactions, agendamentos, reminders

### Pré-requisitos

**Compatível com qualquer plataforma:**
- ✅ macOS (Intel e Apple Silicon M1/M2/M3)
- ✅ Linux (Ubuntu, Debian, Fedora, Arch, etc.)
- ✅ Windows 10/11 (via WSL2)

**Requerimentos:**
- ✅ Docker e Docker Compose instalados e rodando
- ✅ Chave de API da OpenAI ([obter aqui](https://platform.openai.com/api-keys))

**⚠️ Windows:** Configure Git antes de clonar:
```powershell
git config --global core.autocrlf input
```
---

### 1️⃣ Clone e Prepare

```bash
git clone https://github.com/adejaimejr/desafio-tecnico-n8n-chatbot.git
cd desafio-tecnico-n8n-chatbot
```

**Obtenha sua OpenAI API Key:**
1. Acesse: https://platform.openai.com/api-keys
2. Crie uma nova chave
3. **Copie e guarde** - você vai usar no passo 4

---

### 2️⃣ Configure o Ambiente

```bash
# Copie o arquivo de exemplo e configure suas variáveis
cp .env.example .env

# Gere chaves de segurança (recomendado)
# Encryption key do N8N:
openssl rand -hex 16
# Senha do Redis:
openssl rand -base64 32
# API Key do frontend:
openssl rand -base64 24
```

Edite o `.env` e substitua:
- `N8N_ENCRYPTION_KEY` - cole a chave gerada (hex 16)
- `QUEUE_BULL_REDIS_PASSWORD` - cole a senha gerada (base64 32)
- `VITE_API_KEY` - cole a chave gerada (base64 24)

---

### 3️⃣ Suba o Ambiente

```bash
docker-compose up -d
```

**Aguarde ~30 segundos** para todos os serviços iniciarem.

Verifique se está tudo rodando:
```bash
docker-compose ps
```

Você deve ver **5 containers** com status "Up":
- ✅ **chatbot-postgres** (healthy) - Database PostgreSQL
- ✅ **chatbot-redis** (healthy) - Fila de jobs (Bull Queue)
- ✅ **chatbot-n8n-main** (up) - Interface web + webhooks
- ✅ **chatbot-n8n-worker** (up) - Worker para processar workflows
- ✅ **chatbot-pgadmin** (up) - Interface de administração

**🚀 N8N Queue Mode:**
O projeto usa N8N em modo fila para processamento distribuído:
- Webhooks respondem instantaneamente (não bloqueiam)
- Workflows executam em background via workers
- Escalável: `docker-compose up -d --scale n8n-worker=3`
- Detalhes completos: [docs/QUEUE_MODE.md](docs/QUEUE_MODE.md)

---

### 4️⃣ Acesse e Configure o N8N

**4.1. Acesse:** http://localhost:5678

**4.2. Primeira vez - Criar conta:**
- Preencha: Nome, Email, Senha
- Este será o usuário **owner** (administrador)
- **Anote suas credenciais!**

**4.3. Configure Credenciais:**

Após fazer login no N8N:

#### A) PostgreSQL
1. Menu lateral → **Credentials** → **New**
2. Busque e selecione **"PostgreSQL"**
3. Preencha exatamente:
   ```
   Host: postgres
   Database: chatbot
   User: n8n
   Password: n8n_password
   Port: 5432
   ```
   ⚠️ **Use database `chatbot`** - o database `n8n` é para uso interno do N8N
4. Clique **"Save"** e nomeie: **"PostgreSQL - Chatbot"**

#### B) OpenAI
1. **Credentials** → **New** → Busque **"OpenAI"**
2. Cole a **API Key** que você obteve no passo 1
3. Clique **"Save"** e nomeie: **"OpenAI API"**

✅ **Credenciais configuradas!**

---

### 5️⃣ Acesse o PgAdmin (Opcional)

**5.1. Acesse:** http://localhost:5050

**5.2. Faça login:**
- Email: `admin@chatbot.com`
- Senha: `Admin@123`

**5.3. Primeira vez - Configurar servidor:**

Se o servidor "Chatbot DB" **não aparecer automaticamente**:

1. Clique com botão direito em **"Servers"**
2. Selecione **"Register" → "Server"**
3. Aba **"General"**:
   - Name: `Chatbot DB`
4. Aba **"Connection"**:
   ```
   Host: postgres
   Port: 5432
   Maintenance database: chatbot
   Username: n8n
   Password: n8n_password
   ✅ Marque "Save password"
   ```
5. Clique **"Save"**

**✅ PgAdmin configurado!**

Navegue: Servers → Chatbot DB → Databases → chatbot → Schemas → public → Tables

---

### 6️⃣ Importe os Workflows

No N8N:
1. Menu lateral → Workflows → Import from File
2. Importe os arquivos da pasta `workflows/`:
3. Para cada workflow importado:
   - Abra o workflow
   - Clique em **"Active"** (botão no canto superior direito)
   - Verifique se não há erros

## 📚 Documentação da API

**Base URL:** `http://localhost:5679/webhook`

**Autenticação:** Header `X-API-Key` (configurar no N8N)

### Endpoints

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| POST | `/chat` | Enviar mensagem ao chatbot |
| POST | `/api/v1/agendamento` | Criar agendamento |
| GET | `/api/v1/agendamento/:id` | Consultar agendamento |
| PUT | `/api/v1/agendamento/:id` | Atualizar agendamento |
| DELETE | `/api/v1/agendamento/:id` | Cancelar agendamento |
| POST | `/api/v1/bloqueio` | Bloquear usuário |
| POST | `/api/v1/desbloqueio` | Desbloquear usuário |

### Exemplo Rápido

```bash
# Enviar mensagem
curl -X POST http://localhost:5679/webhook/chat \
  -H "X-API-Key: SUA_CHAVE" \
  -H "Content-Type: application/json" \
  -d '{"nome":"João","email":"joao@example.com","message":"Olá!"}'
```

**Documentação completa com todos os exemplos:** [docs/API_EXAMPLES.md](docs/API_EXAMPLES.md)

---

## 🗄️ Banco de Dados

**4 tabelas:** `users`, `interactions`, `agendamentos`, `reminders`

**Acesso visual:** http://localhost:5050 (PgAdmin)
- Login: `admin@chatbot.com` / `Admin@123`

**Queries úteis:** [scripts/queries-uteis.sql](scripts/queries-uteis.sql)

---

## 🔧 Comandos Úteis

```bash
# Status dos containers
docker-compose ps

# Logs em tempo real
docker-compose logs -f n8n-editor

# Parar/reiniciar
docker-compose down
docker-compose up -d

# Escalar workers
docker-compose up -d --scale n8n-worker=3

# Backup do banco
docker exec chatbot-postgres pg_dump -U n8n chatbot > backup.sql
```

---

## 📁 Estrutura do Projeto

```
├── docker-compose.yml      # 6 containers (PostgreSQL, Redis, N8N x3, PgAdmin)
├── .env.example            # Template de configuração
├── init.sql                # Schema do banco
├── n8n/workflows/          # 10 workflows JSON
├── frontend/               # React + Vite
├── docs/                   # Documentação detalhada
└── scripts/                # Queries SQL úteis
```

---

## 🚀 Deploy

### Local (Docker)
```bash
docker-compose up -d
```

### Produção
- **N8N:** [n8n.io/cloud](https://n8n.io/cloud) (gratuito)
- **Database:** [Supabase](https://supabase.com) (gratuito)
- **Frontend:** [Netlify](https://netlify.com) ou [Vercel](https://vercel.com)

---

## 🔍 Troubleshooting

| Problema | Solução |
|----------|---------|
| N8N não conecta no banco | `docker-compose logs postgres` |
| Workflow não ativa | Verificar credenciais no N8N |
| OpenAI erro 401 | Verificar API key |
| API retorna 404 | Verificar se workflow está ativo |

---

## 🏆 Diferenciais

- N8N Queue Mode com Redis (escalável)
- Prevenção de Prompt Injection
- API REST completa (7 endpoints)
- Sistema de lembretes (15min timeout)
- Docker one-command setup
- Multi-plataforma (macOS, Linux, Windows)

---

## 📖 Documentação Adicional

| Arquivo | Conteúdo |
|---------|----------|
| [docs/SETUP.md](docs/SETUP.md) | Guia completo de instalação |
| [docs/API_EXAMPLES.md](docs/API_EXAMPLES.md) | Exemplos de requests |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Arquitetura do sistema |

---

## 📄 Licença

MIT

## 👤 Autor

**Adejaime Junior** - [@adejaimejr](https://github.com/adejaimejr)

# Setup Completo - Chatbot N8N

Guia completo para instalar e configurar o projeto.

---

## Pré-requisitos

### 1. Docker Desktop

| Sistema | Instalação |
|---------|------------|
| **Windows** | https://www.docker.com/products/docker-desktop/ (marque "Use WSL 2") |
| **macOS** | https://www.docker.com/products/docker-desktop/ (Intel ou Apple Silicon) |
| **Linux** | `curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh` |

**Windows - Habilitar WSL2:**
```powershell
wsl --install
# Reinicie o computador após!
```

**Linux - Adicionar usuário ao grupo docker:**
```bash
sudo usermod -aG docker $USER
# Faça logout e login novamente
```

### 2. Git

| Sistema | Instalação |
|---------|------------|
| **Windows** | https://git-scm.com/download/win |
| **macOS** | Já vem instalado |
| **Linux** | `sudo apt install git -y` |

### 3. OpenAI API Key

1. Acesse: https://platform.openai.com/api-keys
2. Crie uma nova chave (começa com `sk-...`)
3. **Copie e guarde** - vai usar no passo de configuração

---

## Instalação por Sistema Operacional

Escolha seu sistema e siga os passos:

---

### Windows (PowerShell)

```powershell
# 1. Configurar Git (importante!)
git config --global core.autocrlf input

# 2. Clonar repositório
git clone https://github.com/adejaimejr/desafio-tecnico-n8n-chatbot.git
cd desafio-tecnico-n8n-chatbot

# 3. Copiar arquivo de ambiente
Copy-Item .env.example .env

# 4. Gerar chaves de segurança
$n8nKey = -join ((48..57) + (97..102) | Get-Random -Count 32 | ForEach-Object {[char]$_})
$redisPass = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | ForEach-Object {[char]$_})
$apiKey = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 24 | ForEach-Object {[char]$_})

Write-Host "=== COPIE ESTAS CHAVES ==="
Write-Host "N8N_ENCRYPTION_KEY=$n8nKey"
Write-Host "QUEUE_BULL_REDIS_PASSWORD=$redisPass"
Write-Host "VITE_API_KEY=$apiKey"

# 5. Editar .env (cole as chaves geradas)
notepad .env

# 6. Subir containers
docker compose up -d

# 7. Verificar status
docker compose ps

# 8. Abrir N8N no navegador
start http://localhost:5678
```

---

### macOS (Terminal)

```bash
# 1. Clonar repositório
git clone https://github.com/adejaimejr/desafio-tecnico-n8n-chatbot.git
cd desafio-tecnico-n8n-chatbot

# 2. Copiar arquivo de ambiente
cp .env.example .env

# 3. Gerar e aplicar chaves automaticamente
N8N_KEY=$(openssl rand -hex 16)
REDIS_PASS=$(openssl rand -base64 32)
API_KEY=$(openssl rand -base64 24)

sed -i '' "s|N8N_ENCRYPTION_KEY=.*|N8N_ENCRYPTION_KEY=$N8N_KEY|" .env
sed -i '' "s|QUEUE_BULL_REDIS_PASSWORD=.*|QUEUE_BULL_REDIS_PASSWORD=$REDIS_PASS|" .env
sed -i '' "s|VITE_API_KEY=.*|VITE_API_KEY=$API_KEY|" .env

echo "Chaves geradas e aplicadas no .env"

# 4. Dar permissão ao script de inicialização
chmod +x init-databases.sh

# 5. Subir containers
docker compose up -d

# 6. Verificar status
docker compose ps

# 7. Abrir N8N no navegador
open http://localhost:5678
```

---

### Linux (Ubuntu/Debian)

```bash
# 1. Clonar repositório
git clone https://github.com/adejaimejr/desafio-tecnico-n8n-chatbot.git
cd desafio-tecnico-n8n-chatbot

# 2. Copiar arquivo de ambiente
cp .env.example .env

# 3. Gerar e aplicar chaves automaticamente
N8N_KEY=$(openssl rand -hex 16)
REDIS_PASS=$(openssl rand -base64 32)
API_KEY=$(openssl rand -base64 24)

sed -i "s|N8N_ENCRYPTION_KEY=.*|N8N_ENCRYPTION_KEY=$N8N_KEY|" .env
sed -i "s|QUEUE_BULL_REDIS_PASSWORD=.*|QUEUE_BULL_REDIS_PASSWORD=$REDIS_PASS|" .env
sed -i "s|VITE_API_KEY=.*|VITE_API_KEY=$API_KEY|" .env

echo "Chaves geradas e aplicadas no .env"

# 4. Dar permissão ao script de inicialização
chmod +x init-databases.sh

# 5. Subir containers
docker compose up -d

# 6. Verificar status
docker compose ps

# 7. Abrir N8N no navegador
xdg-open http://localhost:5678
```

---

## Verificar Containers

Após `docker compose up -d`, você deve ver **7 containers**:

```bash
docker compose ps
```

| Container | Status Esperado | Porta |
|-----------|-----------------|-------|
| chatbot-postgres | healthy | 5432 |
| chatbot-redis | healthy | 6379 |
| chatbot-n8n-editor | up | 5678 |
| chatbot-n8n-webhook | up | 5679 |
| chatbot-n8n-worker | up | - |
| chatbot-pgadmin | up | 5050 |
| chatbot-frontend | up | 5173 |

**Se algum container não subir:**
```bash
docker compose logs <nome-do-container>
```

---

## Configurar o N8N

### 1. Acessar N8N

Abra: **http://localhost:5678**

Aguarde ~15 segundos na primeira vez.

### 2. Criar Conta (primeira vez)

- Preencha: Nome, Email, Senha
- Este será seu usuário administrador
- **Anote suas credenciais!**

### 3. Configurar Credenciais

Após fazer login, vá em **Menu lateral → Credentials → New**

#### A) PostgreSQL

1. Busque: `PostgreSQL`
2. Preencha:
   ```
   Host: postgres
   Database: chatbot
   User: n8n
   Password: n8n_password
   Port: 5432
   ```
3. Salve como: **PostgreSQL - Chatbot**

#### B) OpenAI

1. Busque: `OpenAI`
2. Cole sua **API Key** (sk-...)
3. Salve como: **OpenAI API**

#### C) Header Auth (para autenticação da API)

1. Busque: `Header Auth`
2. Preencha:
   - **Name:** `X-API-Key`
   - **Value:** (copie o valor de VITE_API_KEY do seu .env)
3. Salve como: **X-API-Key Auth**

---

## Importar Workflows

1. Menu → **Workflows** → **Import from File**
2. Importe os arquivos da pasta `n8n/workflows/`:
   - `chat-handler.json`
   - `reminder-system.json`
   - `reminder-check.json`
   - `user-management-api-bloqueio.json`
   - `user-management-api-desbloqueio.json`
   - `scheduled-appointments-create.json`
   - `scheduled-appointments-get.json`
   - `scheduled-appointments-update.json`
   - `scheduled-appointments-delete.json`
   - `scheduled-appointments-notifier.json`
3. Para cada workflow importado:
   - Abra o workflow
   - Clique em **Active** (botão verde no canto superior direito)

---

## Configurar PgAdmin (Opcional)

### 1. Acessar PgAdmin

Abra: **http://localhost:5050**

Login:
- Email: `admin@chatbot.com`
- Senha: `Admin@123`

### 2. Conectar ao PostgreSQL

Se o servidor "Chatbot DB" não aparecer automaticamente:

1. Clique direito em **Servers** → **Register** → **Server**
2. Aba **General**: Name = `Chatbot DB`
3. Aba **Connection**:
   ```
   Host: postgres
   Port: 5432
   Username: n8n
   Password: n8n_password
   ✅ Save password
   ```
4. Clique **Save**

### 3. Explorar Tabelas

Navegue: Servers → Chatbot DB → Databases → **chatbot** → Schemas → public → Tables

Você verá: `users`, `interactions`, `agendamentos`, `reminders`

---

## Testar o Sistema

### Verificar serviços

**Todos os sistemas:**
```bash
# PostgreSQL
docker exec chatbot-postgres psql -U n8n -d chatbot -c "\dt"

# N8N
curl http://localhost:5678/healthz
```

**macOS/Linux - Redis:**
```bash
docker exec chatbot-redis redis-cli -a $(grep QUEUE_BULL_REDIS_PASSWORD .env | cut -d'=' -f2) ping
```

**Windows PowerShell - Redis:**
```powershell
$senha = (Get-Content .env | Select-String "QUEUE_BULL_REDIS_PASSWORD").Line.Split("=")[1]
docker exec chatbot-redis redis-cli -a $senha ping
```

### Testar o Chat

**macOS/Linux:**
```bash
curl -X POST http://localhost:5679/webhook/chat \
  -H "X-API-Key: $(grep VITE_API_KEY .env | cut -d'=' -f2)" \
  -H "Content-Type: application/json" \
  -d '{"nome":"Teste","email":"teste@example.com","message":"Olá!"}'
```

**Ou acesse o Frontend:** http://localhost:5173

---

## URLs de Acesso

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| **Frontend** | http://localhost:5173 | - |
| **N8N Editor** | http://localhost:5678 | (você criou) |
| **N8N Webhooks** | http://localhost:5679/webhook/* | Header X-API-Key |
| **PgAdmin** | http://localhost:5050 | admin@chatbot.com / Admin@123 |

---

## Comandos Úteis

```bash
# Ver status
docker compose ps

# Ver logs
docker compose logs -f n8n-editor
docker compose logs -f postgres
docker compose logs -f redis

# Parar tudo
docker compose down

# Reiniciar
docker compose restart

# Escalar workers (para mais performance)
docker compose up -d --scale n8n-worker=3

# Reset completo (APAGA DADOS!)
docker compose down -v
docker compose up -d
```

---

## Troubleshooting

### Container não sobe

```bash
docker compose logs <container>
```

### Porta em uso

**macOS/Linux:**
```bash
lsof -i :5678
```

**Windows:**
```powershell
netstat -ano | findstr :5678
```

### N8N não abre

1. Aguarde 30 segundos
2. Verifique logs: `docker compose logs n8n-editor`
3. Reinicie: `docker compose restart n8n-editor`

### Redis não conecta

```bash
# Verificar senha no .env
cat .env | grep QUEUE_BULL_REDIS_PASSWORD

# Deve ter valor (não pode ser "GERE_SUA_SENHA_AQUI")
```

### Worker reiniciando

```bash
# Verificar encryption key
cat .env | grep N8N_ENCRYPTION_KEY

# Deve ter valor hex de 32 caracteres
```

### Erro de conexão PostgreSQL no N8N

- Host deve ser `postgres` (não `localhost`)
- Database deve ser `chatbot` (não `n8n`)
- Senha: `n8n_password`

### OpenAI erro 401

- Verificar se a API Key está correta
- Verificar se tem créditos: https://platform.openai.com/usage

---

## Checklist Final

- [ ] 7 containers rodando (`docker compose ps`)
- [ ] N8N acessível (http://localhost:5678)
- [ ] Conta criada no N8N
- [ ] Credencial **PostgreSQL - Chatbot** configurada
- [ ] Credencial **OpenAI API** configurada
- [ ] Credencial **X-API-Key Auth** configurada
- [ ] 10 workflows importados e ativos
- [ ] Frontend acessível (http://localhost:5173)
- [ ] Teste de chat funcionando

---

## Próximos Passos

- Leia o [README.md](../README.md) - Documentação da API
- Veja exemplos em [API_EXAMPLES.md](API_EXAMPLES.md)
- Entenda a arquitetura em [ARCHITECTURE.md](ARCHITECTURE.md)

---

**Setup completo!**

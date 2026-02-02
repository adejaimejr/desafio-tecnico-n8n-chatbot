# API Examples - Chatbot N8N

Exemplos de requests para todos os endpoints da API.

**Base URL Local:** `http://localhost:5679/webhook`

---

## Autenticação

Todos os endpoints requerem autenticação via header `X-API-Key`.

```
X-API-Key: TirW14Ep2MYbZOC8wkFoDeYb
```

> **IMPORTANTE:** A API Key acima é apenas um exemplo para desenvolvimento.
> Em produção, gere uma nova chave segura e configure no N8N.

**Response 401 (Não autenticado):**
```json
{
  "code": 401,
  "message": "Authorization failed - please check your credential"
}
```

---

## 1. Chat Handler

### POST /webhook/chat - Enviar mensagem

**cURL:**
```bash
curl -X POST http://localhost:5679/webhook/chat \
  -H "X-API-Key: TirW14Ep2MYbZOC8wkFoDeYb" \
  -H "Content-Type: application/json" \
  -d '{
    "nome": "Carlos Santos",
    "email": "carlos@example.com",
    "message": "Olá, preciso de ajuda!"
  }'
```

**Response 200 (Sucesso):**
```json
{
  "success": true,
  "response": "Olá Carlos! Como posso ajudá-lo hoje?",
  "timestamp": "2026-02-02T10:30:00.000Z"
}
```

**Response 403 (Usuário Bloqueado):**
```json
{
  "success": false,
  "error": "Usuário bloqueado",
  "email": "carlos@example.com"
}
```

**Response 422 (Validação):**
```json
{
  "success": false,
  "error": "Validação falhou",
  "details": {
    "email": "Email inválido",
    "message": "Mensagem é obrigatória"
  }
}
```

---

## 2. User Management API

### POST /api/v1/bloqueio - Bloquear usuário

**cURL:**
```bash
curl -X POST http://localhost:5679/webhook/api/v1/bloqueio \
  -H "X-API-Key: TirW14Ep2MYbZOC8wkFoDeYb" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "usuario@example.com"
  }'
```

**Response 200 (Sucesso):**
```json
{
  "success": true,
  "message": "Usuário bloqueado com sucesso",
  "user": {
    "id": "b392b8ea-010c-47b0-b160-827826873372",
    "email": "usuario@example.com",
    "bloqueado": true
  }
}
```

**Response 404 (Não encontrado):**
```json
{
  "success": false,
  "error": "Usuário não encontrado",
  "email": "usuario@example.com"
}
```

---

### POST /api/v1/desbloqueio - Desbloquear usuário

**cURL:**
```bash
curl -X POST http://localhost:5679/webhook/api/v1/desbloqueio \
  -H "X-API-Key: TirW14Ep2MYbZOC8wkFoDeYb" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "usuario@example.com"
  }'
```

**Response 200 (Sucesso):**
```json
{
  "success": true,
  "message": "Usuário desbloqueado com sucesso",
  "user": {
    "id": "b392b8ea-010c-47b0-b160-827826873372",
    "email": "usuario@example.com",
    "bloqueado": false
  }
}
```

---

## 3. Scheduled Appointments API

### POST /api/v1/agendamento - Criar agendamento

**cURL:**
```bash
curl -X POST http://localhost:5679/webhook/api/v1/agendamento \
  -H "X-API-Key: TirW14Ep2MYbZOC8wkFoDeYb" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "carlos@example.com",
    "data_agendada": "2026-02-15T14:00:00-03:00",
    "mensagem": "Reunião de planejamento Q1"
  }'
```

**Response 201 (Criado):**
```json
{
  "success": true,
  "message": "Agendamento criado com sucesso",
  "agendamento": {
    "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "user_id": "b392b8ea-010c-47b0-b160-827826873372",
    "nome": "Carlos Santos",
    "email": "carlos@example.com",
    "data_agendada": "2026-02-15T17:00:00.000Z",
    "mensagem": "Reunião de planejamento Q1",
    "status": "pendente",
    "notificado": false,
    "created_at": "2026-02-02T10:30:00.000Z"
  }
}
```

**Response 404 (Usuário não encontrado):**
```json
{
  "success": false,
  "error": "Usuário não encontrado",
  "email": "naoexiste@example.com"
}
```

**Response 422 (Validação):**
```json
{
  "success": false,
  "error": "Validação falhou",
  "details": {
    "data_agendada": "Data deve ser futura"
  }
}
```

---

### GET /api/v1/agendamento/:id - Consultar agendamento

**cURL:**
```bash
curl -X GET "http://localhost:5679/webhook/api/v1/agendamento/f47ac10b-58cc-4372-a567-0e02b2c3d479" \
  -H "X-API-Key: TirW14Ep2MYbZOC8wkFoDeYb"
```

**Response 200 (Sucesso):**
```json
{
  "success": true,
  "agendamento": {
    "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "user_id": "b392b8ea-010c-47b0-b160-827826873372",
    "nome": "Carlos Santos",
    "email": "carlos@example.com",
    "data_agendada": "2026-02-15T17:00:00.000Z",
    "mensagem": "Reunião de planejamento Q1",
    "status": "pendente",
    "notificado": false,
    "created_at": "2026-02-02T10:30:00.000Z",
    "updated_at": "2026-02-02T10:30:00.000Z"
  }
}
```

**Response 404 (Não encontrado):**
```json
{
  "success": false,
  "error": "Agendamento não encontrado",
  "id": "00000000-0000-0000-0000-000000000000"
}
```

---

### PUT /api/v1/agendamento/:id - Atualizar agendamento

**cURL:**
```bash
curl -X PUT "http://localhost:5679/webhook/api/v1/agendamento/f47ac10b-58cc-4372-a567-0e02b2c3d479" \
  -H "X-API-Key: TirW14Ep2MYbZOC8wkFoDeYb" \
  -H "Content-Type: application/json" \
  -d '{
    "data_agendada": "2026-02-16T15:00:00-03:00",
    "mensagem": "Reunião remarcada para dia 16"
  }'
```

**Response 200 (Sucesso):**
```json
{
  "success": true,
  "message": "Agendamento atualizado com sucesso",
  "agendamento": {
    "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "data_agendada": "2026-02-16T18:00:00.000Z",
    "mensagem": "Reunião remarcada para dia 16",
    "status": "pendente",
    "updated_at": "2026-02-02T11:00:00.000Z"
  }
}
```

**Response 400 (Não editável):**
```json
{
  "success": false,
  "error": "Agendamento não pode ser editado",
  "reason": "Status 'cancelado' não permite alterações"
}
```

---

### DELETE /api/v1/agendamento/:id - Cancelar agendamento

**cURL:**
```bash
curl -X DELETE "http://localhost:5679/webhook/api/v1/agendamento/f47ac10b-58cc-4372-a567-0e02b2c3d479" \
  -H "X-API-Key: TirW14Ep2MYbZOC8wkFoDeYb"
```

**Response 200 (Sucesso):**
```json
{
  "success": true,
  "message": "Agendamento cancelado com sucesso",
  "agendamento": {
    "id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "status": "cancelado",
    "updated_at": "2026-02-02T11:30:00.000Z"
  }
}
```

---

## Códigos HTTP

| Código | Significado |
|--------|-------------|
| 200 | Sucesso |
| 201 | Criado com sucesso |
| 400 | Requisição inválida (ex: status não editável) |
| 401 | Não autenticado (X-API-Key inválida) |
| 403 | Acesso negado (usuário bloqueado) |
| 404 | Recurso não encontrado |
| 422 | Validação falhou |

---

## Configurar Autenticação no N8N

### 1. Criar Credential

1. Acesse **http://localhost:5678**
2. Vá em **Settings** → **Credentials** → **Add Credential**
3. Busque **Header Auth**
4. Configure:
   - **Name:** `X-API-Key Auth`
   - **Header Name:** `X-API-Key`
   - **Header Value:** `TirW14Ep2MYbZOC8wkFoDeYb`
5. Clique **Save**

### 2. Configurar em cada Webhook

1. Abra o workflow
2. Clique no node **Webhook**
3. Em **Authentication**, selecione **Header Auth**
4. Em **Credential**, selecione **X-API-Key Auth**
5. Salve o workflow

### Workflows que precisam de autenticação:
- Chat Handler
- User Management API - Bloqueio
- User Management API - Desbloqueio
- Scheduled Appointments - Create
- Scheduled Appointments - Get
- Scheduled Appointments - Update
- Scheduled Appointments - Delete

---

## Postman Collection

### Variáveis de Ambiente

```json
{
  "base_url": "http://localhost:5679/webhook",
  "api_key": "TirW14Ep2MYbZOC8wkFoDeYb"
}
```

### Headers (adicionar em todas requests)

| Header | Value |
|--------|-------|
| X-API-Key | `{{api_key}}` |
| Content-Type | application/json |

### Requests

| Nome | Método | URL |
|------|--------|-----|
| Chat - Enviar Mensagem | POST | `{{base_url}}/chat` |
| User - Bloquear | POST | `{{base_url}}/api/v1/bloqueio` |
| User - Desbloquear | POST | `{{base_url}}/api/v1/desbloqueio` |
| Agendamento - Criar | POST | `{{base_url}}/api/v1/agendamento` |
| Agendamento - Consultar | GET | `{{base_url}}/api/v1/agendamento/:id` |
| Agendamento - Atualizar | PUT | `{{base_url}}/api/v1/agendamento/:id` |
| Agendamento - Cancelar | DELETE | `{{base_url}}/api/v1/agendamento/:id` |

---

## Insomnia

### Environment

```json
{
  "base_url": "http://localhost:5679/webhook",
  "api_key": "TirW14Ep2MYbZOC8wkFoDeYb"
}
```

### Headers (adicionar em todas requests)

```
X-API-Key: {{ _.api_key }}
Content-Type: application/json
```

---

## Testes Rápidos (Copy & Paste)

### Testar Chat
```bash
curl -s -X POST http://localhost:5679/webhook/chat \
  -H "X-API-Key: TirW14Ep2MYbZOC8wkFoDeYb" \
  -H "Content-Type: application/json" \
  -d '{"nome":"Teste","email":"teste@example.com","message":"Ola!"}' | jq .
```

### Testar Bloqueio
```bash
curl -s -X POST http://localhost:5679/webhook/api/v1/bloqueio \
  -H "X-API-Key: TirW14Ep2MYbZOC8wkFoDeYb" \
  -H "Content-Type: application/json" \
  -d '{"email":"teste@example.com"}' | jq .
```

### Testar Desbloqueio
```bash
curl -s -X POST http://localhost:5679/webhook/api/v1/desbloqueio \
  -H "X-API-Key: TirW14Ep2MYbZOC8wkFoDeYb" \
  -H "Content-Type: application/json" \
  -d '{"email":"teste@example.com"}' | jq .
```

### Testar Criar Agendamento
```bash
curl -s -X POST http://localhost:5679/webhook/api/v1/agendamento \
  -H "X-API-Key: TirW14Ep2MYbZOC8wkFoDeYb" \
  -H "Content-Type: application/json" \
  -d '{"email":"teste@example.com","data_agendada":"2026-02-20T10:00:00-03:00","mensagem":"Teste agendamento"}' | jq .
```

### Testar sem autenticação (deve retornar 401)
```bash
curl -s -X POST http://localhost:5679/webhook/chat \
  -H "Content-Type: application/json" \
  -d '{"nome":"Teste","email":"teste@example.com","message":"Ola!"}' | jq .
```

---

> **Nota:** A API Key `TirW14Ep2MYbZOC8wkFoDeYb` é apenas um exemplo.
> Em produção, altere para uma chave segura gerada com: `openssl rand -base64 24`

**Última atualização:** 2026-02-02

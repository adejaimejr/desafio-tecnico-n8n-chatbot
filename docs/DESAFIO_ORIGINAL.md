# Desafio Técnico – Chatbot com Agendamento e Bloqueio de Contatos usando N8N

📌 **Descrição**  
Implemente um chatbot utilizando o N8N como backend. O chatbot deve ser capaz de interagir com o usuário, realizar agendamentos de conversas, bloquear e desbloquear usuários, e enviar lembretes de mensagens caso o usuário não responda dentro de 15 minutos. Caso o usuário não responda após o segundo lembrete, nenhuma nova mensagem será enviada. Além disso, o chatbot deve ser capaz de respeitar as preferências de comunicação do usuário, como o bloqueio definitivo de mensagens, e fornecer uma interface simples para o usuário interagir.

Ao finalizar, publique o repositório no GitHub e compartilhe o link para avaliação.

## 🚀 Stack Obrigatória  
- **Backend:** N8N  
- **Frontend:** React (ou qualquer framework de sua escolha para uma interface de chat simples)  
- **Banco de Dados:** Pode ser utilizado qualquer banco de dados simples para armazenamento das interações (Ex: SQLite, MongoDB, etc.).  
- **Webhooks:** Para integração entre o frontend e N8N.  
- **LLM (Modelos de Linguagem de Grande Escala):** Integração obrigatória com uma API de LLM gratuita (OpenAI GPT-3 ou Hugging Face) para respostas dinâmicas.

## 🗂️ **Modelagem de Domínio**  
- **Usuário**  
  - id (UUID)  
  - nome (obrigatório)  
  - email (obrigatório, único)  
  - bloqueado (boolean)  
  - interações (array de mensagens)  

- **Agendamento de Conversa**  
  - id (UUID)  
  - usuario_id (FK para Usuário)  
  - data_agendada (datetime)  
  - status (pendente, cancelado, realizado)  

### **Regras de Negócio**  
- O **email** do usuário deve ser único.  
- O usuário pode ser bloqueado, o que impede que o bot envie mensagens para ele.  
- O **agendamento** de conversas deve ser validado e confirmado antes de ser salvo.  
- Se o usuário não responder dentro de **15 minutos**, um lembrete deve ser enviado. Caso ele não responda após o segundo lembrete, nenhuma nova mensagem será enviada.  
- Caso o usuário tenha sido bloqueado, quando a pessoa entrar em contato o bot deve alertar que ele foi adicionado a lista de bloqueio e deve permitir que ele se desbloqueie.



## ⚖️ **Regras Adicionais**  
- **Prevenção de Ciclos**: Caso o usuário bloqueie o chatbot, ele não pode ser contatado novamente até que se desbloqueie.  
- **Timeout de 15 minutos**: Se o usuário não interagir após 15 minutos de uma mensagem enviada, o bot deve relembrá-lo. Caso o usuário não responda após o segundo lembrete, nenhuma nova mensagem será enviada.  
- **Webhook para Frontend**: O frontend deve se comunicar com N8N via webhook, enviando as interações e recebendo respostas para exibição no chat.

## 📦 **Entregáveis**  
1. **Código em Repositório GitHub**.  
2. **README.md contendo**:
   - Como rodar o projeto com N8N.
   - Como configurar o frontend (React ou outra ferramenta).
   - Como acessar a documentação da API.
   - Exemplos de requests (via curl/Postman/Insomnia).
   - Como configurar a API de LLM (ex: OpenAI, Hugging Face).
3. **docker-compose.yml** para facilitar o setup local com N8N e banco de dados.
4. **Documentação Swagger** (opcional, caso tenha uma API mais robusta).

## ✅ **Como Entregar**  
1. Suba o código no GitHub (público ou privado com acesso).
2. Inclua no **README.md**:
= Como acessar o fluxo
- Caso seja necessário rodar algo localmente em docker, quais comandos rodar
4. Envie o link do repositório para avaliação.

## 🏆 **Critérios de Avaliação**  
- **Qualidade do Código**: Clareza, organização e modularização do código. O fluxo do bot deve ser bem estruturado no N8N.  
- **Funcionalidade**: O chatbot deve ser funcional e capaz de lidar com as interações descritas (agendamento, bloqueio, lembretes, etc.).  
- **Integração Front-End/Back-End**: O frontend deve estar corretamente integrado ao N8N via webhooks e capaz de exibir as mensagens de forma dinâmica.  
- **Documentação**: O README deve ser claro e fácil de seguir para rodar o projeto localmente.  
- **Implementação de Regras de Negócio**: Bloqueio de usuário, agendamento e resposta automática em 15 minutos funcionando corretamente.
- **Frontend**: O frontend não será avaliado por beleza, apenas o correto funcionanmento dele se comunicando com a API. Caso prefira existe um arquivo de exemplo nesse repositório.

## ⭐ **Diferenciais (Bônus)**  
- **Prevenção de Prompt Injection**: Implementação de técnicas de defesa contra injeções de comandos no chatbot.
- **Exposição de endpoint para agendar conversa via API**: A API deve permitir que o agendamento de conversasm ou bloqueio seja feito externamente, sem interação com o frontend.
  


## **Hospedagem**

### N8N:
O N8N deve estar hospedado em uma plataforma gratuita como:

- N8N Cloud (Plano gratuito)

- Heroku (Plano gratuito)

- Railway (Plano gratuito)

### Frontend:
Você pode hospedar o front-end (React) gratuitamente em plataformas como:

- Netlify

- Vercel

- GitHub Pages (se o código do frontend estiver no GitHub)


## 📚 **Endpoints para o desafio de exposição da API**  
- **/api/v1/agendamento**  
  - `POST /api/v1/agendamento` → Cria um novo agendamento para conversa.  
  - `GET /api/v1/agendamento/:id` → Retorna um agendamento específico.  
  - `PUT /api/v1/agendamento/:id` → Atualiza um agendamento (confirmar ou cancelar).  
  - `DELETE /api/v1/agendamento/:id` → Remove o agendamento.  

- **/api/v1/bloqueio**  
  - `POST /api/v1/bloqueio` → Bloqueia o usuário para não receber mais mensagens.  

  - `POST /api/v1/desbloqueio` → Desbloqueia o usuário para permitir novas mensagens.  


import { useState, useRef, useEffect, useCallback } from 'react';
import ChatBot from 'react-chatbotify';
import { sendMessage, unblockUser, checkReminders } from './api';
import './App.css';

function App() {
  // Refs para acesso síncrono no fluxo
  const userDataRef = useRef({ nome: '', email: '' });
  const isRegisteredRef = useRef(false);

  const [isBlocked, setIsBlocked] = useState(false);
  const [isUnblocking, setIsUnblocking] = useState(false);
  const [reminderMessages, setReminderMessages] = useState([]);
  const [isRegistered, setIsRegistered] = useState(false);

  // Polling para verificar lembretes (a cada 30 segundos)
  const checkForReminders = useCallback(async () => {
    if (!userDataRef.current.email || isBlocked) {
      return;
    }

    try {
      const result = await checkReminders(userDataRef.current.email);
      if (result.success && result.has_reminders && result.reminders.length > 0) {
        // Adiciona novos lembretes à lista
        setReminderMessages(prev => {
          const newReminders = result.reminders.filter(
            r => !prev.some(p => p.id === r.id)
          );
          return [...prev, ...newReminders];
        });
      }
    } catch (error) {
      console.error('Erro no polling de lembretes:', error);
    }
  }, [isBlocked]);

  // Inicia polling quando usuário está registrado
  useEffect(() => {
    let intervalId;

    if (isRegistered && userDataRef.current.email && !isBlocked) {
      // Verifica imediatamente após 5 segundos
      const timeoutId = setTimeout(checkForReminders, 5000);
      // E depois a cada 30 segundos
      intervalId = setInterval(checkForReminders, 30000);

      return () => {
        clearTimeout(timeoutId);
        clearInterval(intervalId);
      };
    }

    return () => {
      if (intervalId) {
        clearInterval(intervalId);
      }
    };
  }, [checkForReminders, isBlocked, isRegistered]);

  // Limpa lembrete após ser exibido
  const dismissReminder = (reminderId) => {
    setReminderMessages(prev => prev.filter(r => r.id !== reminderId));
  };

  // Configuração do tema
  const settings = {
    general: {
      embedded: false,
      primaryColor: '#6366f1',
      secondaryColor: '#4f46e5',
      fontFamily: 'Inter, system-ui, sans-serif',
      showFooter: false,
    },
    header: {
      title: 'ChatBot - Desafio N8N',
      avatar: 'https://api.dicebear.com/7.x/bottts/svg?seed=desafio',
    },
    chatHistory: {
      storageKey: 'chatbot_n8n_history',
    },
    botBubble: {
      showAvatar: true,
    },
    tooltip: {
      text: 'Olá! 👋',
    },
  };

  // Estilos customizados
  const styles = {
    headerStyle: {
      background: 'linear-gradient(135deg, #6366f1 0%, #4f46e5 100%)',
      color: '#fff',
    },
    chatWindowStyle: {
      backgroundColor: '#f8fafc',
    },
    userBubbleStyle: {
      backgroundColor: '#6366f1',
      color: '#fff',
    },
    botBubbleStyle: {
      backgroundColor: '#fff',
      color: '#1e293b',
      border: '1px solid #e2e8f0',
    },
  };

  // Fluxo do chatbot
  const flow = {
    start: {
      message: 'Olá! Bem-vindo ao ChatBot - Desafio N8N. Qual é o seu nome?',
      path: 'get_name',
    },
    get_name: {
      message: (params) => {
        userDataRef.current.nome = params.userInput;
        return `Prazer, ${params.userInput}! Qual é o seu email?`;
      },
      path: 'get_email',
    },
    get_email: {
      message: (params) => {
        // Se já está registrado, vai direto para o chat
        if (isRegisteredRef.current) {
          return null; // Não exibe mensagem, vai direto pro chat
        }

        const email = params.userInput;
        // Validação básica de email
        if (!email.includes('@') || !email.includes('.')) {
          return 'Por favor, informe um email válido.';
        }
        userDataRef.current.email = email;
        isRegisteredRef.current = true;
        setIsRegistered(true); // Ativa o polling de lembretes
        return `Ótimo! Agora você pode conversar comigo. Como posso ajudar?`;
      },
      path: () => {
        // Se já está registrado, vai direto para o chat
        if (isRegisteredRef.current) {
          return 'chat';
        }
        // Verifica se o email atual é válido
        const email = userDataRef.current.email;
        if (email && email.includes('@') && email.includes('.')) {
          return 'chat';
        }
        return 'get_email';
      },
    },
    chat: {
      message: async (params) => {
        const { nome, email } = userDataRef.current;
        if (!nome || !email) {
          return 'Por favor, reinicie a conversa informando seu nome e email.';
        }

        try {
          const result = await sendMessage(
            nome,
            email,
            params.userInput
          );

          // Verifica se usuário está bloqueado (HTTP 403)
          if (result.httpStatus === 403 || result.error === 'Usuário bloqueado') {
            setIsBlocked(true);
            return `⚠️ Você está bloqueado e não pode enviar mensagens.

Use o botão "Desbloquear" abaixo para voltar a conversar.`;
          }

          // Erro de validação
          if (result.httpStatus === 422) {
            return `❌ Erro de validação: ${JSON.stringify(result.details || result.error)}`;
          }

          // Sucesso
          if (result.success && result.response) {
            return result.response;
          }

          return result.error || 'Desculpe, ocorreu um erro. Tente novamente.';
        } catch (error) {
          console.error('Erro ao enviar mensagem:', error);
          return '❌ Erro de conexão. Verifique se o N8N está rodando.';
        }
      },
      path: 'chat',
    },
  };

  // Função de desbloqueio
  const handleUnblock = async () => {
    if (!userDataRef.current.email) {
      alert('Email não encontrado. Reinicie a conversa.');
      return;
    }

    setIsUnblocking(true);
    try {
      const result = await unblockUser(userDataRef.current.email);
      if (result.success) {
        setIsBlocked(false);
        alert('✅ Você foi desbloqueado! Pode voltar a conversar.');
      } else {
        alert(`❌ Erro: ${result.error || 'Não foi possível desbloquear'}`);
      }
    } catch (error) {
      alert('❌ Erro de conexão ao tentar desbloquear.');
    }
    setIsUnblocking(false);
  };

  return (
    <div className="app-container">
      <ChatBot settings={settings} styles={styles} flow={flow} />

      {/* Notificações de lembrete */}
      {reminderMessages.length > 0 && (
        <div className="reminder-container">
          {reminderMessages.map((reminder) => (
            <div
              key={reminder.id}
              className={`reminder-card ${reminder.is_last ? 'reminder-last' : ''}`}
            >
              <div className="reminder-header">
                <span className="reminder-icon">⏰</span>
                <span className="reminder-title">
                  {reminder.is_last ? 'Último Lembrete' : 'Lembrete'}
                </span>
                <button
                  className="reminder-close"
                  onClick={() => dismissReminder(reminder.id)}
                >
                  ✕
                </button>
              </div>
              <p className="reminder-message">{reminder.message}</p>
            </div>
          ))}
        </div>
      )}

      {/* Botão de desbloqueio - aparece quando bloqueado */}
      {isBlocked && (
        <div className="unblock-container">
          <div className="unblock-card">
            <span className="unblock-icon">🔒</span>
            <p>Você está bloqueado</p>
            <button
              className="unblock-button"
              onClick={handleUnblock}
              disabled={isUnblocking}
            >
              {isUnblocking ? 'Desbloqueando...' : '🔓 Desbloquear'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;

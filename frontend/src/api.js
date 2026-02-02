// API de integração com N8N
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:5679/webhook';
const API_KEY = import.meta.env.VITE_API_KEY || 'TirW14Ep2MYbZOC8wkFoDeYb';

/**
 * Envia mensagem para o chatbot
 */
export async function sendMessage(nome, email, message) {
  const response = await fetch(`${API_URL}/chat`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': API_KEY,
    },
    body: JSON.stringify({ nome, email, message }),
  });

  const data = await response.json();

  // Retorna dados junto com status HTTP para tratamento de bloqueio
  return {
    ...data,
    httpStatus: response.status,
  };
}

/**
 * Desbloqueia usuário
 */
export async function unblockUser(email) {
  const response = await fetch(`${API_URL}/api/v1/desbloqueio`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': API_KEY,
    },
    body: JSON.stringify({ email }),
  });

  return response.json();
}

/**
 * Verifica se há lembretes pendentes para o usuário
 * Usado para polling de lembretes do sistema de timeout 15min
 */
export async function checkReminders(email) {
  try {
    const response = await fetch(`${API_URL}/check-reminders?email=${encodeURIComponent(email)}`, {
      method: 'GET',
      headers: {
        'X-API-Key': API_KEY,
      },
    });

    if (!response.ok) {
      return { success: false, has_reminders: false, reminders: [] };
    }

    return response.json();
  } catch (error) {
    console.error('Erro ao verificar lembretes:', error);
    return { success: false, has_reminders: false, reminders: [] };
  }
}

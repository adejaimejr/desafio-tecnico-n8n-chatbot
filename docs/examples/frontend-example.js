import React, { useState, useEffect } from 'react';

function ChatBot() {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const [isBlocked, setIsBlocked] = useState(false);

  // Função para enviar a mensagem para o N8N
  const sendMessage = async () => {
    if (input.trim() === '') return;

    // Envia a mensagem para o webhook do N8N
    const response = await fetch('https://seu-n8n-api.com/webhook', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: input }),
    });

    const data = await response.json();

    if (data.status === 'blocked') {
      setIsBlocked(true); // Marca como bloqueado
    } else {
      setMessages([...messages, { from: 'user', text: input }, { from: 'bot', text: data.response }]);
    }
    setInput('');
  };

  useEffect(() => {
    // Checa se o usuário foi bloqueado
    if (isBlocked) {
      setMessages([...messages, { from: 'bot', text: 'Você foi bloqueado. Se desejar retomar o contato, por favor, desbloqueie.' }]);
    }
  }, [isBlocked]);

  return (
    <div className="chat">
      <div className="messages">
        {messages.map((msg, index) => (
          <div key={index} className={msg.from}>
            {msg.text}
          </div>
        ))}
      </div>
      <input
        type="text"
        value={input}
        onChange={(e) => setInput(e.target.value)}
        onKeyDown={(e) => e.key === 'Enter' && sendMessage()}
        disabled={isBlocked}
      />
      <button onClick={sendMessage} disabled={isBlocked}>Enviar</button>
    </div>
  );
}

export default ChatBot;

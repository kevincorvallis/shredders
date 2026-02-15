'use client';

import { useChat } from '@ai-sdk/react';
import { DefaultChatTransport } from 'ai';
import { useEffect, useRef, useState, FormEvent, useMemo } from 'react';
import { ChatMessage } from './ChatMessage';
import { ChatInput } from './ChatInput';

export function ChatInterface() {
  const transport = useMemo(() => new DefaultChatTransport({ api: '/api/chat' }), []);

  const { messages, sendMessage, status, error } = useChat({
    transport,
  });

  const [input, setInput] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const scrollContainerRef = useRef<HTMLDivElement>(null);

  const isLoading = status === 'streaming' || status === 'submitted';

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!input.trim() || isLoading) return;
    const message = input;
    setInput('');
    await sendMessage({
      role: 'user',
      parts: [{ type: 'text', text: message }],
    });
  };

  // Auto-scroll to bottom on new messages
  useEffect(() => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [messages]);

  return (
    <div className="flex flex-col h-full bg-background">
      {/* Header */}
      <header className="flex-shrink-0 px-4 py-3 border-b border-border-secondary bg-[var(--header-bg)] backdrop-blur-xl backdrop-saturate-150">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-accent flex items-center justify-center">
            <span className="text-xl">🏔️</span>
          </div>
          <div>
            <h1 className="text-text-primary font-semibold">Shredders AI</h1>
            <p className="text-text-tertiary text-xs">Your mountain conditions assistant</p>
          </div>
          <div className="ml-auto flex items-center gap-2">
            <span className="flex items-center gap-1.5 px-2 py-1 bg-green-500/10 text-green-400 rounded-full text-xs">
              <span className="w-1.5 h-1.5 bg-green-400 rounded-full animate-pulse"></span>
              Live Data
            </span>
          </div>
        </div>
      </header>

      {/* Messages area */}
      <div
        ref={scrollContainerRef}
        className="flex-1 overflow-y-auto px-4 py-6 space-y-6"
      >
        {messages.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full text-center">
            <div className="w-20 h-20 rounded-2xl bg-accent-subtle flex items-center justify-center mb-4">
              <span className="text-4xl">🏔️</span>
            </div>
            <h2 className="text-text-primary text-xl font-semibold mb-2">Welcome to Shredders AI</h2>
            <p className="text-text-secondary max-w-sm mb-6">
              Ask me about mountain conditions, weather forecasts, powder scores, or compare resorts.
            </p>
            <div className="grid grid-cols-2 gap-2 max-w-md">
              {[
                { icon: '❄️', text: "How's the powder today?" },
                { icon: '📊', text: 'Show me snow history' },
                { icon: '📷', text: 'Pull up the webcam' },
                { icon: '🆚', text: 'Baker vs Stevens?' },
              ].map((item, idx) => (
                <button
                  key={idx}
                  onClick={() => setInput(item.text)}
                  className="flex items-center gap-2 px-4 py-3 bg-surface-secondary hover:bg-surface-tertiary rounded-xl text-left transition-colors"
                >
                  <span className="text-lg">{item.icon}</span>
                  <span className="text-text-secondary text-sm">{item.text}</span>
                </button>
              ))}
            </div>
          </div>
        ) : (
          messages.map((message, index) => (
            <ChatMessage
              key={message.id}
              message={message}
              isStreaming={isLoading && index === messages.length - 1 && message.role === 'assistant'}
            />
          ))
        )}

        {/* Error display */}
        {error && (
          <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-4 text-red-400 text-sm">
            <p className="font-medium mb-1">Something went wrong</p>
            <p className="text-red-400/80">{error.message}</p>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Input area */}
      <ChatInput
        input={input}
        setInput={setInput}
        onSubmit={handleSubmit}
        isLoading={isLoading}
      />
    </div>
  );
}

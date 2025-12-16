'use client';

import { useChat } from '@ai-sdk/react';
import { DefaultChatTransport } from 'ai';
import { useEffect, useRef, useState, FormEvent, useMemo } from 'react';
import { ChatMessage } from '@/components/chat/ChatMessage';
import { ChatInput } from '@/components/chat/ChatInput';

export default function AgentPage() {
  const transport = useMemo(() => new DefaultChatTransport({ api: '/api/agent' }), []);

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

  useEffect(() => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: 'smooth' });
    }
  }, [messages]);

  return (
    <div className="flex flex-col h-[calc(100vh-64px)] bg-slate-900">
      {/* Header */}
      <header className="flex-shrink-0 px-4 py-3 border-b border-slate-700 bg-slate-900/95 backdrop-blur-sm">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-500 to-teal-600 flex items-center justify-center">
            <span className="text-xl">🤖</span>
          </div>
          <div>
            <h1 className="text-white font-semibold">Shredders Agent</h1>
            <p className="text-gray-500 text-xs">Full-stack assistant with infrastructure access</p>
          </div>
          <div className="ml-auto flex items-center gap-2">
            <span className="flex items-center gap-1.5 px-2 py-1 bg-emerald-500/10 text-emerald-400 rounded-full text-xs">
              <span className="w-1.5 h-1.5 bg-emerald-400 rounded-full animate-pulse"></span>
              Agent Mode
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
            <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-emerald-500/20 to-teal-600/20 flex items-center justify-center mb-4">
              <span className="text-4xl">🤖</span>
            </div>
            <h2 className="text-white text-xl font-semibold mb-2">Shredders Agent</h2>
            <p className="text-gray-400 max-w-sm mb-6">
              I have full context about the Shredders app - APIs, infrastructure, deployment, and real-time mountain data.
            </p>
            <div className="grid grid-cols-2 gap-2 max-w-md">
              {[
                { icon: '❄️', text: "How's Baker looking today?" },
                { icon: '🔌', text: 'Explain the API structure' },
                { icon: '📊', text: 'How does powder scoring work?' },
                { icon: '🏗️', text: 'What data sources do you use?' },
              ].map((item, idx) => (
                <button
                  key={idx}
                  onClick={() => setInput(item.text)}
                  className="flex items-center gap-2 px-4 py-3 bg-slate-800 hover:bg-slate-700 rounded-xl text-left transition-colors"
                >
                  <span className="text-lg">{item.icon}</span>
                  <span className="text-gray-300 text-sm">{item.text}</span>
                </button>
              ))}
            </div>

            {/* Capability cards */}
            <div className="mt-8 grid grid-cols-3 gap-3 max-w-2xl">
              <div className="bg-slate-800/50 rounded-xl p-4 text-left">
                <div className="text-emerald-400 text-lg mb-2">🏔️</div>
                <div className="text-white text-sm font-medium mb-1">Mountain Data</div>
                <div className="text-gray-500 text-xs">Real-time conditions, forecasts, and powder scores for 15 PNW mountains</div>
              </div>
              <div className="bg-slate-800/50 rounded-xl p-4 text-left">
                <div className="text-emerald-400 text-lg mb-2">🔧</div>
                <div className="text-white text-sm font-medium mb-1">Infrastructure</div>
                <div className="text-gray-500 text-xs">Full knowledge of APIs, CLI tools, deployment, and architecture</div>
              </div>
              <div className="bg-slate-800/50 rounded-xl p-4 text-left">
                <div className="text-emerald-400 text-lg mb-2">📡</div>
                <div className="text-white text-sm font-medium mb-1">Data Sources</div>
                <div className="text-gray-500 text-xs">SNOTEL, NOAA, Open-Meteo, and WSDOT integration knowledge</div>
              </div>
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

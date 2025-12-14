import { ChatInterface } from '@/components/chat';

export const metadata = {
  title: 'Shredders AI - Chat',
  description: 'AI-powered mountain conditions assistant',
};

export default function ChatPage() {
  return (
    <main className="h-screen bg-slate-900">
      <ChatInterface />
    </main>
  );
}

import { ChatInterface } from '@/components/chat';

import type { Metadata } from "next";

export const metadata: Metadata = {
  title: 'AI Chat',
  description: 'Ask questions about mountain conditions, powder scores, and trip planning for PNW ski resorts',
};

export default function ChatPage() {
  return (
    <main className="h-screen bg-background">
      <ChatInterface />
    </main>
  );
}

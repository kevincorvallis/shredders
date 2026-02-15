'use client';

import { UIMessage, isTextUIPart, isToolUIPart } from 'ai';
import { ComponentRenderer } from './ComponentRenderer';

interface ChatMessageProps {
  message: UIMessage;
  isStreaming?: boolean;
}

// Helper to extract text from message parts
function getTextContent(message: UIMessage): string {
  return message.parts
    .filter(isTextUIPart)
    .map((part) => part.text)
    .join('');
}

// Helper to extract tool invocations from message parts
function getToolInvocations(message: UIMessage) {
  return message.parts
    .filter(isToolUIPart)
    .map((part) => ({
      toolName: part.type.replace('tool-', ''),
      state: part.state as 'input-streaming' | 'input-available' | 'output-available' | 'output-error',
      toolCallId: part.toolCallId,
      result: 'output' in part ? (part.output as { type: string; [key: string]: unknown }) : undefined,
    }));
}

export function ChatMessage({ message, isStreaming }: ChatMessageProps) {
  const isUser = message.role === 'user';
  const textContent = getTextContent(message);
  const toolInvocations = getToolInvocations(message);

  return (
    <div className={`flex ${isUser ? 'justify-end' : 'justify-start'}`}>
      <div className={`max-w-[90%] ${isUser ? 'order-1' : 'order-2'}`}>
        {/* Avatar */}
        <div className={`flex items-start gap-3 ${isUser ? 'flex-row-reverse' : 'flex-row'}`}>
          <div
            className={`flex-shrink-0 w-8 h-8 rounded-full flex items-center justify-center ${
              isUser
                ? 'bg-accent'
                : 'bg-accent'
            }`}
          >
            {isUser ? (
              <svg
                className="w-5 h-5 text-white"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                />
              </svg>
            ) : (
              <span className="text-white text-sm">🏔️</span>
            )}
          </div>

          <div className={`flex flex-col ${isUser ? 'items-end' : 'items-start'}`}>
            {/* Label */}
            <span className="text-xs text-text-tertiary mb-1">
              {isUser ? 'You' : 'Shredders AI'}
            </span>

            {/* Message bubble */}
            <div
              className={`rounded-2xl px-4 py-2 ${
                isUser
                  ? 'bg-accent text-white rounded-tr-sm'
                  : 'bg-surface-secondary text-text-primary rounded-tl-sm'
              }`}
            >
              {textContent ? (
                <div className="whitespace-pre-wrap">{textContent}</div>
              ) : isStreaming ? (
                <div className="flex items-center gap-1">
                  <div className="w-2 h-2 bg-text-tertiary rounded-full animate-bounce [animation-delay:-0.3s]"></div>
                  <div className="w-2 h-2 bg-text-tertiary rounded-full animate-bounce [animation-delay:-0.15s]"></div>
                  <div className="w-2 h-2 bg-text-tertiary rounded-full animate-bounce"></div>
                </div>
              ) : null}
            </div>

            {/* Tool invocations (widgets) */}
            {!isUser && toolInvocations.length > 0 && (
              <div className="mt-2 w-full">
                <ComponentRenderer toolInvocations={toolInvocations} />
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

'use client';

import { useState } from 'react';
import type { CreateEventResponse } from '@/types/event';

interface PostCreateModalProps {
  response: CreateEventResponse;
  onClose: () => void;
}

export function PostCreateModal({ response, onClose }: PostCreateModalProps) {
  const { event, inviteUrl } = response;
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(inviteUrl);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      // Fallback for older browsers
      const input = document.createElement('input');
      input.value = inviteUrl;
      document.body.appendChild(input);
      input.select();
      document.execCommand('copy');
      document.body.removeChild(input);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const calendarBaseUrl = `/api/events/${event.id}/calendar`;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
      <div className="bg-slate-800 border border-slate-700 rounded-2xl w-full max-w-md overflow-hidden">
        {/* Header */}
        <div className="p-6 text-center">
          <div className="w-16 h-16 bg-green-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h2 className="text-xl font-bold text-white">Event Created!</h2>
          <p className="text-gray-400 text-sm mt-1">{event.title}</p>
        </div>

        {/* Share section */}
        <div className="px-6 pb-4 space-y-4">
          {/* Invite Link */}
          <div>
            <p className="text-xs text-gray-400 mb-2">Share invite link</p>
            <div className="flex gap-2">
              <input
                type="text"
                readOnly
                value={inviteUrl}
                className="flex-1 bg-slate-900 border border-slate-700 rounded-lg px-3 py-2 text-sm text-gray-300 truncate"
              />
              <button
                type="button"
                onClick={handleCopy}
                className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                  copied
                    ? 'bg-green-500/20 text-green-400'
                    : 'bg-sky-500 hover:bg-sky-600 text-white'
                }`}
              >
                {copied ? 'Copied!' : 'Copy'}
              </button>
            </div>
          </div>

          {/* Calendar buttons */}
          <div>
            <p className="text-xs text-gray-400 mb-2">Add to calendar</p>
            <div className="grid grid-cols-3 gap-2">
              <a
                href={`${calendarBaseUrl}?format=google`}
                target="_blank"
                rel="noopener noreferrer"
                className="flex flex-col items-center gap-1 p-3 bg-slate-900 hover:bg-slate-700 rounded-lg transition-colors"
              >
                <span className="text-lg">📅</span>
                <span className="text-xs text-gray-400">Google</span>
              </a>
              <a
                href={`${calendarBaseUrl}?format=apple`}
                className="flex flex-col items-center gap-1 p-3 bg-slate-900 hover:bg-slate-700 rounded-lg transition-colors"
              >
                <span className="text-lg">🍎</span>
                <span className="text-xs text-gray-400">Apple</span>
              </a>
              <a
                href={`${calendarBaseUrl}?format=ics`}
                download
                className="flex flex-col items-center gap-1 p-3 bg-slate-900 hover:bg-slate-700 rounded-lg transition-colors"
              >
                <span className="text-lg">📥</span>
                <span className="text-xs text-gray-400">.ics File</span>
              </a>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="p-4 border-t border-slate-700">
          <button
            type="button"
            onClick={onClose}
            className="w-full py-3 bg-sky-500 hover:bg-sky-600 text-white rounded-xl font-semibold transition-colors"
          >
            View Event
          </button>
        </div>
      </div>
    </div>
  );
}

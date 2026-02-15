'use client';

interface DraftBannerProps {
  savedAt: string;
  onResume: () => void;
  onDiscard: () => void;
}

export function DraftBanner({ savedAt, onResume, onDiscard }: DraftBannerProps) {
  const timeAgo = getTimeAgo(savedAt);

  return (
    <div className="bg-amber-500/10 border border-amber-500/30 rounded-xl px-4 py-3 flex items-center justify-between gap-3">
      <div className="flex items-center gap-2 min-w-0">
        <svg className="w-5 h-5 text-amber-400 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <p className="text-sm text-amber-200 truncate">
          You have an unsaved draft from {timeAgo}
        </p>
      </div>
      <div className="flex items-center gap-2 shrink-0">
        <button
          type="button"
          onClick={onDiscard}
          className="text-xs text-gray-400 hover:text-white transition-colors px-2 py-1"
        >
          Discard
        </button>
        <button
          type="button"
          onClick={onResume}
          className="text-xs font-medium text-amber-400 hover:text-amber-300 transition-colors bg-amber-500/20 px-3 py-1 rounded-full"
        >
          Resume
        </button>
      </div>
    </div>
  );
}

function getTimeAgo(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime();
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return 'just now';
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  return 'yesterday';
}

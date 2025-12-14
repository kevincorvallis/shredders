'use client';

import { AISummary as AISummaryType } from '@/types/mountain';

interface AISummaryProps {
  summary: AISummaryType;
}

export function AISummary({ summary }: AISummaryProps) {
  const generatedTime = new Date(summary.generated).toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
  });

  return (
    <div className="bg-gradient-to-br from-purple-900 to-indigo-900 text-white rounded-xl shadow-lg p-6">
      <div className="flex items-center gap-2 mb-4">
        <div className="w-8 h-8 bg-white/20 rounded-full flex items-center justify-center">
          <span className="text-lg">🤖</span>
        </div>
        <div>
          <h2 className="font-semibold">AI Conditions Report</h2>
          <p className="text-xs text-purple-200">Generated {generatedTime}</p>
        </div>
      </div>

      <h3 className="text-xl font-bold mb-3">{summary.headline}</h3>

      <div className="space-y-4 text-purple-100">
        <p className="text-sm leading-relaxed">{summary.conditions}</p>

        <div className="bg-white/10 rounded-lg p-4">
          <p className="text-sm font-medium text-white mb-1">Recommendation</p>
          <p className="text-sm">{summary.recommendation}</p>
        </div>

        <div className="flex items-center gap-2 text-sm">
          <span className="text-xl">🎿</span>
          <span className="font-medium">Best time to go:</span>
          <span>{summary.bestTimeToGo}</span>
        </div>
      </div>
    </div>
  );
}

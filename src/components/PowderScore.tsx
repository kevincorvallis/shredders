'use client';

import { PowderPrediction } from '@/types/mountain';

interface PowderScoreProps {
  prediction: PowderPrediction;
}

export function PowderScore({ prediction }: PowderScoreProps) {
  const { score, confidence, factors } = prediction;

  const getScoreColor = (score: number) => {
    if (score >= 80) return 'text-green-500';
    if (score >= 60) return 'text-yellow-500';
    if (score >= 40) return 'text-orange-500';
    return 'text-red-500';
  };

  const getScoreLabel = (score: number) => {
    if (score >= 80) return 'Epic';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  };

  const getGradient = (score: number) => {
    if (score >= 80) return 'from-green-400 to-green-600';
    if (score >= 60) return 'from-yellow-400 to-yellow-600';
    if (score >= 40) return 'from-orange-400 to-orange-600';
    return 'from-red-400 to-red-600';
  };

  const dayName = prediction.date.toLocaleDateString('en-US', { weekday: 'long' });

  return (
    <div className="bg-white rounded-xl shadow-lg p-6">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-lg font-semibold text-text-primary">Powder Score</h2>
        <span className="text-sm text-text-quaternary">{dayName}</span>
      </div>

      {/* Score Gauge */}
      <div className="flex flex-col items-center py-4">
        <div className="relative w-36 h-36">
          {/* Background circle */}
          <svg className="w-full h-full transform -rotate-90">
            <circle
              cx="72"
              cy="72"
              r="64"
              fill="none"
              stroke="#e5e7eb"
              strokeWidth="12"
            />
            {/* Progress circle */}
            <circle
              cx="72"
              cy="72"
              r="64"
              fill="none"
              stroke="url(#gradient)"
              strokeWidth="12"
              strokeLinecap="round"
              strokeDasharray={`${(score / 100) * 402} 402`}
            />
            <defs>
              <linearGradient id="gradient" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" className={`${getGradient(score).includes('green') ? 'text-green-400' : getGradient(score).includes('yellow') ? 'text-yellow-400' : getGradient(score).includes('orange') ? 'text-orange-400' : 'text-red-400'}`} style={{ stopColor: 'currentColor' }} />
                <stop offset="100%" className={`${getGradient(score).includes('green') ? 'text-green-600' : getGradient(score).includes('yellow') ? 'text-yellow-600' : getGradient(score).includes('orange') ? 'text-orange-600' : 'text-red-600'}`} style={{ stopColor: 'currentColor' }} />
              </linearGradient>
            </defs>
          </svg>
          {/* Score text */}
          <div className="absolute inset-0 flex flex-col items-center justify-center">
            <span className={`text-4xl font-bold ${getScoreColor(score)}`}>{score}</span>
            <span className="text-sm text-text-quaternary">{getScoreLabel(score)}</span>
          </div>
        </div>
        <p className="text-sm text-text-quaternary mt-2">
          {confidence}% confidence
        </p>
      </div>

      {/* Contributing Factors */}
      <div className="mt-4 space-y-3">
        <h3 className="text-sm font-medium text-text-tertiary">Contributing Factors</h3>
        {factors.map((factor) => (
          <div key={factor.name} className="flex items-center justify-between text-sm">
            <div className="flex items-center gap-2">
              <span className={`w-2 h-2 rounded-full ${factor.contribution > 0 ? 'bg-green-500' : 'bg-red-500'}`} />
              <span className="text-text-tertiary">{factor.name}</span>
            </div>
            <div className="flex items-center gap-2">
              <span className={factor.contribution > 0 ? 'text-green-600' : 'text-red-600'}>
                {factor.contribution > 0 ? '+' : ''}{factor.contribution}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

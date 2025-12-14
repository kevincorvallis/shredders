'use client';

interface PowderScoreData {
  score: number;
  maxScore: number;
  confidence: number;
  trend: string;
  factors: Array<{
    name: string;
    value: string;
    description: string;
  }>;
}

interface PowderScoreWidgetProps {
  mountain: string;
  data: PowderScoreData;
}

export function PowderScoreWidget({ mountain, data }: PowderScoreWidgetProps) {
  const getScoreColor = (score: number) => {
    if (score >= 8) return 'text-green-400';
    if (score >= 6) return 'text-yellow-400';
    if (score >= 4) return 'text-orange-400';
    return 'text-red-400';
  };

  const getScoreBg = (score: number) => {
    if (score >= 8) return 'from-green-500/20 to-green-600/10 border-green-500/30';
    if (score >= 6) return 'from-yellow-500/20 to-yellow-600/10 border-yellow-500/30';
    if (score >= 4) return 'from-orange-500/20 to-orange-600/10 border-orange-500/30';
    return 'from-red-500/20 to-red-600/10 border-red-500/30';
  };

  const getScoreLabel = (score: number) => {
    if (score >= 9) return 'EPIC';
    if (score >= 8) return 'EXCELLENT';
    if (score >= 6) return 'GOOD';
    if (score >= 4) return 'FAIR';
    return 'POOR';
  };

  return (
    <div className={`bg-gradient-to-br ${getScoreBg(data.score)} rounded-xl p-4 border`}>
      <div className="flex items-center justify-between mb-3">
        <div>
          <h3 className="text-white font-semibold text-sm">{mountain}</h3>
          <p className="text-gray-400 text-xs">Powder Score</p>
        </div>
        <div className="text-right">
          <div className={`text-4xl font-bold ${getScoreColor(data.score)}`}>
            {data.score}
          </div>
          <div className="text-gray-500 text-xs">/ {data.maxScore}</div>
        </div>
      </div>

      <div className="flex items-center gap-2 mb-3">
        <span className={`px-2 py-0.5 rounded text-xs font-medium ${getScoreColor(data.score)} bg-black/30`}>
          {getScoreLabel(data.score)}
        </span>
        <span className="text-gray-500 text-xs">{data.confidence}% confidence</span>
        {data.trend && (
          <span className="text-gray-500 text-xs">
            {data.trend === 'improving' ? '📈' : data.trend === 'declining' ? '📉' : '➡️'}
          </span>
        )}
      </div>

      <div className="space-y-1.5">
        {data.factors.map((factor, idx) => (
          <div key={idx} className="flex items-center justify-between text-xs">
            <span className="text-gray-400">{factor.name}</span>
            <span className={factor.value.startsWith('+') ? 'text-green-400' : factor.value.startsWith('-') ? 'text-red-400' : 'text-gray-300'}>
              {factor.value}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

'use client';

interface MountainData {
  name: string;
  powderScore: number;
  snowDepth: number;
  newSnow: number;
  temperature: number;
  wind: number;
}

interface ComparisonWidgetProps {
  mountains: MountainData[];
}

export function ComparisonWidget({ mountains }: ComparisonWidgetProps) {
  const getScoreColor = (score: number) => {
    if (score >= 8) return 'text-green-400';
    if (score >= 6) return 'text-yellow-400';
    if (score >= 4) return 'text-orange-400';
    return 'text-red-400';
  };

  const getWinner = () => {
    if (mountains.length < 2) return null;
    const [m1, m2] = mountains;
    if (m1.powderScore > m2.powderScore) return m1.name;
    if (m2.powderScore > m1.powderScore) return m2.name;
    return 'tie';
  };

  const winner = getWinner();

  const getBetterIndicator = (val1: number, val2: number, higherIsBetter: boolean = true) => {
    if (val1 === val2) return ['', ''];
    if (higherIsBetter) {
      return val1 > val2 ? ['text-green-400', 'text-gray-400'] : ['text-gray-400', 'text-green-400'];
    }
    return val1 < val2 ? ['text-green-400', 'text-gray-400'] : ['text-gray-400', 'text-green-400'];
  };

  if (mountains.length < 2) return null;

  const [m1, m2] = mountains;

  return (
    <div className="bg-gradient-to-br from-amber-500/20 to-orange-600/10 rounded-xl p-4 border border-amber-500/30">
      <div className="mb-4">
        <h3 className="text-white font-semibold text-sm">Mountain Comparison</h3>
        <p className="text-gray-400 text-xs">
          {m1.name} vs {m2.name}
        </p>
      </div>

      {/* Header Row */}
      <div className="grid grid-cols-3 gap-2 mb-3 pb-2 border-b border-white/10">
        <div className="text-gray-500 text-xs"></div>
        <div className="text-center">
          <span className={`font-semibold text-sm ${winner === m1.name ? 'text-green-400' : 'text-white'}`}>
            {m1.name}
          </span>
          {winner === m1.name && <span className="ml-1">🏆</span>}
        </div>
        <div className="text-center">
          <span className={`font-semibold text-sm ${winner === m2.name ? 'text-green-400' : 'text-white'}`}>
            {m2.name}
          </span>
          {winner === m2.name && <span className="ml-1">🏆</span>}
        </div>
      </div>

      {/* Powder Score */}
      <div className="grid grid-cols-3 gap-2 py-2">
        <div className="text-gray-400 text-xs">Powder Score</div>
        <div className={`text-center text-lg font-bold ${getScoreColor(m1.powderScore)}`}>
          {m1.powderScore}
        </div>
        <div className={`text-center text-lg font-bold ${getScoreColor(m2.powderScore)}`}>
          {m2.powderScore}
        </div>
      </div>

      {/* Snow Depth */}
      <div className="grid grid-cols-3 gap-2 py-2 border-t border-white/5">
        <div className="text-gray-400 text-xs">Snow Depth</div>
        <div className={`text-center text-sm font-medium ${getBetterIndicator(m1.snowDepth, m2.snowDepth)[0]}`}>
          {m1.snowDepth}"
        </div>
        <div className={`text-center text-sm font-medium ${getBetterIndicator(m1.snowDepth, m2.snowDepth)[1]}`}>
          {m2.snowDepth}"
        </div>
      </div>

      {/* New Snow */}
      <div className="grid grid-cols-3 gap-2 py-2 border-t border-white/5">
        <div className="text-gray-400 text-xs">24h Snow</div>
        <div className={`text-center text-sm font-medium ${getBetterIndicator(m1.newSnow, m2.newSnow)[0]}`}>
          {m1.newSnow}"
        </div>
        <div className={`text-center text-sm font-medium ${getBetterIndicator(m1.newSnow, m2.newSnow)[1]}`}>
          {m2.newSnow}"
        </div>
      </div>

      {/* Temperature */}
      <div className="grid grid-cols-3 gap-2 py-2 border-t border-white/5">
        <div className="text-gray-400 text-xs">Temperature</div>
        <div className={`text-center text-sm font-medium ${getBetterIndicator(m1.temperature, m2.temperature, false)[0]}`}>
          {m1.temperature}°F
        </div>
        <div className={`text-center text-sm font-medium ${getBetterIndicator(m1.temperature, m2.temperature, false)[1]}`}>
          {m2.temperature}°F
        </div>
      </div>

      {/* Wind */}
      <div className="grid grid-cols-3 gap-2 py-2 border-t border-white/5">
        <div className="text-gray-400 text-xs">Wind</div>
        <div className={`text-center text-sm font-medium ${getBetterIndicator(m1.wind, m2.wind, false)[0]}`}>
          {m1.wind} mph
        </div>
        <div className={`text-center text-sm font-medium ${getBetterIndicator(m1.wind, m2.wind, false)[1]}`}>
          {m2.wind} mph
        </div>
      </div>
    </div>
  );
}

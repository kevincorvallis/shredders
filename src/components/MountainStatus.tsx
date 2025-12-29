import { type MountainStatus as MountainStatusType } from '@/data/mountains';

interface MountainStatusProps {
  status?: MountainStatusType;
  variant?: 'compact' | 'full';
}

export function MountainStatus({ status, variant = 'compact' }: MountainStatusProps) {
  if (!status) return null;

  const statusColor = status.isOpen
    ? 'bg-green-500/20 text-green-400 border-green-500/30'
    : 'bg-red-500/20 text-red-400 border-red-500/30';

  const percentColor =
    (status.percentOpen ?? 0) >= 80
      ? 'text-green-400'
      : (status.percentOpen ?? 0) >= 50
        ? 'text-yellow-400'
        : 'text-orange-400';

  if (variant === 'compact') {
    return (
      <div className="flex items-center gap-2 text-sm">
        <div className={`px-2 py-1 rounded-md border ${statusColor} font-medium`}>
          {status.isOpen ? 'OPEN' : 'CLOSED'}
        </div>
        {status.isOpen && status.percentOpen !== undefined && (
          <span className={`font-bold ${percentColor}`}>
            {status.percentOpen}% Open
          </span>
        )}
      </div>
    );
  }

  return (
    <div className="bg-slate-800/50 rounded-xl p-4 space-y-3">
      <div className="flex items-center justify-between">
        <h3 className="text-sm font-semibold text-gray-400 uppercase tracking-wider">
          Mountain Status
        </h3>
        <div className={`px-3 py-1 rounded-lg border ${statusColor} font-bold text-sm`}>
          {status.isOpen ? 'OPEN' : 'CLOSED'}
        </div>
      </div>

      {status.isOpen && (
        <>
          {status.percentOpen !== undefined && (
            <div>
              <div className="flex items-center justify-between mb-2">
                <span className="text-sm text-gray-400">Terrain Open</span>
                <span className={`text-2xl font-bold ${percentColor}`}>
                  {status.percentOpen}%
                </span>
              </div>
              <div className="h-2 bg-slate-700 rounded-full overflow-hidden">
                <div
                  className={`h-full ${
                    status.percentOpen >= 80
                      ? 'bg-green-500'
                      : status.percentOpen >= 50
                        ? 'bg-yellow-500'
                        : 'bg-orange-500'
                  }`}
                  style={{ width: `${status.percentOpen}%` }}
                />
              </div>
            </div>
          )}

          <div className="grid grid-cols-2 gap-3 text-sm">
            {status.liftsOpen && (
              <div className="bg-slate-700/50 rounded-lg p-3">
                <div className="text-gray-400 text-xs mb-1">Lifts</div>
                <div className="text-white font-bold">{status.liftsOpen}</div>
              </div>
            )}
            {status.runsOpen && (
              <div className="bg-slate-700/50 rounded-lg p-3">
                <div className="text-gray-400 text-xs mb-1">Runs</div>
                <div className="text-white font-bold">{status.runsOpen}</div>
              </div>
            )}
          </div>
        </>
      )}

      {status.message && (
        <div className="text-sm text-gray-300 pt-2 border-t border-slate-700">
          {status.message}
        </div>
      )}

      {status.lastUpdated && (
        <div className="text-xs text-gray-500">
          Updated: {new Date(status.lastUpdated).toLocaleString()}
        </div>
      )}
    </div>
  );
}

export default function HistoryLoading() {
  return (
    <div className="min-h-screen bg-surface-primary">
      {/* Header Skeleton */}
      <header className="sticky top-0 z-10 bg-surface-primary/95 backdrop-blur-sm border-b border-border-secondary">
        <div className="max-w-4xl mx-auto px-4 py-4">
          <div className="flex items-center gap-3">
            <div className="w-5 h-5 bg-surface-tertiary rounded animate-pulse" />
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 rounded-full bg-surface-tertiary animate-pulse" />
              <div className="h-6 w-40 bg-surface-tertiary rounded animate-pulse" />
            </div>
          </div>
        </div>

        {/* Tab Navigation Skeleton */}
        <div className="max-w-4xl mx-auto px-4">
          <nav className="flex gap-1 border-t border-border-secondary pt-2 pb-2">
            <div className="h-10 w-28 bg-surface-tertiary rounded-lg animate-pulse" />
            <div className="h-10 w-24 bg-surface-tertiary rounded-lg animate-pulse" />
            <div className="h-10 w-24 bg-surface-secondary rounded-lg animate-pulse" />
            <div className="h-10 w-28 bg-surface-tertiary rounded-lg animate-pulse" />
          </nav>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-6 space-y-6">
        {/* Controls Skeleton */}
        <div className="flex items-center justify-between mb-4 animate-pulse">
          <div className="h-8 w-48 bg-surface-tertiary rounded" />
          <div className="flex gap-2">
            <div className="h-10 w-16 bg-surface-tertiary rounded-lg" />
            <div className="h-10 w-16 bg-surface-tertiary rounded-lg" />
            <div className="h-10 w-16 bg-surface-tertiary rounded-lg" />
            <div className="h-10 w-24 bg-surface-tertiary rounded-lg" />
          </div>
        </div>

        {/* Summary Cards Skeleton */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {[...Array(3)].map((_, i) => (
            <div
              key={i}
              className="bg-surface-secondary rounded-xl p-6 animate-pulse"
            >
              <div className="h-4 w-32 bg-surface-tertiary rounded mb-2" />
              <div className="h-8 w-24 bg-surface-tertiary rounded mb-1" />
              <div className="h-3 w-full bg-surface-tertiary rounded" />
            </div>
          ))}
        </div>

        {/* Charts Skeleton */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Snow Depth Chart */}
          <div className="bg-surface-secondary rounded-xl p-6 animate-pulse">
            <div className="h-6 w-32 bg-surface-tertiary rounded mb-4" />
            <div className="h-64 bg-surface-tertiary/50 rounded" />
          </div>

          {/* Snowfall Chart */}
          <div className="bg-surface-secondary rounded-xl p-6 animate-pulse">
            <div className="h-6 w-32 bg-surface-tertiary rounded mb-4" />
            <div className="h-64 bg-surface-tertiary/50 rounded" />
          </div>

          {/* Temperature Chart */}
          <div className="bg-surface-secondary rounded-xl p-6 animate-pulse col-span-full">
            <div className="h-6 w-40 bg-surface-tertiary rounded mb-4" />
            <div className="h-64 bg-surface-tertiary/50 rounded" />
          </div>
        </div>

        {/* Data Source Info Skeleton */}
        <div className="bg-surface-secondary rounded-xl p-4 animate-pulse">
          <div className="h-4 w-64 bg-surface-tertiary rounded" />
        </div>
      </main>
    </div>
  );
}

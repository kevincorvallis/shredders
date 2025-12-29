export default function MountainLoading() {
  return (
    <div className="min-h-screen bg-slate-900">
      {/* Header Skeleton */}
      <header className="sticky top-0 z-10 bg-slate-900/95 backdrop-blur-sm border-b border-slate-800">
        <div className="max-w-4xl mx-auto px-4 py-4">
          <div className="flex items-center gap-3">
            <div className="w-6 h-6 bg-slate-700 rounded animate-pulse" />
            <div className="h-10 w-48 bg-slate-700 rounded-lg animate-pulse" />
            <div className="ml-auto w-24 h-6 bg-slate-700 rounded animate-pulse" />
          </div>
        </div>

        {/* Tab Navigation Skeleton */}
        <div className="max-w-4xl mx-auto px-4">
          <nav className="flex gap-1 border-t border-slate-800 pt-2 pb-2">
            <div className="h-10 w-28 bg-slate-800 rounded-lg animate-pulse" />
            <div className="h-10 w-24 bg-slate-700 rounded-lg animate-pulse" />
            <div className="h-10 w-24 bg-slate-700 rounded-lg animate-pulse" />
            <div className="h-10 w-28 bg-slate-700 rounded-lg animate-pulse" />
          </nav>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 py-6 space-y-6">
        {/* Powder Score Skeleton */}
        <div className="bg-slate-800 rounded-xl p-6 animate-pulse">
          <div className="flex items-center justify-between mb-4">
            <div className="h-6 w-32 bg-slate-700 rounded" />
            <div className="h-12 w-24 bg-slate-700 rounded" />
          </div>
          <div className="h-4 w-full bg-slate-700 rounded mb-4" />
          <div className="h-12 w-full bg-slate-700 rounded-xl mb-4" />
          <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
            {[...Array(6)].map((_, i) => (
              <div key={i} className="bg-slate-700/50 rounded-lg p-3 h-16" />
            ))}
          </div>
        </div>

        {/* Current Conditions Skeleton */}
        <div className="bg-slate-800 rounded-xl p-6 animate-pulse">
          <div className="h-6 w-40 bg-slate-700 rounded mb-4" />
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-4">
            {[...Array(4)].map((_, i) => (
              <div key={i} className="bg-slate-700/50 rounded-lg p-4 h-24" />
            ))}
          </div>
          <div className="bg-slate-700/30 rounded-lg p-4 h-32" />
        </div>

        {/* Road Conditions Skeleton */}
        <div className="bg-slate-800 rounded-xl p-6 animate-pulse">
          <div className="h-6 w-48 bg-slate-700 rounded mb-2" />
          <div className="h-3 w-full bg-slate-700 rounded mb-4" />
          <div className="space-y-3">
            {[...Array(2)].map((_, i) => (
              <div key={i} className="bg-slate-700/50 rounded-lg p-4 h-32" />
            ))}
          </div>
        </div>

        {/* Trip & Traffic Skeleton */}
        <div className="bg-slate-800 rounded-xl p-6 animate-pulse">
          <div className="flex items-start justify-between gap-4 mb-3">
            <div>
              <div className="h-6 w-32 bg-slate-700 rounded mb-2" />
              <div className="h-3 w-64 bg-slate-700 rounded" />
            </div>
            <div className="flex gap-2">
              <div className="h-6 w-24 bg-slate-700 rounded" />
              <div className="h-6 w-24 bg-slate-700 rounded" />
            </div>
          </div>
          <div className="h-4 w-full bg-slate-700 rounded mb-3" />
          <div className="bg-slate-700/50 rounded-lg p-4 mb-3 h-20" />
          <div className="space-y-2">
            {[...Array(3)].map((_, i) => (
              <div key={i} className="h-3 w-full bg-slate-700 rounded" />
            ))}
          </div>
        </div>

        {/* Powder Day Planner Skeleton */}
        <div className="bg-slate-800 rounded-xl p-6 animate-pulse">
          <div className="h-6 w-40 bg-slate-700 rounded mb-2" />
          <div className="h-3 w-full bg-slate-700 rounded mb-4" />
          <div className="grid md:grid-cols-3 gap-3">
            {[...Array(3)].map((_, i) => (
              <div key={i} className="bg-slate-700/50 rounded-lg p-4 h-40" />
            ))}
          </div>
        </div>

        {/* 7-Day Forecast Skeleton */}
        <div className="bg-slate-800 rounded-xl p-6 animate-pulse">
          <div className="flex items-center justify-between mb-4">
            <div className="h-6 w-32 bg-slate-700 rounded" />
            <div className="flex gap-2">
              <div className="h-8 w-20 bg-slate-700 rounded-lg" />
              <div className="h-8 w-28 bg-slate-700 rounded-lg" />
            </div>
          </div>
          <div className="grid grid-cols-7 gap-2">
            {[...Array(7)].map((_, i) => (
              <div key={i} className="bg-slate-700/50 rounded-lg p-3 h-32" />
            ))}
          </div>
        </div>

        {/* Webcams Skeleton */}
        <div className="bg-slate-800 rounded-xl p-6 animate-pulse">
          <div className="h-6 w-24 bg-slate-700 rounded mb-4" />
          <div className="grid md:grid-cols-2 gap-4">
            {[...Array(2)].map((_, i) => (
              <div key={i} className="bg-slate-700/50 rounded-lg overflow-hidden">
                <div className="aspect-video bg-slate-700" />
                <div className="p-3">
                  <div className="h-4 w-32 bg-slate-600 rounded mb-2" />
                  <div className="h-3 w-24 bg-slate-600 rounded" />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Mountain Info Skeleton */}
        <div className="bg-slate-800 rounded-xl p-6 animate-pulse">
          <div className="h-6 w-32 bg-slate-700 rounded mb-4" />
          <div className="grid md:grid-cols-2 gap-4">
            {[...Array(2)].map((_, i) => (
              <div key={i} className="space-y-2">
                {[...Array(3)].map((_, j) => (
                  <div key={j} className="flex justify-between">
                    <div className="h-4 w-32 bg-slate-700 rounded" />
                    <div className="h-4 w-20 bg-slate-700 rounded" />
                  </div>
                ))}
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  );
}

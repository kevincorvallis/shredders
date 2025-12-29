export default function PatrolLoading() {
  return (
    <div className="min-h-screen bg-slate-900">
      {/* Header Skeleton */}
      <header className="sticky top-0 z-10 bg-slate-900/95 backdrop-blur-sm border-b border-slate-800">
        <div className="max-w-4xl mx-auto px-4 py-4">
          <div className="flex items-center gap-3">
            <div className="w-5 h-5 bg-slate-700 rounded animate-pulse" />
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 rounded-full bg-slate-700 animate-pulse" />
              <div className="h-6 w-40 bg-slate-700 rounded animate-pulse" />
            </div>
            <div className="ml-auto h-6 w-24 bg-slate-700 rounded animate-pulse" />
          </div>
        </div>

        {/* Tab Navigation Skeleton */}
        <div className="max-w-4xl mx-auto px-4">
          <nav className="flex gap-1 border-t border-slate-800 pt-2 pb-2">
            <div className="h-10 w-28 bg-slate-700 rounded-lg animate-pulse" />
            <div className="h-10 w-24 bg-slate-800 rounded-lg animate-pulse" />
            <div className="h-10 w-24 bg-slate-700 rounded-lg animate-pulse" />
            <div className="h-10 w-28 bg-slate-700 rounded-lg animate-pulse" />
          </nav>
        </div>
      </header>

      <main className="max-w-6xl mx-auto px-4 py-6 space-y-6">
        {/* Refresh Button Skeleton */}
        <div className="flex justify-end animate-pulse">
          <div className="h-10 w-28 bg-slate-700 rounded-lg" />
        </div>

        {/* Safety Alert Banner Skeleton */}
        <div className="bg-gradient-to-r from-orange-500/20 to-red-500/20 border-2 border-orange-500 rounded-xl p-6 animate-pulse">
          <div className="flex items-start gap-4">
            <div className="w-8 h-8 bg-orange-500/30 rounded" />
            <div className="flex-1 space-y-2">
              <div className="h-6 w-48 bg-orange-500/30 rounded" />
              <div className="h-4 w-full bg-orange-500/30 rounded" />
              <div className="h-4 w-3/4 bg-orange-500/30 rounded" />
            </div>
          </div>
        </div>

        {/* Metrics Grid Skeleton */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[...Array(8)].map((_, i) => (
            <div
              key={i}
              className="bg-slate-800 rounded-xl p-4 animate-pulse"
            >
              <div className="h-4 w-24 bg-slate-700 rounded mb-2" />
              <div className="h-8 w-16 bg-slate-700 rounded mb-1" />
              <div className="h-3 w-20 bg-slate-700 rounded" />
            </div>
          ))}
        </div>

        {/* Main Content Grid Skeleton */}
        <div className="grid lg:grid-cols-2 gap-6">
          {/* Wind Rose Card */}
          <div className="bg-slate-800 rounded-xl p-6 animate-pulse">
            <div className="h-6 w-32 bg-slate-700 rounded mb-4" />
            <div className="aspect-square bg-slate-700/50 rounded" />
            <div className="mt-4 h-4 w-full bg-slate-700 rounded" />
          </div>

          {/* Snow Stability Card */}
          <div className="bg-slate-800 rounded-xl p-6 animate-pulse">
            <div className="h-6 w-40 bg-slate-700 rounded mb-4" />
            <div className="space-y-3">
              {[...Array(4)].map((_, i) => (
                <div key={i} className="flex items-center gap-3">
                  <div className="w-6 h-6 bg-slate-700 rounded" />
                  <div className="flex-1">
                    <div className="h-4 w-32 bg-slate-700 rounded mb-1" />
                    <div className="h-3 w-full bg-slate-700 rounded" />
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Temperature Profile Card */}
          <div className="bg-slate-800 rounded-xl p-6 animate-pulse">
            <div className="h-6 w-48 bg-slate-700 rounded mb-4" />
            <div className="h-48 bg-slate-700/50 rounded" />
          </div>

          {/* Hazard Matrix Card */}
          <div className="bg-slate-800 rounded-xl p-6 animate-pulse">
            <div className="h-6 w-36 bg-slate-700 rounded mb-4" />
            <div className="grid grid-cols-3 gap-2">
              {[...Array(9)].map((_, i) => (
                <div key={i} className="h-16 bg-slate-700/50 rounded" />
              ))}
            </div>
          </div>
        </div>

        {/* Data Quality Note Skeleton */}
        <div className="bg-slate-800/50 rounded-xl p-4 animate-pulse">
          <div className="h-4 w-full max-w-2xl bg-slate-700 rounded" />
        </div>
      </main>
    </div>
  );
}

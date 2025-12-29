export default function WebcamsLoading() {
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
          </div>
        </div>

        {/* Tab Navigation Skeleton */}
        <div className="max-w-4xl mx-auto px-4">
          <nav className="flex gap-1 border-t border-slate-800 pt-2 pb-2">
            <div className="h-10 w-28 bg-slate-700 rounded-lg animate-pulse" />
            <div className="h-10 w-24 bg-slate-700 rounded-lg animate-pulse" />
            <div className="h-10 w-24 bg-slate-700 rounded-lg animate-pulse" />
            <div className="h-10 w-28 bg-slate-800 rounded-lg animate-pulse" />
          </nav>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-6 space-y-8">
        {/* Controls Skeleton */}
        <div className="flex items-center justify-between animate-pulse">
          <div className="h-8 w-48 bg-slate-700 rounded" />
          <div className="h-10 w-24 bg-slate-700 rounded-lg" />
        </div>

        {/* Mountain Webcams Section */}
        <div>
          <div className="h-7 w-48 bg-slate-700 rounded mb-4 animate-pulse" />
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[...Array(6)].map((_, i) => (
              <div
                key={i}
                className="bg-slate-800 rounded-xl overflow-hidden animate-pulse"
              >
                <div className="aspect-video bg-slate-700" />
                <div className="p-4">
                  <div className="h-5 w-32 bg-slate-700 rounded mb-2" />
                  <div className="h-4 w-24 bg-slate-700 rounded" />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Road Webcams Section */}
        <div>
          <div className="h-7 w-56 bg-slate-700 rounded mb-2 animate-pulse" />
          <div className="h-4 w-96 bg-slate-700 rounded mb-4 animate-pulse" />
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[...Array(6)].map((_, i) => (
              <div
                key={i}
                className="bg-slate-800 rounded-xl overflow-hidden animate-pulse"
              >
                <div className="aspect-video bg-slate-700" />
                <div className="p-4">
                  <div className="h-5 w-40 bg-slate-700 rounded mb-2" />
                  <div className="h-4 w-32 bg-slate-700 rounded" />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Note Skeleton */}
        <div className="bg-slate-800/50 rounded-xl p-4 animate-pulse">
          <div className="h-4 w-full max-w-2xl bg-slate-700 rounded" />
        </div>
      </main>
    </div>
  );
}

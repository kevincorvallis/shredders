import { Skeleton } from '@/components/ui/skeleton';
import { Mountain } from 'lucide-react';

export default function Loading() {
  return (
    <div className="min-h-screen bg-background">
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="flex items-center gap-3 mb-8">
          <Mountain className="w-8 h-8 text-sky-400 animate-pulse" />
          <Skeleton className="h-10 w-48" />
        </div>

        <Skeleton className="h-64 w-full mb-6 rounded-2xl" />

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          {[...Array(4)].map((_, i) => (
            <Skeleton key={i} className="h-24 rounded-xl" />
          ))}
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {[...Array(3)].map((_, i) => (
            <Skeleton key={i} className="h-80 rounded-xl" />
          ))}
        </div>
      </div>
    </div>
  );
}

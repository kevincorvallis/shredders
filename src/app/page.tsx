import Link from 'next/link';
import { MountainHeader } from '@/components/MountainHeader';
import { ConditionsCard } from '@/components/ConditionsCard';
import { ForecastTimeline } from '@/components/ForecastTimeline';
import { PowderScore } from '@/components/PowderScore';
import { AISummary } from '@/components/AISummary';
import {
  mtBaker,
  mockCurrentConditions,
  mockForecast,
  mockPowderPrediction,
  mockAISummary,
} from '@/data/mock';

export default function Home() {
  return (
    <div className="min-h-screen bg-gray-100">
      <div className="max-w-6xl mx-auto px-4 py-8">
        {/* Header */}
        <header className="mb-8">
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-center gap-3 mb-2">
                <span className="text-3xl">🏔️</span>
                <h1 className="text-2xl font-bold text-gray-900">Shredders</h1>
              </div>
              <p className="text-gray-500">AI-powered mountain conditions for powder chasers</p>
            </div>
            <Link
              href="/chat"
              className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-violet-500 to-purple-600 text-white rounded-xl hover:from-violet-600 hover:to-purple-700 transition-all shadow-lg shadow-purple-500/25"
            >
              <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
              </svg>
              <span className="font-medium">Ask AI</span>
            </Link>
          </div>
        </header>

        {/* Main Content */}
        <div className="space-y-6">
          {/* Mountain Header */}
          <MountainHeader mountain={mtBaker} conditions={mockCurrentConditions} />

          {/* AI Summary - Full Width */}
          <AISummary summary={mockAISummary} />

          {/* Two Column Layout */}
          <div className="grid md:grid-cols-3 gap-6">
            {/* Left Column - Conditions */}
            <div className="md:col-span-1 space-y-6">
              <PowderScore prediction={mockPowderPrediction} />
              <ConditionsCard conditions={mockCurrentConditions} />
            </div>

            {/* Right Column - Forecast */}
            <div className="md:col-span-2">
              <ForecastTimeline forecast={mockForecast} />
            </div>
          </div>
        </div>

        {/* Footer */}
        <footer className="mt-12 text-center text-sm text-gray-400">
          <p>Data sources: NOAA Weather API, SNOTEL</p>
          <p className="mt-1">Built with Next.js and Claude AI</p>
        </footer>
      </div>
    </div>
  );
}

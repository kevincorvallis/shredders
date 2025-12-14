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
          <div className="flex items-center gap-3 mb-2">
            <span className="text-3xl">🏔️</span>
            <h1 className="text-2xl font-bold text-gray-900">Shredders</h1>
          </div>
          <p className="text-gray-500">AI-powered mountain conditions for powder chasers</p>
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

'use client';

import { CurrentConditions } from '@/types/mountain';

interface ConditionsCardProps {
  conditions: CurrentConditions;
}

export function ConditionsCard({ conditions }: ConditionsCardProps) {
  return (
    <div className="bg-white rounded-xl shadow-lg p-6">
      <h2 className="text-lg font-semibold text-text-primary mb-4">Snow Conditions</h2>

      <div className="space-y-4">
        <div className="flex items-center justify-between py-3 border-b border-border-secondary">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
              <span className="text-xl">📏</span>
            </div>
            <div>
              <p className="text-sm text-text-quaternary">Snow Depth</p>
              <p className="font-semibold text-text-primary">{conditions.snowDepth}&quot; base</p>
            </div>
          </div>
        </div>

        <div className="flex items-center justify-between py-3 border-b border-border-secondary">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
              <span className="text-xl">❄️</span>
            </div>
            <div>
              <p className="text-sm text-text-quaternary">24 Hour Snowfall</p>
              <p className="font-semibold text-text-primary">{conditions.snowfall24h}&quot; new</p>
            </div>
          </div>
          <span className={`px-2 py-1 rounded text-xs font-medium ${
            conditions.snowfall24h >= 6
              ? 'bg-green-100 text-green-800'
              : conditions.snowfall24h > 0
                ? 'bg-blue-100 text-blue-800'
                : 'bg-surface-secondary text-text-quaternary'
          }`}>
            {conditions.snowfall24h >= 6 ? 'Powder!' : conditions.snowfall24h > 0 ? 'Fresh' : 'Packed'}
          </span>
        </div>

        <div className="flex items-center justify-between py-3 border-b border-border-secondary">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
              <span className="text-xl">🌨️</span>
            </div>
            <div>
              <p className="text-sm text-text-quaternary">48 Hour Snowfall</p>
              <p className="font-semibold text-text-primary">{conditions.snowfall48h}&quot;</p>
            </div>
          </div>
        </div>

        <div className="flex items-center justify-between py-3 border-b border-border-secondary">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
              <span className="text-xl">📅</span>
            </div>
            <div>
              <p className="text-sm text-text-quaternary">7 Day Snowfall</p>
              <p className="font-semibold text-text-primary">{conditions.snowfall7d}&quot;</p>
            </div>
          </div>
        </div>

        <div className="flex items-center justify-between py-3">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
              <span className="text-xl">💧</span>
            </div>
            <div>
              <p className="text-sm text-text-quaternary">Snow Water Equivalent</p>
              <p className="font-semibold text-text-primary">{conditions.snowWaterEquivalent}&quot;</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

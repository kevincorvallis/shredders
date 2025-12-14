'use client';

import { CurrentConditions } from '@/types/mountain';

interface ConditionsCardProps {
  conditions: CurrentConditions;
}

export function ConditionsCard({ conditions }: ConditionsCardProps) {
  return (
    <div className="bg-white rounded-xl shadow-lg p-6">
      <h2 className="text-lg font-semibold text-gray-900 mb-4">Snow Conditions</h2>

      <div className="space-y-4">
        <div className="flex items-center justify-between py-3 border-b border-gray-100">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
              <span className="text-xl">📏</span>
            </div>
            <div>
              <p className="text-sm text-gray-500">Snow Depth</p>
              <p className="font-semibold text-gray-900">{conditions.snowDepth}&quot; base</p>
            </div>
          </div>
        </div>

        <div className="flex items-center justify-between py-3 border-b border-gray-100">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
              <span className="text-xl">❄️</span>
            </div>
            <div>
              <p className="text-sm text-gray-500">24 Hour Snowfall</p>
              <p className="font-semibold text-gray-900">{conditions.snowfall24h}&quot; new</p>
            </div>
          </div>
          <span className={`px-2 py-1 rounded text-xs font-medium ${
            conditions.snowfall24h >= 6
              ? 'bg-green-100 text-green-800'
              : conditions.snowfall24h > 0
                ? 'bg-blue-100 text-blue-800'
                : 'bg-gray-100 text-gray-600'
          }`}>
            {conditions.snowfall24h >= 6 ? 'Powder!' : conditions.snowfall24h > 0 ? 'Fresh' : 'Packed'}
          </span>
        </div>

        <div className="flex items-center justify-between py-3 border-b border-gray-100">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
              <span className="text-xl">🌨️</span>
            </div>
            <div>
              <p className="text-sm text-gray-500">48 Hour Snowfall</p>
              <p className="font-semibold text-gray-900">{conditions.snowfall48h}&quot;</p>
            </div>
          </div>
        </div>

        <div className="flex items-center justify-between py-3 border-b border-gray-100">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
              <span className="text-xl">📅</span>
            </div>
            <div>
              <p className="text-sm text-gray-500">7 Day Snowfall</p>
              <p className="font-semibold text-gray-900">{conditions.snowfall7d}&quot;</p>
            </div>
          </div>
        </div>

        <div className="flex items-center justify-between py-3">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-blue-100 rounded-full flex items-center justify-center">
              <span className="text-xl">💧</span>
            </div>
            <div>
              <p className="text-sm text-gray-500">Snow Water Equivalent</p>
              <p className="font-semibold text-gray-900">{conditions.snowWaterEquivalent}&quot;</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

'use client';

import { UseFormReturn } from 'react-hook-form';
import type { MountainConfig } from '@shredders/shared';
import type { CreateEventFormData } from '@/lib/schemas/event';
import { useConditions } from '@/hooks/useConditions';
import { ForecastPreview, BestPowderDayBanner } from './ForecastPreview';

interface EventFormStep1Props {
  form: UseFormReturn<CreateEventFormData>;
  mountains: MountainConfig[];
}

export function EventFormStep1({ form, mountains }: EventFormStep1Props) {
  const { register, watch, setValue, formState: { errors } } = form;
  const mountainId = watch('mountainId');
  const eventDate = watch('eventDate');

  const today = new Date().toISOString().split('T')[0];

  const { forecast, bestPowderDay, isLoading: forecastLoading } = useConditions(
    mountainId || '',
    eventDate
  );

  const selectedMountain = mountains.find((m) => m.id === mountainId);

  return (
    <div className="space-y-5">
      <div>
        <h2 className="text-lg font-semibold text-text-primary mb-1">Where & When</h2>
        <p className="text-sm text-text-tertiary">Pick your mountain and date</p>
      </div>

      {/* Mountain Selection */}
      <div>
        <label className="block text-sm font-medium text-text-secondary mb-2">Mountain *</label>
        <select
          {...register('mountainId')}
          className="w-full bg-surface-secondary border border-border-primary rounded-xl px-4 py-3 text-text-primary focus:outline-none focus:border-accent"
        >
          <option value="">Select a mountain</option>
          {mountains.map((m) => (
            <option key={m.id} value={m.id}>
              {m.name}
            </option>
          ))}
        </select>
        {errors.mountainId && (
          <p className="text-red-400 text-sm mt-1">{errors.mountainId.message}</p>
        )}
      </div>

      {/* Date */}
      <div>
        <label className="block text-sm font-medium text-text-secondary mb-2">Date *</label>
        <input
          type="date"
          {...register('eventDate')}
          min={today}
          className="w-full bg-surface-secondary border border-border-primary rounded-xl px-4 py-3 text-text-primary focus:outline-none focus:border-accent"
        />
        {errors.eventDate && (
          <p className="text-red-400 text-sm mt-1">{errors.eventDate.message}</p>
        )}
      </div>

      {/* Best Powder Day suggestion */}
      {mountainId && bestPowderDay && bestPowderDay.snowfall >= 3 && (
        <BestPowderDayBanner
          day={bestPowderDay}
          onApply={() => {
            const dateStr =
              typeof bestPowderDay.date === 'string'
                ? bestPowderDay.date
                : new Date(bestPowderDay.date).toISOString().split('T')[0];
            setValue('eventDate', dateStr, { shouldValidate: true });
          }}
        />
      )}

      {/* Forecast loading */}
      {mountainId && eventDate && forecastLoading && (
        <div className="flex items-center gap-2 text-sm text-text-tertiary">
          <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
          </svg>
          Loading forecast...
        </div>
      )}

      {/* Forecast Preview */}
      {mountainId && eventDate && forecast && (
        <div>
          <label className="block text-sm font-medium text-text-secondary mb-2">
            Forecast for {selectedMountain?.name || 'selected mountain'}
          </label>
          <ForecastPreview forecast={forecast} />
        </div>
      )}

      {/* No forecast available (date beyond 7-day window) */}
      {mountainId && eventDate && !forecastLoading && !forecast && (
        <p className="text-sm text-text-quaternary">
          No forecast available for this date (forecasts cover the next 7 days)
        </p>
      )}
    </div>
  );
}

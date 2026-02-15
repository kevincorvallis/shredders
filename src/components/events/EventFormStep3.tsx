'use client';

import { UseFormReturn } from 'react-hook-form';
import type { CreateEventFormData } from '@/lib/schemas/event';

interface EventFormStep3Props {
  form: UseFormReturn<CreateEventFormData>;
}

export function EventFormStep3({ form }: EventFormStep3Props) {
  const { register, watch, formState: { errors } } = form;
  const carpoolAvailable = watch('carpoolAvailable');

  return (
    <div className="space-y-5">
      <div>
        <h2 className="text-lg font-semibold text-text-primary mb-1">Logistics</h2>
        <p className="text-sm text-text-tertiary">Set meeting details and carpool options</p>
      </div>

      {/* Departure Time */}
      <div>
        <label className="block text-sm font-medium text-text-secondary mb-2">Departure Time</label>
        <input
          type="time"
          {...register('departureTime')}
          className="w-full bg-surface-secondary border border-border-primary rounded-xl px-4 py-3 text-text-primary focus:outline-none focus:border-accent"
        />
      </div>

      {/* Meeting Point */}
      <div>
        <label className="block text-sm font-medium text-text-secondary mb-2">Meeting Point</label>
        <input
          type="text"
          {...register('departureLocation')}
          placeholder="e.g., Northgate Park & Ride"
          className="w-full bg-surface-secondary border border-border-primary rounded-xl px-4 py-3 text-text-primary placeholder-text-tertiary focus:outline-none focus:border-accent"
          maxLength={255}
        />
      </div>

      {/* Carpool */}
      <div className="space-y-3">
        <label className="flex items-center gap-3 cursor-pointer">
          <input
            type="checkbox"
            {...register('carpoolAvailable')}
            className="w-5 h-5 rounded bg-surface-secondary border-border-primary text-accent focus:ring-accent"
          />
          <span className="text-text-secondary">I can give rides</span>
        </label>

        {carpoolAvailable && (
          <div>
            <label className="block text-sm font-medium text-text-secondary mb-2">Available Seats</label>
            <input
              type="number"
              {...register('carpoolSeats', { valueAsNumber: true })}
              min={0}
              max={8}
              className="w-24 bg-surface-secondary border border-border-primary rounded-xl px-4 py-3 text-text-primary focus:outline-none focus:border-accent"
            />
          </div>
        )}
      </div>
    </div>
  );
}

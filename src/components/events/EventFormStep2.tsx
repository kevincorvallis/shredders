'use client';

import { useState } from 'react';
import { UseFormReturn } from 'react-hook-form';
import type { CreateEventFormData } from '@/lib/schemas/event';
import { skillLevelLabels } from '@/lib/schemas/event';

interface EventFormStep2Props {
  form: UseFormReturn<CreateEventFormData>;
}

export function EventFormStep2({ form }: EventFormStep2Props) {
  const { register, watch, setValue, formState: { errors } } = form;
  const notes = watch('notes') || '';
  const title = watch('title') || '';
  const maxAttendees = watch('maxAttendees');
  const [limitEnabled, setLimitEnabled] = useState(maxAttendees != null && maxAttendees > 0);

  const groupSizeHint = (n: number | null | undefined) => {
    if (!n) return '';
    if (n <= 6) return 'Small group';
    if (n <= 15) return 'Medium group';
    return 'Large group';
  };

  return (
    <div className="space-y-5">
      <div>
        <h2 className="text-lg font-semibold text-text-primary mb-1">Event Details</h2>
        <p className="text-sm text-text-tertiary">Name your event and set preferences</p>
      </div>

      {/* Title */}
      <div>
        <label className="block text-sm font-medium text-text-secondary mb-2">Event Title *</label>
        <input
          type="text"
          {...register('title')}
          placeholder="e.g., Powder Day at Stevens!"
          className="w-full bg-surface-secondary border border-border-primary rounded-xl px-4 py-3 text-text-primary placeholder-text-tertiary focus:outline-none focus:border-accent"
          maxLength={100}
        />
        <div className="flex justify-between mt-1">
          {errors.title ? (
            <p className="text-red-400 text-sm">{errors.title.message}</p>
          ) : (
            <span />
          )}
          <p className="text-xs text-text-quaternary">{title.length}/100</p>
        </div>
      </div>

      {/* Skill Level */}
      <div>
        <label className="block text-sm font-medium text-text-secondary mb-2">Skill Level</label>
        <select
          {...register('skillLevel')}
          className="w-full bg-surface-secondary border border-border-primary rounded-xl px-4 py-3 text-text-primary focus:outline-none focus:border-accent"
        >
          {Object.entries(skillLevelLabels).map(([value, label]) => (
            <option key={value} value={value}>
              {label}
            </option>
          ))}
        </select>
      </div>

      {/* Max Attendees */}
      <div className="space-y-3">
        <label className="flex items-center gap-3 cursor-pointer">
          <input
            type="checkbox"
            checked={limitEnabled}
            onChange={(e) => {
              setLimitEnabled(e.target.checked);
              if (!e.target.checked) {
                setValue('maxAttendees', null);
              } else {
                setValue('maxAttendees', 10);
              }
            }}
            className="w-5 h-5 rounded bg-surface-secondary border-border-primary text-accent focus:ring-accent"
          />
          <span className="text-text-secondary">Limit group size</span>
        </label>

        {limitEnabled && (
          <div>
            <div className="flex items-center gap-3">
              <input
                type="number"
                value={maxAttendees ?? 10}
                onChange={(e) => {
                  const val = Math.min(1000, Math.max(2, parseInt(e.target.value) || 2));
                  setValue('maxAttendees', val);
                }}
                min={2}
                max={1000}
                className="w-24 bg-surface-secondary border border-border-primary rounded-xl px-4 py-3 text-text-primary focus:outline-none focus:border-accent"
              />
              <span className="text-sm text-text-tertiary">max attendees</span>
              {maxAttendees && (
                <span className="text-xs text-accent">{groupSizeHint(maxAttendees)}</span>
              )}
            </div>
            <p className="text-xs text-text-quaternary mt-1">
              Extra RSVPs will be added to a waitlist automatically
            </p>
          </div>
        )}
      </div>

      {/* Notes */}
      <div>
        <label className="block text-sm font-medium text-text-secondary mb-2">Additional Notes</label>
        <textarea
          {...register('notes')}
          placeholder="Any other details for your group..."
          rows={3}
          className="w-full bg-surface-secondary border border-border-primary rounded-xl px-4 py-3 text-text-primary placeholder-text-tertiary focus:outline-none focus:border-accent resize-none"
          maxLength={2000}
        />
        <p className="text-xs text-text-quaternary mt-1 text-right">{notes.length}/2000</p>
      </div>
    </div>
  );
}

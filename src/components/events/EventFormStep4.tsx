'use client';

import { UseFormReturn } from 'react-hook-form';
import type { MountainConfig } from '@shredders/shared';
import type { CreateEventFormData } from '@/lib/schemas/event';
import { skillLevelLabels } from '@/lib/schemas/event';
import { useConditions } from '@/hooks/useConditions';
import { ForecastPreview } from './ForecastPreview';

interface EventFormStep4Props {
  form: UseFormReturn<CreateEventFormData>;
  mountains: MountainConfig[];
  onEditStep: (step: number) => void;
}

function ReviewSection({
  title,
  stepIndex,
  onEdit,
  children,
}: {
  title: string;
  stepIndex: number;
  onEdit: (step: number) => void;
  children: React.ReactNode;
}) {
  return (
    <div className="bg-surface-secondary/50 border border-border-primary rounded-xl p-4">
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-sm font-medium text-text-secondary">{title}</h3>
        <button
          type="button"
          onClick={() => onEdit(stepIndex)}
          className="text-xs text-accent hover:text-accent transition-colors"
        >
          Edit
        </button>
      </div>
      {children}
    </div>
  );
}

function ReviewRow({ label, value }: { label: string; value: string | null | undefined }) {
  if (!value) return null;
  return (
    <div className="flex justify-between py-1">
      <span className="text-sm text-text-tertiary">{label}</span>
      <span className="text-sm text-text-primary">{value}</span>
    </div>
  );
}

export function EventFormStep4({ form, mountains, onEditStep }: EventFormStep4Props) {
  const values = form.getValues();
  const mountain = mountains.find((m) => m.id === values.mountainId);
  const { forecast } = useConditions(values.mountainId, values.eventDate);

  const formattedDate = values.eventDate
    ? new Date(values.eventDate + 'T12:00:00').toLocaleDateString('en-US', {
        weekday: 'long',
        month: 'long',
        day: 'numeric',
        year: 'numeric',
      })
    : '';

  const formattedTime = values.departureTime
    ? new Date(`2000-01-01T${values.departureTime}`).toLocaleTimeString('en-US', {
        hour: 'numeric',
        minute: '2-digit',
      })
    : null;

  return (
    <div className="space-y-5">
      <div>
        <h2 className="text-lg font-semibold text-text-primary mb-1">Review & Create</h2>
        <p className="text-sm text-text-tertiary">Make sure everything looks good</p>
      </div>

      {/* Where & When */}
      <ReviewSection title="Where & When" stepIndex={0} onEdit={onEditStep}>
        <ReviewRow label="Mountain" value={mountain?.name} />
        <ReviewRow label="Date" value={formattedDate} />
        {forecast && (
          <div className="mt-2">
            <ForecastPreview forecast={forecast} compact />
          </div>
        )}
      </ReviewSection>

      {/* Details */}
      <ReviewSection title="Details" stepIndex={1} onEdit={onEditStep}>
        <ReviewRow label="Title" value={values.title} />
        <ReviewRow
          label="Skill Level"
          value={skillLevelLabels[values.skillLevel || ''] || 'All levels welcome'}
        />
        {values.maxAttendees && (
          <ReviewRow label="Max Attendees" value={String(values.maxAttendees)} />
        )}
        {values.notes && (
          <div className="mt-2">
            <p className="text-xs text-text-tertiary mb-1">Notes</p>
            <p className="text-sm text-text-secondary whitespace-pre-wrap">{values.notes}</p>
          </div>
        )}
      </ReviewSection>

      {/* Logistics */}
      <ReviewSection title="Logistics" stepIndex={2} onEdit={onEditStep}>
        <ReviewRow label="Departure" value={formattedTime} />
        <ReviewRow label="Meeting Point" value={values.departureLocation} />
        <ReviewRow
          label="Carpool"
          value={
            values.carpoolAvailable
              ? `Yes - ${values.carpoolSeats || 0} seats`
              : null
          }
        />
        {!formattedTime && !values.departureLocation && !values.carpoolAvailable && (
          <p className="text-sm text-text-quaternary italic">No logistics details set</p>
        )}
      </ReviewSection>
    </div>
  );
}

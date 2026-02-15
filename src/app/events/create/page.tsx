'use client';

import { useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useForm } from 'react-hook-form';
import { getAllMountains } from '@shredders/shared';
import { createEventSchema, stepSchemas, type CreateEventFormData } from '@/lib/schemas/event';
import type { CreateEventRequest, CreateEventResponse } from '@/types/event';
import { StepIndicator } from '@/components/events/StepIndicator';
import { EventFormStep1 } from '@/components/events/EventFormStep1';
import { EventFormStep2 } from '@/components/events/EventFormStep2';
import { EventFormStep3 } from '@/components/events/EventFormStep3';
import { EventFormStep4 } from '@/components/events/EventFormStep4';
import { DraftBanner } from '@/components/events/DraftBanner';
import { QuickPresets } from '@/components/events/QuickPresets';
import { useFormDraft } from '@/hooks/useFormDraft';
import { PostCreateModal } from '@/components/events/PostCreateModal';

const TOTAL_STEPS = 4;

export default function CreateEventPage() {
  const router = useRouter();
  const mountains = getAllMountains();
  const [currentStep, setCurrentStep] = useState(0);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [completedSteps, setCompletedSteps] = useState<Set<number>>(new Set());
  const [showDraft, setShowDraft] = useState(true);
  const [createdEvent, setCreatedEvent] = useState<CreateEventResponse | null>(null);

  const form = useForm<CreateEventFormData>({
    defaultValues: {
      mountainId: '',
      eventDate: '',
      title: '',
      skillLevel: '',
      notes: '',
      maxAttendees: null,
      departureTime: '',
      departureLocation: '',
      carpoolAvailable: false,
      carpoolSeats: 0,
    },
    mode: 'onTouched',
  });

  const { hasDraft, getDraft, restoreDraft, discardDraft, clearDraft } = useFormDraft(form);
  const draft = hasDraft && showDraft ? getDraft() : null;

  const validateCurrentStep = useCallback(async (): Promise<boolean> => {
    if (currentStep >= 3) return true; // Review step - no validation needed

    const schema = stepSchemas[currentStep];
    const values = form.getValues();

    // Pick only the fields for this step
    const stepFields = Object.keys(schema.shape) as (keyof CreateEventFormData)[];
    const stepValues: Record<string, unknown> = {};
    for (const field of stepFields) {
      stepValues[field] = values[field];
    }

    const result = schema.safeParse(stepValues);
    if (result.success) {
      // Clear errors for this step's fields
      for (const field of stepFields) {
        form.clearErrors(field);
      }
      return true;
    }

    // Set errors for failed fields
    for (const issue of result.error.issues) {
      const fieldName = issue.path[0] as keyof CreateEventFormData;
      form.setError(fieldName, { type: 'validation', message: issue.message });
    }
    return false;
  }, [currentStep, form]);

  const goToStep = useCallback((step: number) => {
    setError(null);
    setCurrentStep(step);
  }, []);

  const handleNext = useCallback(async () => {
    const valid = await validateCurrentStep();
    if (!valid) return;

    setCompletedSteps((prev) => new Set([...prev, currentStep]));
    setCurrentStep((prev) => Math.min(prev + 1, TOTAL_STEPS - 1));
    setError(null);
  }, [currentStep, validateCurrentStep]);

  const handleBack = useCallback(() => {
    setCurrentStep((prev) => Math.max(prev - 1, 0));
    setError(null);
  }, []);

  const handleSubmit = async () => {
    setError(null);

    // Final validation against full schema
    const values = form.getValues();
    const result = createEventSchema.safeParse(values);
    if (!result.success) {
      setError(result.error.issues[0]?.message || 'Please fix form errors');
      return;
    }

    setIsSubmitting(true);

    try {
      const data = result.data;
      const body: CreateEventRequest = {
        mountainId: data.mountainId,
        title: data.title.trim(),
        eventDate: data.eventDate,
      };

      if (data.notes?.trim()) body.notes = data.notes.trim();
      if (data.departureTime) body.departureTime = data.departureTime;
      if (data.departureLocation?.trim()) body.departureLocation = data.departureLocation.trim();
      if (data.skillLevel && data.skillLevel !== '') body.skillLevel = data.skillLevel as CreateEventRequest['skillLevel'];
      if (data.carpoolAvailable) {
        body.carpoolAvailable = true;
        body.carpoolSeats = data.carpoolSeats || 0;
      }
      if (data.maxAttendees) {
        body.maxAttendees = data.maxAttendees;
      }

      const res = await fetch('/api/events', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });

      if (!res.ok) {
        const errData = await res.json();
        throw new Error(errData.error || 'Failed to create event');
      }

      const responseData: CreateEventResponse = await res.json();
      clearDraft();
      setCreatedEvent(responseData);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  const isLastStep = currentStep === TOTAL_STEPS - 1;

  return (
    <div className="min-h-screen bg-slate-900">
      {/* Header */}
      <header className="sticky top-0 z-10 bg-slate-900/95 backdrop-blur-sm border-b border-slate-800">
        <div className="max-w-2xl mx-auto px-4 py-4">
          <div className="flex items-center gap-3">
            <Link href="/events" className="text-gray-400 hover:text-white transition-colors">
              <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </Link>
            <h1 className="text-xl font-bold text-white">Create Event</h1>
          </div>
        </div>
      </header>

      {/* Step Indicator */}
      <div className="max-w-2xl mx-auto px-4 pt-6 pb-2">
        <StepIndicator
          currentStep={currentStep}
          onStepClick={goToStep}
          completedSteps={completedSteps}
        />
      </div>

      {/* Form Content */}
      <div className="max-w-2xl mx-auto px-4 py-6">
        {/* Draft Banner */}
        {draft && (
          <div className="mb-4">
            <DraftBanner
              savedAt={draft.savedAt}
              onResume={() => {
                restoreDraft();
                setShowDraft(false);
              }}
              onDiscard={() => {
                discardDraft();
                setShowDraft(false);
              }}
            />
          </div>
        )}

        {/* Quick Presets (only on step 0 when form is mostly empty) */}
        {currentStep === 0 && !form.getValues().title && (
          <div className="mb-5">
            <p className="text-xs text-gray-500 mb-2">Quick start</p>
            <QuickPresets form={form} />
          </div>
        )}

        {error && (
          <div className="bg-red-500/20 border border-red-500/50 text-red-400 px-4 py-3 rounded-xl mb-6">
            {error}
          </div>
        )}

        {currentStep === 0 && <EventFormStep1 form={form} mountains={mountains} />}
        {currentStep === 1 && <EventFormStep2 form={form} />}
        {currentStep === 2 && <EventFormStep3 form={form} />}
        {currentStep === 3 && <EventFormStep4 form={form} mountains={mountains} onEditStep={goToStep} />}

        {/* Navigation */}
        <div className="flex gap-3 mt-8">
          {currentStep > 0 && (
            <button
              type="button"
              onClick={handleBack}
              className="flex-1 py-3.5 bg-slate-800 hover:bg-slate-700 text-white rounded-xl font-medium transition-colors border border-slate-700"
            >
              Back
            </button>
          )}
          {isLastStep ? (
            <button
              type="button"
              onClick={handleSubmit}
              disabled={isSubmitting}
              className="flex-1 py-3.5 bg-sky-500 hover:bg-sky-600 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-xl font-semibold transition-colors"
            >
              {isSubmitting ? 'Creating...' : 'Create Event'}
            </button>
          ) : (
            <button
              type="button"
              onClick={handleNext}
              className="flex-1 py-3.5 bg-sky-500 hover:bg-sky-600 text-white rounded-xl font-semibold transition-colors"
            >
              Next
            </button>
          )}
        </div>
      </div>

      {/* Post-creation modal */}
      {createdEvent && (
        <PostCreateModal
          response={createdEvent}
          onClose={() => router.push(`/events/${createdEvent.event.id}`)}
        />
      )}
    </div>
  );
}

import { z } from 'zod';
import type { SkillLevel } from '@/types/event';

const today = () => new Date().toLocaleDateString('en-CA', { timeZone: 'America/Los_Angeles' });

// Step 1: Where & When
export const step1Schema = z.object({
  mountainId: z.string().min(1, 'Please select a mountain'),
  eventDate: z.string().min(1, 'Please select a date').refine(
    (date) => date >= today(),
    'Date cannot be in the past'
  ),
});

// Step 2: Details
export const step2Schema = z.object({
  title: z.string().min(3, 'Title must be at least 3 characters').max(100, 'Title must be under 100 characters'),
  skillLevel: z.string().optional(),
  notes: z.string().max(2000, 'Notes must be under 2000 characters').optional(),
  maxAttendees: z.number().min(2, 'Minimum 2 attendees').max(1000, 'Maximum 1000 attendees').nullable().optional(),
});

// Step 3: Logistics
export const step3Schema = z.object({
  departureTime: z.string().optional(),
  departureLocation: z.string().max(255, 'Location must be under 255 characters').optional(),
  carpoolAvailable: z.boolean().optional(),
  carpoolSeats: z.number().min(0).max(8).optional(),
});

// Combined schema for final submission
export const createEventSchema = step1Schema.merge(step2Schema).merge(step3Schema);

export type CreateEventFormData = z.infer<typeof createEventSchema>;

export type Step1Data = z.infer<typeof step1Schema>;
export type Step2Data = z.infer<typeof step2Schema>;
export type Step3Data = z.infer<typeof step3Schema>;

// Step schemas array for per-step validation
export const stepSchemas = [step1Schema, step2Schema, step3Schema] as const;

// Skill level display labels
export const skillLevelLabels: Record<string, string> = {
  '': 'All levels welcome',
  beginner: 'Beginner',
  intermediate: 'Intermediate',
  advanced: 'Advanced',
  expert: 'Expert',
  all: 'All Levels',
};

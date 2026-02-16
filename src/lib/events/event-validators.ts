import { NextResponse } from 'next/server';
import { getMountain } from '@shredders/shared';
import { Errors, handleError } from '@/lib/errors';
import type { SkillLevel } from '@/types/event';

/**
 * Validates the mountainId and returns the mountain object.
 * Returns a NextResponse error if invalid, or the mountain if valid.
 */
export function validateMountain(mountainId: string | undefined) {
  if (!mountainId) {
    return { error: NextResponse.json({ error: 'Mountain ID is required' }, { status: 400 }) };
  }
  const mountain = getMountain(mountainId);
  if (!mountain) {
    return { error: handleError(Errors.resourceNotFound('Mountain')) };
  }
  return { mountain };
}

/**
 * Validates event title (3-100 chars).
 * Returns a NextResponse error if invalid, or null if valid.
 */
export function validateTitle(title: string | undefined): NextResponse | null {
  if (!title || title.trim().length < 3) {
    return NextResponse.json({ error: 'Title must be at least 3 characters' }, { status: 400 });
  }
  if (title.length > 100) {
    return NextResponse.json({ error: 'Title must be less than 100 characters' }, { status: 400 });
  }
  return null;
}

/**
 * Validates event notes (max 2000 chars).
 */
export function validateNotes(notes: string | undefined): NextResponse | null {
  if (notes && notes.length > 2000) {
    return NextResponse.json({ error: 'Notes must be less than 2000 characters' }, { status: 400 });
  }
  return null;
}

/**
 * Validates event date (required, not in the past).
 */
export function validateEventDate(eventDate: string | undefined): NextResponse | null {
  if (!eventDate) {
    return NextResponse.json({ error: 'Event date is required' }, { status: 400 });
  }
  const today = new Date().toLocaleDateString('en-CA', { timeZone: 'America/Los_Angeles' });
  if (eventDate < today) {
    return NextResponse.json({ error: 'Event date cannot be in the past' }, { status: 400 });
  }
  return null;
}

/**
 * Validates skill level if provided.
 */
export function validateSkillLevel(skillLevel: string | undefined): NextResponse | null {
  const validSkillLevels: SkillLevel[] = ['beginner', 'intermediate', 'advanced', 'expert', 'all'];
  if (skillLevel && !validSkillLevels.includes(skillLevel as SkillLevel)) {
    return NextResponse.json({ error: 'Invalid skill level' }, { status: 400 });
  }
  return null;
}

/**
 * Validates carpool seats (0-8).
 */
export function validateCarpoolSeats(carpoolSeats: number | undefined): NextResponse | null {
  if (carpoolSeats !== undefined && (carpoolSeats < 0 || carpoolSeats > 8)) {
    return NextResponse.json({ error: 'Carpool seats must be between 0 and 8' }, { status: 400 });
  }
  return null;
}

/**
 * Validates max attendees (1-1000).
 */
export function validateMaxAttendees(maxAttendees: number | undefined | null): NextResponse | null {
  if (maxAttendees !== undefined && maxAttendees !== null && (maxAttendees < 1 || maxAttendees > 1000)) {
    return NextResponse.json({ error: 'Max attendees must be between 1 and 1000' }, { status: 400 });
  }
  return null;
}

/**
 * Validates departure time format (HH:MM).
 */
export function validateDepartureTime(departureTime: string | undefined): NextResponse | null {
  if (departureTime && !/^\d{2}:\d{2}$/.test(departureTime)) {
    return NextResponse.json({ error: 'Departure time must be in HH:MM format' }, { status: 400 });
  }
  return null;
}

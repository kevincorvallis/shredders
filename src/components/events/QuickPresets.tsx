'use client';

import type { UseFormReturn } from 'react-hook-form';
import type { CreateEventFormData } from '@/lib/schemas/event';

interface QuickPresetsProps {
  form: UseFormReturn<CreateEventFormData>;
}

interface Preset {
  label: string;
  icon: string;
  values: Partial<CreateEventFormData>;
}

function getNextSaturday(): string {
  const now = new Date();
  const day = now.getDay();
  const daysUntilSat = (6 - day + 7) % 7 || 7;
  const sat = new Date(now);
  sat.setDate(now.getDate() + daysUntilSat);
  return sat.toISOString().split('T')[0];
}

function getNextWeekday(): string {
  const now = new Date();
  const day = now.getDay();
  // Next Mon-Fri
  const daysUntil = day >= 5 ? (8 - day) : 1; // If Fri/Sat/Sun, jump to Mon
  const next = new Date(now);
  next.setDate(now.getDate() + daysUntil);
  return next.toISOString().split('T')[0];
}

const presets: Preset[] = [
  {
    label: 'Weekend powder day',
    icon: '❄️',
    values: {
      eventDate: getNextSaturday(),
      departureTime: '07:00',
      skillLevel: 'all',
      carpoolAvailable: true,
      carpoolSeats: 3,
    },
  },
  {
    label: 'Weekday morning',
    icon: '🌅',
    values: {
      eventDate: getNextWeekday(),
      departureTime: '06:30',
      skillLevel: 'intermediate',
    },
  },
  {
    label: 'Night skiing',
    icon: '🌙',
    values: {
      departureTime: '16:00',
      skillLevel: 'all',
    },
  },
  {
    label: 'Beginners trip',
    icon: '🎿',
    values: {
      skillLevel: 'beginner',
      departureTime: '08:00',
      maxAttendees: 6,
    },
  },
];

export function QuickPresets({ form }: QuickPresetsProps) {
  const applyPreset = (preset: Preset) => {
    const current = form.getValues();
    form.reset({ ...current, ...preset.values });
  };

  return (
    <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
      {presets.map((preset) => (
        <button
          key={preset.label}
          type="button"
          onClick={() => applyPreset(preset)}
          className="flex items-center gap-1.5 px-3 py-1.5 bg-slate-800 hover:bg-slate-700 border border-slate-700 rounded-full text-sm text-gray-300 hover:text-white transition-colors whitespace-nowrap shrink-0"
        >
          <span>{preset.icon}</span>
          <span>{preset.label}</span>
        </button>
      ))}
    </div>
  );
}

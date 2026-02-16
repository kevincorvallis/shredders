/**
 * Shared event query filter logic.
 * Used by both the attendee query (joined table) and the base events query.
 */

/**
 * Parsed event filter parameters from URL search params.
 */
export interface EventFilterParams {
  mountainId: string | null;
  status: string;
  upcoming: boolean;
  dateFrom: string | null;
  dateTo: string | null;
  skillLevel: string | null;
  carpoolAvailable: string | null;
  hasAvailableSeats: boolean;
  search: string | null;
  sortBy: string;
  thisWeekend: boolean;
  createdByMe: boolean;
  attendingOnly: boolean;
  limit: number;
  offset: number;
}

/**
 * Parse and validate event filter params from URL search params.
 */
export function parseEventFilterParams(searchParams: URLSearchParams): EventFilterParams {
  const statusParam = searchParams.get('status') || 'active';
  const validStatuses = ['active', 'cancelled', 'completed'];

  return {
    mountainId: searchParams.get('mountainId'),
    status: validStatuses.includes(statusParam) ? statusParam : 'active',
    upcoming: searchParams.get('upcoming') !== 'false',
    dateFrom: searchParams.get('dateFrom'),
    dateTo: searchParams.get('dateTo'),
    skillLevel: searchParams.get('skillLevel'),
    carpoolAvailable: searchParams.get('carpoolAvailable'),
    hasAvailableSeats: searchParams.get('hasAvailableSeats') === 'true',
    search: searchParams.get('search')?.trim() || null,
    sortBy: searchParams.get('sortBy') || 'date',
    thisWeekend: searchParams.get('thisWeekend') === 'true',
    createdByMe: searchParams.get('createdByMe') === 'true',
    attendingOnly: searchParams.get('attendingOnly') === 'true',
    limit: Math.min(parseInt(searchParams.get('limit') || '20'), 100),
    offset: parseInt(searchParams.get('offset') || '0'),
  };
}

/** Get today's date in Pacific time (YYYY-MM-DD). */
export function getTodayPacific(): string {
  return new Date().toLocaleDateString('en-CA', { timeZone: 'America/Los_Angeles' });
}

/** Get this weekend's Saturday–Sunday date range. */
export function getWeekendDates(): { start: string; end: string } {
  const now = new Date();
  const dayOfWeek = now.getDay();
  const daysUntilSaturday = (6 - dayOfWeek + 7) % 7 || 7;
  const saturday = new Date(now);
  saturday.setDate(now.getDate() + (dayOfWeek === 6 ? 0 : daysUntilSaturday));
  const sunday = new Date(saturday);
  sunday.setDate(saturday.getDate() + 1);
  return {
    start: saturday.toISOString().split('T')[0],
    end: sunday.toISOString().split('T')[0],
  };
}

/** Sanitize search input to prevent PostgREST filter injection. */
export function sanitizeSearchInput(input: string): string {
  return input.replace(/[,.()\[\]]/g, '').trim();
}

/**
 * Apply common event filters to a Supabase query builder.
 *
 * @param query - Supabase query builder (any select/filter chain)
 * @param filters - Parsed filter params
 * @param prefix - Column prefix for joined-table queries (e.g. 'event.')
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function applyEventFilters(query: any, filters: EventFilterParams, prefix = ''): any {
  const col = (name: string) => `${prefix}${name}`;

  if (filters.mountainId) {
    query = query.eq(col('mountain_id'), filters.mountainId);
  }

  if (filters.skillLevel) {
    query = query.eq(col('skill_level'), filters.skillLevel);
  }

  if (filters.carpoolAvailable === 'true') {
    query = query.eq(col('carpool_available'), true);
  }

  if (filters.hasAvailableSeats) {
    query = query.eq(col('carpool_available'), true).gt(col('carpool_seats'), 0);
  }

  // Date filters
  if (filters.thisWeekend) {
    const weekend = getWeekendDates();
    query = query.gte(col('event_date'), weekend.start).lte(col('event_date'), weekend.end);
  } else {
    if (filters.dateFrom) {
      query = query.gte(col('event_date'), filters.dateFrom);
    } else if (filters.upcoming) {
      query = query.gte(col('event_date'), getTodayPacific());
    }
    if (filters.dateTo) {
      query = query.lte(col('event_date'), filters.dateTo);
    }
  }

  // Text search
  if (filters.search) {
    const sanitized = sanitizeSearchInput(filters.search);
    if (sanitized) {
      query = query.or(`${col('title')}.ilike.%${sanitized}%,${col('notes')}.ilike.%${sanitized}%`);
    }
  }

  // Sorting
  if (prefix) {
    const table = prefix.replace('.', '');
    query = filters.sortBy === 'popularity'
      ? query.order(`${table}(going_count)`, { ascending: false })
      : query.order(`${table}(event_date)`, { ascending: true });
  } else {
    query = filters.sortBy === 'popularity'
      ? query.order('going_count', { ascending: false })
      : query.order('event_date', { ascending: true });
  }

  return query;
}

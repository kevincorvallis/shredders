import { useEffect, useRef, useCallback } from 'react';
import type { UseFormReturn } from 'react-hook-form';

const STORAGE_KEY = 'shredders-event-draft';

interface DraftData {
  values: Record<string, unknown>;
  savedAt: string;
}

export function useFormDraft(form: UseFormReturn<any>) {
  const hasDraft = useRef(false);
  const initialized = useRef(false);

  // Check for existing draft on mount
  useEffect(() => {
    if (initialized.current) return;
    initialized.current = true;

    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (raw) {
        const draft: DraftData = JSON.parse(raw);
        // Only restore if draft is less than 24 hours old
        const savedAt = new Date(draft.savedAt).getTime();
        const now = Date.now();
        if (now - savedAt < 24 * 60 * 60 * 1000) {
          hasDraft.current = true;
        }
      }
    } catch {
      // Ignore parse errors
    }
  }, []);

  // Auto-save on form changes (debounced)
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  useEffect(() => {
    const subscription = form.watch((values) => {
      // Don't save empty forms
      if (!values.mountainId && !values.title && !values.eventDate) return;

      if (debounceRef.current) clearTimeout(debounceRef.current);
      debounceRef.current = setTimeout(() => {
        try {
          const draft: DraftData = {
            values,
            savedAt: new Date().toISOString(),
          };
          localStorage.setItem(STORAGE_KEY, JSON.stringify(draft));
        } catch {
          // localStorage full or unavailable
        }
      }, 500);
    });

    return () => {
      subscription.unsubscribe();
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, [form]);

  const getDraft = useCallback((): DraftData | null => {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return null;
      const draft: DraftData = JSON.parse(raw);
      const savedAt = new Date(draft.savedAt).getTime();
      if (Date.now() - savedAt > 24 * 60 * 60 * 1000) {
        localStorage.removeItem(STORAGE_KEY);
        return null;
      }
      return draft;
    } catch {
      return null;
    }
  }, []);

  const restoreDraft = useCallback(() => {
    const draft = getDraft();
    if (draft) {
      form.reset(draft.values);
      hasDraft.current = false;
    }
  }, [form, getDraft]);

  const discardDraft = useCallback(() => {
    localStorage.removeItem(STORAGE_KEY);
    hasDraft.current = false;
  }, []);

  const clearDraft = useCallback(() => {
    localStorage.removeItem(STORAGE_KEY);
  }, []);

  return {
    hasDraft: hasDraft.current,
    getDraft,
    restoreDraft,
    discardDraft,
    clearDraft,
  };
}

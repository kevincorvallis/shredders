'use client';

import { createContext, useContext, useState, useEffect, ReactNode } from 'react';

interface MountainContextType {
  selectedMountainId: string;
  setSelectedMountain: (id: string) => void;
}

const MountainContext = createContext<MountainContextType | undefined>(undefined);

const STORAGE_KEY = 'selectedMountainId';
const DEFAULT_MOUNTAIN = 'baker';

export function MountainProvider({ children }: { children: ReactNode }) {
  const [selectedMountainId, setSelectedMountainId] = useState(DEFAULT_MOUNTAIN);
  const [isHydrated, setIsHydrated] = useState(false);

  // Load from localStorage on mount
  useEffect(() => {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      setSelectedMountainId(stored);
    }
    setIsHydrated(true);
  }, []);

  const setSelectedMountain = (id: string) => {
    setSelectedMountainId(id);
    localStorage.setItem(STORAGE_KEY, id);
  };

  // Prevent hydration mismatch by not rendering until hydrated
  if (!isHydrated) {
    return (
      <MountainContext.Provider value={{ selectedMountainId: DEFAULT_MOUNTAIN, setSelectedMountain }}>
        {children}
      </MountainContext.Provider>
    );
  }

  return (
    <MountainContext.Provider value={{ selectedMountainId, setSelectedMountain }}>
      {children}
    </MountainContext.Provider>
  );
}

export function useMountain() {
  const context = useContext(MountainContext);
  if (!context) {
    throw new Error('useMountain must be used within a MountainProvider');
  }
  return context;
}

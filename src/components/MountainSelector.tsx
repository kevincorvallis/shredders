'use client';

import { useState, useRef, useEffect } from 'react';
import { getAllMountains, type MountainConfig } from '@/data/mountains';

interface MountainSelectorProps {
  selectedId: string;
  onChange: (mountainId: string) => void;
  showRegion?: boolean;
}

export function MountainSelector({
  selectedId,
  onChange,
  showRegion = true,
}: MountainSelectorProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [currentSelectedId, setCurrentSelectedId] = useState(selectedId);
  const dropdownRef = useRef<HTMLDivElement>(null);

  const mountains = getAllMountains();
  const selected = mountains.find((m) => m.id === currentSelectedId);

  const washingtonMountains = mountains.filter((m) => m.region === 'washington');
  const oregonMountains = mountains.filter((m) => m.region === 'oregon');
  const idahoMountains = mountains.filter((m) => m.region === 'idaho');

  // Sync with external prop changes
  useEffect(() => {
    if (selectedId !== currentSelectedId) {
      setCurrentSelectedId(selectedId);
    }
  }, [selectedId, currentSelectedId]);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleSelect = (mountainId: string) => {
    onChange(mountainId);
    setIsOpen(false);
  };

  return (
    <div className="relative" ref={dropdownRef}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 rounded-xl border border-slate-700 transition-colors"
      >
        {selected && (
          <span
            className="w-3 h-3 rounded-full"
            style={{ backgroundColor: selected.color }}
          />
        )}
        <span className="text-white font-medium">
          {selected?.shortName || 'Select Mountain'}
        </span>
        <svg
          className={`w-4 h-4 text-gray-400 transition-transform ${isOpen ? 'rotate-180' : ''}`}
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>

      {isOpen && (
        <div className="absolute top-full left-0 mt-2 w-64 bg-slate-800 border border-slate-700 rounded-xl shadow-xl z-50 overflow-hidden">
          {showRegion ? (
            <>
              <div className="px-3 py-2 bg-slate-700/50">
                <span className="text-xs font-semibold text-gray-400 uppercase tracking-wider">
                  Washington
                </span>
              </div>
              {washingtonMountains.map((mountain) => (
                <MountainOption
                  key={mountain.id}
                  mountain={mountain}
                  isSelected={mountain.id === currentSelectedId}
                  onSelect={handleSelect}
                />
              ))}
              <div className="px-3 py-2 bg-slate-700/50">
                <span className="text-xs font-semibold text-gray-400 uppercase tracking-wider">
                  Oregon
                </span>
              </div>
              {oregonMountains.map((mountain) => (
                <MountainOption
                  key={mountain.id}
                  mountain={mountain}
                  isSelected={mountain.id === currentSelectedId}
                  onSelect={handleSelect}
                />
              ))}
              {idahoMountains.length > 0 && (
                <>
                  <div className="px-3 py-2 bg-slate-700/50">
                    <span className="text-xs font-semibold text-gray-400 uppercase tracking-wider">
                      Idaho
                    </span>
                  </div>
                  {idahoMountains.map((mountain) => (
                    <MountainOption
                      key={mountain.id}
                      mountain={mountain}
                      isSelected={mountain.id === currentSelectedId}
                      onSelect={handleSelect}
                    />
                  ))}
                </>
              )}
            </>
          ) : (
            mountains.map((mountain) => (
              <MountainOption
                key={mountain.id}
                mountain={mountain}
                isSelected={mountain.id === currentSelectedId}
                onSelect={handleSelect}
              />
            ))
          )}
        </div>
      )}
    </div>
  );
}

interface MountainOptionProps {
  mountain: MountainConfig;
  isSelected: boolean;
  onSelect: (id: string) => void;
}

function MountainOption({ mountain, isSelected, onSelect }: MountainOptionProps) {
  return (
    <button
      onClick={() => onSelect(mountain.id)}
      className={`w-full flex items-center gap-3 px-4 py-3 hover:bg-slate-700/50 transition-colors ${
        isSelected ? 'bg-slate-700/30' : ''
      }`}
    >
      <span
        className="w-3 h-3 rounded-full flex-shrink-0"
        style={{ backgroundColor: mountain.color }}
      />
      <div className="flex-1 text-left">
        <div className="text-white font-medium">{mountain.name}</div>
        <div className="text-gray-400 text-xs">
          {mountain.elevation.summit.toLocaleString()}ft summit
          {mountain.snotel ? '' : ' • No SNOTEL'}
        </div>
      </div>
      {isSelected && (
        <svg className="w-5 h-5 text-sky-400" fill="currentColor" viewBox="0 0 20 20">
          <path
            fillRule="evenodd"
            d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
            clipRule="evenodd"
          />
        </svg>
      )}
    </button>
  );
}

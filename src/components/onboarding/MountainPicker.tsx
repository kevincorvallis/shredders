'use client';

import { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { getAllMountains, type MountainConfig } from '@shredders/shared';
import { Search, MapPin, Check, ChevronRight, Mountain } from 'lucide-react';

interface MountainPickerProps {
  onComplete: (selectedMountains: string[]) => void;
  onSkip: () => void;
  initialSelected?: string[];
}

export function MountainPicker({ onComplete, onSkip, initialSelected = [] }: MountainPickerProps) {
  const [selected, setSelected] = useState<Set<string>>(new Set(initialSelected));
  const [searchQuery, setSearchQuery] = useState('');

  const mountains = getAllMountains();

  // Group mountains by region
  const groupedMountains = useMemo(() => {
    const filtered = mountains.filter(m =>
      m.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      m.shortName.toLowerCase().includes(searchQuery.toLowerCase())
    );

    return {
      washington: filtered.filter(m => m.region === 'washington'),
      oregon: filtered.filter(m => m.region === 'oregon'),
      idaho: filtered.filter(m => m.region === 'idaho'),
    };
  }, [mountains, searchQuery]);

  const toggleMountain = (id: string) => {
    setSelected(prev => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  const handleContinue = () => {
    onComplete(Array.from(selected));
  };

  return (
    <div className="fixed inset-0 z-50 flex flex-col bg-gradient-to-br from-background via-blue-900 to-background overflow-hidden">
      {/* Animated background */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <motion.div
          className="absolute top-0 left-1/4 w-96 h-96 bg-blue-500/20 rounded-full blur-3xl"
          animate={{
            y: [0, 100, 0],
            scale: [1, 1.2, 1],
            opacity: [0.3, 0.5, 0.3],
          }}
          transition={{
            duration: 10,
            repeat: Infinity,
            ease: 'easeInOut',
          }}
        />
        <motion.div
          className="absolute bottom-0 right-1/4 w-96 h-96 bg-cyan-500/20 rounded-full blur-3xl"
          animate={{
            y: [0, -100, 0],
            scale: [1.2, 1, 1.2],
            opacity: [0.4, 0.6, 0.4],
          }}
          transition={{
            duration: 12,
            repeat: Infinity,
            ease: 'easeInOut',
          }}
        />
      </div>

      {/* Header */}
      <div className="relative z-10 px-4 pt-6 pb-4">
        <div className="max-w-2xl mx-auto">
          <div className="flex items-center justify-between mb-4">
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
            >
              <h1 className="text-2xl font-bold text-text-primary">Pick Your Mountains</h1>
              <p className="text-blue-200/70 text-sm mt-1">
                Select your home mountains for personalized alerts
              </p>
            </motion.div>
            <button
              onClick={onSkip}
              className="text-text-tertiary hover:text-text-primary text-sm font-medium transition-colors"
            >
              Skip
            </button>
          </div>

          {/* Search */}
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="relative"
          >
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-blue-300/50" />
            <input
              type="text"
              placeholder="Search mountains..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-3 bg-white/10 border border-white/20 rounded-xl text-text-primary placeholder-blue-200/50 focus:outline-none focus:ring-2 focus:ring-blue-400 focus:border-transparent transition-all"
            />
          </motion.div>

          {/* Selected count */}
          {selected.size > 0 && (
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              className="mt-3 flex items-center gap-2"
            >
              <div className="flex -space-x-2">
                {Array.from(selected).slice(0, 3).map(id => {
                  const m = mountains.find(mt => mt.id === id);
                  return m ? (
                    <div
                      key={id}
                      className="w-6 h-6 rounded-full border-2 border-background"
                      style={{ backgroundColor: m.color }}
                    />
                  ) : null;
                })}
                {selected.size > 3 && (
                  <div className="w-6 h-6 rounded-full bg-surface-tertiary border-2 border-background flex items-center justify-center text-xs text-text-primary">
                    +{selected.size - 3}
                  </div>
                )}
              </div>
              <span className="text-sm text-blue-200/70">
                {selected.size} mountain{selected.size !== 1 ? 's' : ''} selected
              </span>
            </motion.div>
          )}
        </div>
      </div>

      {/* Mountain list */}
      <div className="flex-1 overflow-y-auto px-4 pb-32">
        <div className="max-w-2xl mx-auto space-y-6">
          {Object.entries(groupedMountains).map(([region, regionMountains]) => (
            regionMountains.length > 0 && (
              <motion.div
                key={region}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
              >
                <div className="flex items-center gap-2 mb-3">
                  <MapPin className="w-4 h-4 text-blue-400" />
                  <h2 className="text-sm font-semibold text-blue-200/70 uppercase tracking-wider">
                    {region}
                  </h2>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {regionMountains.map((mountain) => (
                    <MountainCard
                      key={mountain.id}
                      mountain={mountain}
                      isSelected={selected.has(mountain.id)}
                      onToggle={() => toggleMountain(mountain.id)}
                    />
                  ))}
                </div>
              </motion.div>
            )
          ))}
        </div>
      </div>

      {/* Footer */}
      <div className="fixed bottom-0 left-0 right-0 bg-gradient-to-t from-background via-background/95 to-transparent pt-8 pb-6 px-4">
        <div className="max-w-2xl mx-auto">
          <motion.button
            onClick={handleContinue}
            className="w-full flex items-center justify-center gap-2 py-4 px-6 bg-gradient-to-r from-blue-600 to-cyan-600 hover:from-blue-700 hover:to-cyan-700 text-text-primary font-semibold rounded-xl shadow-lg shadow-blue-500/30 transition-all duration-200"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            {selected.size > 0 ? (
              <>
                Continue with {selected.size} mountain{selected.size !== 1 ? 's' : ''}
                <ChevronRight className="w-5 h-5" />
              </>
            ) : (
              <>
                Continue without selecting
                <ChevronRight className="w-5 h-5" />
              </>
            )}
          </motion.button>
          <p className="text-center text-xs text-blue-200/50 mt-3">
            You can change this anytime in your profile
          </p>
        </div>
      </div>
    </div>
  );
}

interface MountainCardProps {
  mountain: MountainConfig;
  isSelected: boolean;
  onToggle: () => void;
}

function MountainCard({ mountain, isSelected, onToggle }: MountainCardProps) {
  return (
    <motion.button
      onClick={onToggle}
      className={`relative flex items-center gap-3 p-4 rounded-xl border transition-all duration-200 text-left ${
        isSelected
          ? 'bg-blue-500/20 border-blue-500/50'
          : 'bg-white/5 border-white/10 hover:bg-white/10 hover:border-white/20'
      }`}
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
    >
      {/* Color indicator */}
      <div
        className="w-10 h-10 rounded-lg flex items-center justify-center shrink-0"
        style={{ backgroundColor: `${mountain.color}20` }}
      >
        <Mountain
          className="w-5 h-5"
          style={{ color: mountain.color }}
        />
      </div>

      {/* Info */}
      <div className="flex-1 min-w-0">
        <div className="font-medium text-text-primary truncate">{mountain.name}</div>
        <div className="text-xs text-text-tertiary">
          {mountain.elevation.summit.toLocaleString()}ft summit
        </div>
      </div>

      {/* Selection indicator */}
      <AnimatePresence>
        {isSelected && (
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            exit={{ scale: 0 }}
            className="w-6 h-6 rounded-full bg-blue-500 flex items-center justify-center shrink-0"
          >
            <Check className="w-4 h-4 text-text-primary" />
          </motion.div>
        )}
      </AnimatePresence>
    </motion.button>
  );
}

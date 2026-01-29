'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Snowflake, TrendingUp, Map, Users, Check, ChevronRight } from 'lucide-react';

export type PreferenceType = 'powder' | 'vertical' | 'explore' | 'social';

interface PreferencesStepProps {
  onComplete: (preferences: PreferenceType[]) => void;
  onSkip: () => void;
  initialSelected?: PreferenceType[];
}

const PREFERENCES = [
  {
    id: 'powder' as PreferenceType,
    icon: Snowflake,
    title: 'Chasing Powder',
    description: 'Fresh snow alerts and powder day forecasts',
    color: 'from-sky-500 to-blue-600',
    bgColor: 'bg-sky-500/20',
    borderColor: 'border-sky-500/50',
    iconColor: 'text-sky-400',
  },
  {
    id: 'vertical' as PreferenceType,
    icon: TrendingUp,
    title: 'Tracking Vertical',
    description: 'Stats, goals, and personal records',
    color: 'from-emerald-500 to-green-600',
    bgColor: 'bg-emerald-500/20',
    borderColor: 'border-emerald-500/50',
    iconColor: 'text-emerald-400',
  },
  {
    id: 'explore' as PreferenceType,
    icon: Map,
    title: 'Exploring Resorts',
    description: 'Discover new mountains and hidden gems',
    color: 'from-purple-500 to-violet-600',
    bgColor: 'bg-purple-500/20',
    borderColor: 'border-purple-500/50',
    iconColor: 'text-purple-400',
  },
  {
    id: 'social' as PreferenceType,
    icon: Users,
    title: 'Riding with Friends',
    description: 'Connect, share, and find ski buddies',
    color: 'from-amber-500 to-orange-600',
    bgColor: 'bg-amber-500/20',
    borderColor: 'border-amber-500/50',
    iconColor: 'text-amber-400',
  },
];

export function PreferencesStep({ onComplete, onSkip, initialSelected = [] }: PreferencesStepProps) {
  const [selected, setSelected] = useState<Set<PreferenceType>>(new Set(initialSelected));

  const togglePreference = (id: PreferenceType) => {
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
    <div className="fixed inset-0 z-50 flex flex-col items-center justify-center bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900 overflow-hidden">
      {/* Animated background */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <motion.div
          className="absolute top-0 left-1/4 w-96 h-96 bg-purple-500/20 rounded-full blur-3xl"
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
          className="absolute bottom-0 right-1/4 w-96 h-96 bg-amber-500/20 rounded-full blur-3xl"
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

      {/* Falling snowflakes */}
      {Array.from({ length: 15 }).map((_, i) => (
        <motion.div
          key={i}
          className="absolute text-white text-xl opacity-60"
          style={{
            left: `${Math.random() * 100}%`,
            top: '-10%',
          }}
          animate={{
            y: ['0vh', '110vh'],
            x: [0, Math.sin(i) * 40, 0],
            rotate: [0, 360],
            opacity: [0, 0.6, 0],
          }}
          transition={{
            duration: 8 + Math.random() * 4,
            delay: Math.random() * 5,
            repeat: Infinity,
            ease: 'linear',
          }}
        >
          ❄
        </motion.div>
      ))}

      {/* Main content */}
      <div className="relative z-10 w-full max-w-xl mx-auto px-4">
        {/* Skip button */}
        <div className="absolute top-4 right-4">
          <button
            onClick={onSkip}
            className="text-slate-400 hover:text-white text-sm font-medium transition-colors"
          >
            Skip
          </button>
        </div>

        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-8"
        >
          <h1 className="text-3xl font-bold text-white mb-2">What Gets You Stoked?</h1>
          <p className="text-blue-200/70">
            We&apos;ll personalize your experience based on what you love
          </p>
        </motion.div>

        {/* Preference cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-8">
          {PREFERENCES.map((pref, index) => {
            const isSelected = selected.has(pref.id);
            const Icon = pref.icon;

            return (
              <motion.button
                key={pref.id}
                onClick={() => togglePreference(pref.id)}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.1 + index * 0.1 }}
                className={`relative p-5 rounded-2xl border-2 transition-all duration-200 text-left ${
                  isSelected
                    ? `${pref.bgColor} ${pref.borderColor}`
                    : 'bg-white/5 border-white/10 hover:bg-white/10 hover:border-white/20'
                }`}
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
              >
                {/* Selection indicator */}
                <AnimatePresence>
                  {isSelected && (
                    <motion.div
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      exit={{ scale: 0 }}
                      className={`absolute top-3 right-3 w-6 h-6 rounded-full bg-gradient-to-r ${pref.color} flex items-center justify-center`}
                    >
                      <Check className="w-4 h-4 text-white" />
                    </motion.div>
                  )}
                </AnimatePresence>

                {/* Icon */}
                <div className={`w-12 h-12 rounded-xl ${pref.bgColor} flex items-center justify-center mb-3`}>
                  <Icon className={`w-6 h-6 ${pref.iconColor}`} />
                </div>

                {/* Text */}
                <div className="font-semibold text-white text-lg mb-1">{pref.title}</div>
                <div className="text-sm text-slate-400">{pref.description}</div>
              </motion.button>
            );
          })}
        </div>

        {/* Continue button */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5 }}
        >
          <motion.button
            onClick={handleContinue}
            className="w-full flex items-center justify-center gap-2 py-4 px-6 bg-gradient-to-r from-blue-600 to-cyan-600 hover:from-blue-700 hover:to-cyan-700 text-white font-semibold rounded-xl shadow-lg shadow-blue-500/30 transition-all duration-200"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            {selected.size > 0 ? (
              <>
                Continue
                <ChevronRight className="w-5 h-5" />
              </>
            ) : (
              <>
                Skip for now
                <ChevronRight className="w-5 h-5" />
              </>
            )}
          </motion.button>
          <p className="text-center text-xs text-blue-200/50 mt-4">
            Select as many as you like - or none at all
          </p>
        </motion.div>
      </div>
    </div>
  );
}

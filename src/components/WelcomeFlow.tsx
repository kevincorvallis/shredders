'use client';

import { useState, type ReactNode } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { MountainPicker, PreferencesStep, type PreferenceType } from './onboarding';

interface WelcomeFlowProps {
  onComplete: () => void;
  userName?: string;
  showExtendedOnboarding?: boolean;
}

type OnboardingPhase = 'carousel' | 'mountains' | 'preferences';

interface Step {
  id: string;
  title: string;
  description: string;
  icon: ReactNode;
  gradient: string;
}

const steps: Step[] = [
  {
    id: 'welcome',
    title: 'Welcome to Shredders',
    description: 'Your all-in-one powder tracking companion. Get real-time conditions, forecasts, and alerts for your favorite mountains.',
    icon: (
      <svg className="w-16 h-16" fill="currentColor" viewBox="0 0 24 24">
        <path d="M3 20h18L12 4 3 20zm9-3.5a1.5 1.5 0 100-3 1.5 1.5 0 000 3z" />
      </svg>
    ),
    gradient: 'from-blue-600 to-blue-400',
  },
  {
    id: 'conditions',
    title: 'Track Conditions',
    description: 'Monitor snow depth, powder scores, lift status, and weather forecasts across 26+ mountains in the Pacific Northwest.',
    icon: (
      <svg className="w-16 h-16" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M3 15a4 4 0 004 4h9a5 5 0 10-.1-9.999 5.002 5.002 0 10-9.78 2.096A4.001 4.001 0 003 15z"
        />
      </svg>
    ),
    gradient: 'from-cyan-600 to-cyan-400',
  },
  {
    id: 'alerts',
    title: 'Get Smart Alerts',
    description: 'Receive notifications when fresh powder hits your favorite mountains. Never miss an epic powder day again.',
    icon: (
      <svg className="w-16 h-16" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"
        />
      </svg>
    ),
    gradient: 'from-amber-600 to-amber-400',
  },
  {
    id: 'social',
    title: 'Join the Crew',
    description: 'Connect with other riders, share conditions, check in at mountains, and find your next adventure buddy.',
    icon: (
      <svg className="w-16 h-16" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
        />
      </svg>
    ),
    gradient: 'from-emerald-600 to-emerald-400',
  },
];

export function WelcomeFlow({ onComplete, userName, showExtendedOnboarding = true }: WelcomeFlowProps) {
  const [currentStep, setCurrentStep] = useState(0);
  const [direction, setDirection] = useState(1);
  const [phase, setPhase] = useState<OnboardingPhase>('carousel');
  const [selectedMountains, setSelectedMountains] = useState<string[]>([]);
  const [selectedPreferences, setSelectedPreferences] = useState<PreferenceType[]>([]);

  const handleNext = () => {
    if (currentStep < steps.length - 1) {
      setDirection(1);
      setCurrentStep(currentStep + 1);
    } else if (showExtendedOnboarding) {
      // Move to mountain picker
      setPhase('mountains');
    } else {
      onComplete();
    }
  };

  const handlePrev = () => {
    if (currentStep > 0) {
      setDirection(-1);
      setCurrentStep(currentStep - 1);
    }
  };

  const handleMountainsComplete = (mountains: string[]) => {
    setSelectedMountains(mountains);
    // TODO: Save to user profile
    setPhase('preferences');
  };

  const handleMountainsSkip = () => {
    setPhase('preferences');
  };

  const handlePreferencesComplete = (preferences: PreferenceType[]) => {
    setSelectedPreferences(preferences);
    // TODO: Save to user profile
    onComplete();
  };

  const handlePreferencesSkip = () => {
    onComplete();
  };

  // Render mountain picker phase
  if (phase === 'mountains') {
    return (
      <MountainPicker
        onComplete={handleMountainsComplete}
        onSkip={handleMountainsSkip}
        initialSelected={selectedMountains}
      />
    );
  }

  // Render preferences phase
  if (phase === 'preferences') {
    return (
      <PreferencesStep
        onComplete={handlePreferencesComplete}
        onSkip={handlePreferencesSkip}
        initialSelected={selectedPreferences}
      />
    );
  }

  const handleSkip = () => {
    onComplete();
  };

  const step = steps[currentStep];

  const slideVariants = {
    enter: (direction: number) => ({
      x: direction > 0 ? 1000 : -1000,
      opacity: 0,
    }),
    center: {
      zIndex: 1,
      x: 0,
      opacity: 1,
    },
    exit: (direction: number) => ({
      zIndex: 0,
      x: direction < 0 ? 1000 : -1000,
      opacity: 0,
    }),
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-gradient-to-br from-background via-blue-900 to-background overflow-hidden">
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

      {/* Falling snowflakes */}
      {Array.from({ length: 20 }).map((_, i) => (
        <motion.div
          key={i}
          className="absolute text-text-primary text-2xl opacity-70"
          style={{
            left: `${Math.random() * 100}%`,
            top: '-10%',
          }}
          animate={{
            y: ['0vh', '110vh'],
            x: [0, Math.sin(i) * 50, 0],
            rotate: [0, 360],
            opacity: [0, 0.7, 0],
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
      <div className="relative z-10 w-full max-w-2xl mx-auto px-4">
        {/* Skip button */}
        <div className="absolute top-4 right-4">
          <button
            onClick={handleSkip}
            className="text-text-secondary hover:text-text-primary text-sm font-medium transition-colors"
          >
            Skip
          </button>
        </div>

        {/* Progress indicators */}
        <div className="flex justify-center gap-2 mb-8">
          {steps.map((_, index) => (
            <motion.div
              key={index}
              className={`h-1.5 rounded-full transition-all duration-300 ${
                index === currentStep
                  ? 'w-8 bg-white'
                  : index < currentStep
                  ? 'w-1.5 bg-white/50'
                  : 'w-1.5 bg-white/20'
              }`}
              animate={{
                scale: index === currentStep ? 1.2 : 1,
              }}
            />
          ))}
        </div>

        {/* Step content */}
        <AnimatePresence initial={false} custom={direction} mode="wait">
          <motion.div
            key={currentStep}
            custom={direction}
            variants={slideVariants}
            initial="enter"
            animate="center"
            exit="exit"
            transition={{
              x: { type: 'spring', stiffness: 300, damping: 30 },
              opacity: { duration: 0.2 },
            }}
            className="text-center"
          >
            {/* Icon */}
            <motion.div
              className={`inline-flex p-6 rounded-full bg-gradient-to-br ${step.gradient} mb-6 shadow-2xl`}
              initial={{ scale: 0, rotate: -180 }}
              animate={{ scale: 1, rotate: 0 }}
              transition={{
                type: 'spring',
                stiffness: 260,
                damping: 20,
                delay: 0.1,
              }}
            >
              <div className="text-text-primary">{step.icon}</div>
            </motion.div>

            {/* Greeting (first step only) */}
            {currentStep === 0 && userName && (
              <motion.p
                className="text-text-secondary text-lg mb-2"
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
              >
                Hey {userName}!
              </motion.p>
            )}

            {/* Title */}
            <motion.h2
              className="text-4xl md:text-5xl font-bold text-text-primary mb-4"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
            >
              {step.title}
            </motion.h2>

            {/* Description */}
            <motion.p
              className="text-text-secondary text-lg max-w-xl mx-auto leading-relaxed"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
            >
              {step.description}
            </motion.p>
          </motion.div>
        </AnimatePresence>

        {/* Navigation */}
        <motion.div
          className="flex items-center justify-between mt-12"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.4 }}
        >
          <button
            onClick={handlePrev}
            disabled={currentStep === 0}
            className={`flex items-center gap-2 px-6 py-3 rounded-lg font-medium transition-all duration-200 ${
              currentStep === 0
                ? 'opacity-0 pointer-events-none'
                : 'text-text-primary hover:bg-white/10'
            }`}
          >
            <svg
              className="w-5 h-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M15 19l-7-7 7-7"
              />
            </svg>
            Back
          </button>

          <motion.button
            onClick={handleNext}
            className="flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-blue-600 to-cyan-600 hover:from-blue-700 hover:to-cyan-700 text-text-primary font-semibold rounded-lg shadow-lg shadow-blue-500/50 transition-all duration-200"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
          >
            {currentStep === steps.length - 1 ? (
              <>
                Get Started
                <svg
                  className="w-5 h-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M5 13l4 4L19 7"
                  />
                </svg>
              </>
            ) : (
              <>
                Next
                <svg
                  className="w-5 h-5"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M9 5l7 7-7 7"
                  />
                </svg>
              </>
            )}
          </motion.button>
        </motion.div>
      </div>
    </div>
  );
}

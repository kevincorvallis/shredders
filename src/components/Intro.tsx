'use client';

import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

interface Snowflake {
  id: number;
  x: number;
  delay: number;
  duration: number;
  size: number;
  opacity: number;
}

interface IntroProps {
  onComplete?: () => void;
  duration?: number;
}

export function Intro({ onComplete, duration = 3500 }: IntroProps) {
  const [isVisible, setIsVisible] = useState(true);
  const [snowflakes, setSnowflakes] = useState<Snowflake[]>([]);
  const [showContent, setShowContent] = useState(false);

  // Generate snowflakes
  useEffect(() => {
    const flakes: Snowflake[] = Array.from({ length: 50 }, (_, i) => ({
      id: i,
      x: Math.random() * 100,
      delay: Math.random() * 2,
      duration: 3 + Math.random() * 4,
      size: 4 + Math.random() * 8,
      opacity: 0.3 + Math.random() * 0.7,
    }));
    setSnowflakes(flakes);

    // Show content after a brief delay
    const contentTimer = setTimeout(() => setShowContent(true), 200);
    return () => clearTimeout(contentTimer);
  }, []);

  // Handle completion
  useEffect(() => {
    const timer = setTimeout(() => {
      setIsVisible(false);
      setTimeout(() => onComplete?.(), 500);
    }, duration);
    return () => clearTimeout(timer);
  }, [duration, onComplete]);

  const skipIntro = useCallback(() => {
    setIsVisible(false);
    setTimeout(() => onComplete?.(), 300);
  }, [onComplete]);

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.div
          initial={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.5, ease: 'easeInOut' }}
          className="fixed inset-0 z-50 flex items-center justify-center overflow-hidden cursor-pointer"
          style={{
            background: 'linear-gradient(180deg, #0c1929 0%, #0f172a 50%, #1a1f35 100%)',
          }}
          onClick={skipIntro}
        >
          {/* Animated stars background */}
          <div className="absolute inset-0">
            {[...Array(30)].map((_, i) => (
              <motion.div
                key={`star-${i}`}
                className="absolute rounded-full bg-white"
                style={{
                  width: 1 + Math.random() * 2,
                  height: 1 + Math.random() * 2,
                  left: `${Math.random() * 100}%`,
                  top: `${Math.random() * 60}%`,
                }}
                animate={{
                  opacity: [0.2, 0.8, 0.2],
                  scale: [1, 1.2, 1],
                }}
                transition={{
                  duration: 2 + Math.random() * 2,
                  repeat: Infinity,
                  delay: Math.random() * 2,
                }}
              />
            ))}
          </div>

          {/* Snowflakes */}
          <div className="absolute inset-0 overflow-hidden pointer-events-none">
            {snowflakes.map((flake) => (
              <motion.div
                key={flake.id}
                className="absolute text-white"
                style={{
                  left: `${flake.x}%`,
                  fontSize: flake.size,
                  opacity: 0,
                }}
                animate={{
                  y: ['-10vh', '110vh'],
                  opacity: [0, flake.opacity, flake.opacity, 0],
                  rotate: [0, 360],
                  x: [0, Math.sin(flake.id) * 30, 0],
                }}
                transition={{
                  duration: flake.duration,
                  delay: flake.delay,
                  repeat: Infinity,
                  ease: 'linear',
                }}
              >
                ❄
              </motion.div>
            ))}
          </div>

          {/* Main content */}
          {showContent && (
            <div className="relative z-10 flex flex-col items-center">
              {/* Logo container */}
              <motion.div
                className="relative"
                initial={{ scale: 0.8, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ duration: 0.8, ease: [0.34, 1.56, 0.64, 1] }}
              >
                {/* Outer glow ring */}
                <motion.div
                  className="absolute -inset-8 rounded-full"
                  style={{
                    background: 'radial-gradient(circle, rgba(34, 197, 94, 0.15) 0%, transparent 70%)',
                  }}
                  animate={{
                    scale: [1, 1.2, 1],
                    opacity: [0.5, 0.8, 0.5],
                  }}
                  transition={{
                    duration: 2,
                    repeat: Infinity,
                    ease: 'easeInOut',
                  }}
                />

                {/* SVG Logo with animations */}
                <svg
                  width="200"
                  height="200"
                  viewBox="0 0 200 200"
                  className="relative z-10"
                >
                  <defs>
                    <linearGradient id="introMountainGrad" x1="0%" y1="0%" x2="0%" y2="100%">
                      <stop offset="0%" stopColor="#1e40af" />
                      <stop offset="100%" stopColor="#3b82f6" />
                    </linearGradient>
                    <linearGradient id="introSnowGrad" x1="0%" y1="0%" x2="0%" y2="100%">
                      <stop offset="0%" stopColor="#ffffff" />
                      <stop offset="100%" stopColor="#e0f2fe" />
                    </linearGradient>
                    <linearGradient id="introSkyGrad" x1="0%" y1="0%" x2="0%" y2="100%">
                      <stop offset="0%" stopColor="#0c4a6e" />
                      <stop offset="100%" stopColor="#0369a1" />
                    </linearGradient>
                    <filter id="glow">
                      <feGaussianBlur stdDeviation="3" result="coloredBlur" />
                      <feMerge>
                        <feMergeNode in="coloredBlur" />
                        <feMergeNode in="SourceGraphic" />
                      </feMerge>
                    </filter>
                  </defs>

                  {/* Background Circle */}
                  <motion.circle
                    cx="100"
                    cy="100"
                    r="95"
                    fill="url(#introSkyGrad)"
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    transition={{ duration: 0.5, ease: 'easeOut' }}
                  />

                  {/* Stars */}
                  {[
                    { cx: 45, cy: 35, r: 2, opacity: 0.8 },
                    { cx: 155, cy: 45, r: 1.5, opacity: 0.7 },
                    { cx: 130, cy: 30, r: 1, opacity: 0.6 },
                    { cx: 70, cy: 50, r: 1.5, opacity: 0.5 },
                  ].map((star, i) => (
                    <motion.circle
                      key={i}
                      cx={star.cx}
                      cy={star.cy}
                      r={star.r}
                      fill="white"
                      initial={{ opacity: 0 }}
                      animate={{ opacity: [0, star.opacity, 0] }}
                      transition={{
                        duration: 1.5,
                        delay: 0.3 + i * 0.1,
                        repeat: Infinity,
                        repeatDelay: 1,
                      }}
                    />
                  ))}

                  {/* Back Mountain */}
                  <motion.path
                    d="M20 160 L70 85 L95 110 L120 70 L170 160 Z"
                    fill="#1e3a5f"
                    opacity="0.6"
                    initial={{ y: 50, opacity: 0 }}
                    animate={{ y: 0, opacity: 0.6 }}
                    transition={{ duration: 0.6, delay: 0.2, ease: 'easeOut' }}
                  />

                  {/* Main Mountain */}
                  <motion.path
                    d="M10 160 L55 95 L75 115 L100 60 L125 115 L145 95 L190 160 Z"
                    fill="url(#introMountainGrad)"
                    initial={{ y: 80, opacity: 0 }}
                    animate={{ y: 0, opacity: 1 }}
                    transition={{ duration: 0.7, delay: 0.3, ease: [0.34, 1.56, 0.64, 1] }}
                  />

                  {/* Snow Cap */}
                  <motion.path
                    d="M70 105 L85 85 L100 60 L115 85 L130 105 L120 100 L110 108 L100 95 L90 108 L80 100 Z"
                    fill="url(#introSnowGrad)"
                    initial={{ opacity: 0, scale: 0.8 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ duration: 0.5, delay: 0.6 }}
                    style={{ transformOrigin: '100px 82px' }}
                  />

                  {/* Snow patches */}
                  <motion.g
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 0.7 }}
                    transition={{ duration: 0.4, delay: 0.8 }}
                  >
                    <path d="M55 130 Q65 120 75 130 Q70 125 55 130" fill="white" />
                    <path d="M125 130 Q135 120 145 130 Q140 125 125 130" fill="white" />
                  </motion.g>

                  {/* Animated Powder Score Ring */}
                  <circle
                    cx="100"
                    cy="100"
                    r="90"
                    fill="none"
                    stroke="white"
                    strokeWidth="3"
                    opacity="0.2"
                  />
                  <motion.path
                    d="M100 10 A90 90 0 0 1 190 100"
                    fill="none"
                    stroke="#22c55e"
                    strokeWidth="4"
                    strokeLinecap="round"
                    filter="url(#glow)"
                    initial={{ pathLength: 0, opacity: 0 }}
                    animate={{ pathLength: 1, opacity: 1 }}
                    transition={{ duration: 1.2, delay: 0.5, ease: 'easeInOut' }}
                  />

                  {/* Animated score pulse */}
                  <motion.circle
                    cx="190"
                    cy="100"
                    r="6"
                    fill="#22c55e"
                    filter="url(#glow)"
                    initial={{ scale: 0, opacity: 0 }}
                    animate={{ scale: [0, 1.5, 1], opacity: [0, 1, 0.8] }}
                    transition={{ duration: 0.5, delay: 1.7 }}
                  />
                </svg>

                {/* Powder score badge */}
                <motion.div
                  className="absolute -right-2 top-1/2 -translate-y-1/2"
                  initial={{ scale: 0, opacity: 0, x: -20 }}
                  animate={{ scale: 1, opacity: 1, x: 0 }}
                  transition={{ duration: 0.5, delay: 1.5, ease: [0.34, 1.56, 0.64, 1] }}
                >
                  <div className="bg-emerald-500/20 backdrop-blur-sm border border-emerald-500/30 rounded-full px-3 py-1 flex items-center gap-1">
                    <span className="text-emerald-400 text-sm font-bold">9.2</span>
                    <span className="text-emerald-400/70 text-xs">POWDER</span>
                  </div>
                </motion.div>
              </motion.div>

              {/* Title */}
              <motion.div
                className="mt-8 text-center"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.6, delay: 0.8 }}
              >
                <h1 className="text-4xl md:text-5xl font-bold tracking-tight">
                  <span className="bg-gradient-to-r from-white via-sky-100 to-white bg-clip-text text-transparent">
                    SHREDDERS
                  </span>
                </h1>
                <motion.p
                  className="text-sky-300/70 mt-2 text-sm tracking-widest uppercase"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ duration: 0.5, delay: 1.2 }}
                >
                  AI-Powered Powder Intelligence
                </motion.p>
              </motion.div>

              {/* Loading indicator */}
              <motion.div
                className="mt-10 flex flex-col items-center gap-3"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ duration: 0.5, delay: 1.5 }}
              >
                <div className="flex gap-1">
                  {[0, 1, 2].map((i) => (
                    <motion.div
                      key={i}
                      className="w-2 h-2 rounded-full bg-sky-400"
                      animate={{
                        scale: [1, 1.5, 1],
                        opacity: [0.3, 1, 0.3],
                      }}
                      transition={{
                        duration: 0.8,
                        repeat: Infinity,
                        delay: i * 0.15,
                      }}
                    />
                  ))}
                </div>
                <span className="text-slate-500 text-xs">Loading conditions...</span>
              </motion.div>

              {/* Skip hint */}
              <motion.p
                className="absolute bottom-8 text-slate-600 text-xs"
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ duration: 0.5, delay: 2.5 }}
              >
                tap anywhere to skip
              </motion.p>
            </div>
          )}

          {/* Aurora effect at bottom */}
          <motion.div
            className="absolute bottom-0 left-0 right-0 h-64 pointer-events-none"
            style={{
              background: 'linear-gradient(180deg, transparent 0%, rgba(14, 165, 233, 0.05) 50%, rgba(34, 197, 94, 0.08) 100%)',
            }}
            animate={{
              opacity: [0.5, 0.8, 0.5],
            }}
            transition={{
              duration: 3,
              repeat: Infinity,
              ease: 'easeInOut',
            }}
          />
        </motion.div>
      )}
    </AnimatePresence>
  );
}

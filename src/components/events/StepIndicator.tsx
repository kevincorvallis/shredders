'use client';

const STEPS = [
  { label: 'Where & When', shortLabel: 'Location' },
  { label: 'Details', shortLabel: 'Details' },
  { label: 'Logistics', shortLabel: 'Logistics' },
  { label: 'Review', shortLabel: 'Review' },
];

interface StepIndicatorProps {
  currentStep: number;
  onStepClick?: (step: number) => void;
  completedSteps?: Set<number>;
}

export function StepIndicator({ currentStep, onStepClick, completedSteps }: StepIndicatorProps) {
  return (
    <div className="flex items-center justify-between w-full max-w-md mx-auto">
      {STEPS.map((step, index) => {
        const isActive = index === currentStep;
        const isCompleted = completedSteps?.has(index) || index < currentStep;
        const isClickable = onStepClick && (isCompleted || index <= currentStep);

        return (
          <div key={index} className="flex items-center flex-1 last:flex-none">
            <button
              type="button"
              onClick={() => isClickable && onStepClick?.(index)}
              disabled={!isClickable}
              className={`flex flex-col items-center gap-1.5 ${isClickable ? 'cursor-pointer' : 'cursor-default'}`}
            >
              <div
                className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-accent text-text-primary'
                    : isCompleted
                      ? 'bg-sky-500/20 text-accent'
                      : 'bg-surface-tertiary text-text-quaternary'
                }`}
              >
                {isCompleted && !isActive ? (
                  <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                ) : (
                  index + 1
                )}
              </div>
              <span
                className={`text-xs hidden sm:block ${
                  isActive ? 'text-accent font-medium' : isCompleted ? 'text-text-tertiary' : 'text-text-quaternary'
                }`}
              >
                {step.shortLabel}
              </span>
            </button>
            {index < STEPS.length - 1 && (
              <div
                className={`flex-1 h-0.5 mx-2 mt-[-1.25rem] sm:mt-[-0.5rem] ${
                  isCompleted ? 'bg-sky-500/40' : 'bg-surface-tertiary'
                }`}
              />
            )}
          </div>
        );
      })}
    </div>
  );
}

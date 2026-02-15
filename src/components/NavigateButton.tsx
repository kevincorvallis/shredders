import { Navigation } from 'lucide-react';

interface NavigateButtonProps {
  lat: number;
  lng: number;
  mountainName: string;
  variant?: 'primary' | 'secondary' | 'icon';
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

export function NavigateButton({
  lat,
  lng,
  mountainName,
  variant = 'primary',
  size = 'md',
  className = '',
}: NavigateButtonProps) {
  const mapsUrl = `https://maps.google.com/maps?daddr=${lat},${lng}`;

  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg',
  };

  const variantClasses = {
    primary:
      'bg-accent hover:bg-accent text-text-primary font-semibold shadow-lg hover:shadow-xl',
    secondary:
      'bg-surface-tertiary hover:bg-surface-tertiary text-text-primary font-medium border border-border-primary',
    icon: 'bg-surface-secondary hover:bg-surface-tertiary text-text-primary p-2',
  };

  if (variant === 'icon') {
    return (
      <a
        href={mapsUrl}
        target="_blank"
        rel="noopener noreferrer"
        className={`inline-flex items-center justify-center rounded-lg transition-all ${variantClasses[variant]} ${className}`}
        title={`Navigate to ${mountainName}`}
      >
        <Navigation className="w-5 h-5" />
      </a>
    );
  }

  return (
    <a
      href={mapsUrl}
      target="_blank"
      rel="noopener noreferrer"
      className={`inline-flex items-center justify-center gap-2 rounded-lg transition-all ${sizeClasses[size]} ${variantClasses[variant]} ${className}`}
    >
      <Navigation className={`${size === 'sm' ? 'w-4 h-4' : size === 'lg' ? 'w-6 h-6' : 'w-5 h-5'}`} />
      <span>Navigate</span>
    </a>
  );
}

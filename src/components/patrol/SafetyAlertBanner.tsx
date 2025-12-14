'use client';

import { useState } from 'react';
import { AlertTriangle, Wind, Snowflake, Thermometer, Eye, ChevronDown, ChevronUp } from 'lucide-react';
import { SEVERITY_STYLES, type Severity } from '@/lib/design-tokens';
import type { SafetyAlert } from '@/lib/calculations/safety-metrics';

interface SafetyAlertBannerProps {
  alerts: SafetyAlert[];
  lastUpdated: string;
}

const alertIcons: Record<SafetyAlert['type'], React.ReactNode> = {
  wind_loading: <Wind className="w-5 h-5" />,
  new_snow: <Snowflake className="w-5 h-5" />,
  warm_temps: <Thermometer className="w-5 h-5" />,
  poor_visibility: <Eye className="w-5 h-5" />,
  wind_chill: <Thermometer className="w-5 h-5" />,
};

export function SafetyAlertBanner({ alerts, lastUpdated }: SafetyAlertBannerProps) {
  const [expanded, setExpanded] = useState(false);

  if (alerts.length === 0) {
    return (
      <div className="bg-emerald-500/10 border border-emerald-500/30 rounded-lg p-4">
        <div className="flex items-center gap-3">
          <div className="p-2 rounded-full bg-emerald-500/20">
            <AlertTriangle className="w-5 h-5 text-emerald-400" />
          </div>
          <div className="flex-1">
            <div className="font-medium text-emerald-400">No Active Alerts</div>
            <div className="text-sm text-slate-400">
              Conditions are favorable. Continue monitoring.
            </div>
          </div>
          <div className="text-xs text-slate-500">
            Updated {new Date(lastUpdated).toLocaleTimeString()}
          </div>
        </div>
      </div>
    );
  }

  // Get highest severity
  const severityOrder: Severity[] = ['extreme', 'high', 'considerable', 'moderate', 'low'];
  const highestSeverity = alerts.reduce((highest, alert) => {
    const currentIndex = severityOrder.indexOf(alert.severity);
    const highestIndex = severityOrder.indexOf(highest);
    return currentIndex < highestIndex ? alert.severity : highest;
  }, 'low' as Severity);

  const style = SEVERITY_STYLES[highestSeverity];
  const primaryAlert = alerts[0];

  return (
    <div className={`${style.bg} border ${style.border} rounded-lg overflow-hidden`}>
      {/* Primary alert */}
      <button
        onClick={() => setExpanded(!expanded)}
        className="w-full p-4 flex items-center gap-3 text-left hover:bg-white/5 transition-colors"
      >
        <div className={`p-2 rounded-full ${style.bg}`}>
          {alertIcons[primaryAlert.type]}
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <span className={`font-semibold ${style.text}`}>{primaryAlert.title}</span>
            <span className={`text-xs px-2 py-0.5 rounded-full ${style.bg} ${style.text}`}>
              {style.label}
            </span>
            {alerts.length > 1 && (
              <span className="text-xs text-slate-400">
                +{alerts.length - 1} more
              </span>
            )}
          </div>
          <div className="text-sm text-slate-300 truncate">
            {primaryAlert.message}
          </div>
        </div>
        <div className="flex items-center gap-2">
          <div className="text-xs text-slate-500">
            {new Date(lastUpdated).toLocaleTimeString()}
          </div>
          {expanded ? (
            <ChevronUp className="w-4 h-4 text-slate-400" />
          ) : (
            <ChevronDown className="w-4 h-4 text-slate-400" />
          )}
        </div>
      </button>

      {/* Expanded alerts */}
      {expanded && alerts.length > 0 && (
        <div className="border-t border-white/10">
          {alerts.map((alert, i) => {
            const alertStyle = SEVERITY_STYLES[alert.severity];
            return (
              <div
                key={i}
                className="p-3 flex items-start gap-3 border-b border-white/5 last:border-b-0"
              >
                <div className={`p-1.5 rounded ${alertStyle.bg}`}>
                  {alertIcons[alert.type]}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className={`font-medium ${alertStyle.text}`}>{alert.title}</span>
                    <span className={`text-[10px] px-1.5 py-0.5 rounded ${alertStyle.bg} ${alertStyle.text}`}>
                      {alertStyle.label}
                    </span>
                  </div>
                  <div className="text-sm text-slate-400 mt-0.5">
                    {alert.message}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

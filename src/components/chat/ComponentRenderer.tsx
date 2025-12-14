'use client';

import {
  PowderScoreWidget,
  ConditionsWidget,
  ForecastWidget,
  ComparisonWidget,
  WebcamWidget,
  ChartWidget,
} from '@/components/widgets';

interface ToolInvocation {
  toolName: string;
  state: 'partial-call' | 'call' | 'result';
  result?: {
    type: string;
    mountain?: string;
    data?: unknown;
    name?: string;
    url?: string;
    refreshUrl?: string;
    chartType?: string;
    days?: number;
    mountains?: unknown[];
  };
}

interface ComponentRendererProps {
  toolInvocations: ToolInvocation[];
}

export function ComponentRenderer({ toolInvocations }: ComponentRendererProps) {
  const completedInvocations = toolInvocations.filter(
    (invocation) => invocation.state === 'result' && invocation.result
  );

  if (completedInvocations.length === 0) {
    // Show loading state for pending tool calls
    const pendingCalls = toolInvocations.filter(
      (invocation) => invocation.state === 'call' || invocation.state === 'partial-call'
    );

    if (pendingCalls.length > 0) {
      return (
        <div className="flex items-center gap-2 text-gray-400 text-sm py-2">
          <div className="animate-spin rounded-full h-4 w-4 border-2 border-gray-600 border-t-gray-400"></div>
          <span>Fetching data...</span>
        </div>
      );
    }

    return null;
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-3 my-3">
      {completedInvocations.map((invocation, index) => {
        const result = invocation.result;
        if (!result) return null;

        switch (result.type) {
          case 'conditions':
            return (
              <ConditionsWidget
                key={index}
                mountain={result.mountain || 'Mt. Baker'}
                data={result.data as Parameters<typeof ConditionsWidget>[0]['data']}
              />
            );

          case 'powder_score':
            return (
              <PowderScoreWidget
                key={index}
                mountain={result.mountain || 'Mt. Baker'}
                data={result.data as Parameters<typeof PowderScoreWidget>[0]['data']}
              />
            );

          case 'forecast':
            return (
              <ForecastWidget
                key={index}
                mountain={result.mountain || 'Mt. Baker'}
                data={result.data as Parameters<typeof ForecastWidget>[0]['data']}
              />
            );

          case 'chart':
            return (
              <ChartWidget
                key={index}
                mountain={result.mountain || 'Mt. Baker'}
                chartType={(result.chartType as 'snow_depth' | 'snowfall') || 'snow_depth'}
                days={result.days || 30}
                data={result.data as Parameters<typeof ChartWidget>[0]['data']}
              />
            );

          case 'webcam':
            return (
              <div key={index} className="md:col-span-2">
                <WebcamWidget
                  mountain={result.mountain || 'Mt. Baker'}
                  name={result.name || 'Chair 8'}
                  url={result.url || ''}
                  refreshUrl={result.refreshUrl}
                />
              </div>
            );

          case 'comparison':
            return (
              <div key={index} className="md:col-span-2">
                <ComparisonWidget
                  mountains={result.mountains as Parameters<typeof ComparisonWidget>[0]['mountains']}
                />
              </div>
            );

          default:
            return null;
        }
      })}
    </div>
  );
}

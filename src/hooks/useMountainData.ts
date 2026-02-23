import useSWR from 'swr';

interface MountainData {
  mountain: {
    id: string;
    name: string;
    shortName: string;
    region: string;
    color: string;
    elevation: { base: number; summit: number };
    location: { lat: number; lng: number };
    website: string;
    webcams: any[];
  };
  conditions: any;
  powderScore: any;
  forecast: any[];
  extendedForecast: any[] | null;
  ensemble: any;
  elevationForecast: any;
  openMeteoDaily: any[];
  sunData: any;
  roads: any;
  tripAdvice: any;
  powderDay: any;
  alerts: any[];
  weatherGovLinks: any;
  status: any;
  cachedAt: string;
}

const fetcher = async (url: string) => {
  const res = await fetch(url);

  if (!res.ok) {
    const error: any = new Error('Failed to fetch mountain data');
    error.status = res.status;
    error.statusText = res.statusText;
    throw error;
  }

  return res.json();
};

export function useMountainData(mountainId: string) {
  const { data, error, isLoading, mutate } = useSWR<MountainData>(
    mountainId ? `/api/mountains/${mountainId}/all` : null,
    fetcher,
    {
      // Don't revalidate on focus (user switching tabs)
      revalidateOnFocus: false,
      // Don't revalidate on reconnect
      revalidateOnReconnect: false,
      // Dedupe requests within 5 minutes
      dedupingInterval: 300000,
      // Keep data fresh for 10 minutes
      refreshInterval: 600000,
      // Show stale data while revalidating
      revalidateIfStale: true,
      // Retry on error
      errorRetryCount: 3,
      errorRetryInterval: 5000,
    }
  );

  return {
    data,
    error,
    isLoading,
    refresh: mutate,
  };
}

/**
 * Prefetch mountain data for faster navigation
 */
export function prefetchMountainData(mountainId: string) {
  return fetcher(`/api/mountains/${mountainId}/all`);
}

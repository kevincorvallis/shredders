import * as Sentry from '@sentry/nextjs';
import { monitoringConfig } from '@/lib/config';

if (monitoringConfig.sentry.enabled) {
  Sentry.init({
    dsn: monitoringConfig.sentry.dsn,
    tracesSampleRate: process.env.NODE_ENV === 'production' ? 0.2 : 1.0,
  });
}

/**
 * Environment Variable Validation
 *
 * Validates all required environment variables at startup
 * Fails fast if configuration is missing or invalid
 */

import { z } from 'zod';

/**
 * Environment variable schema
 * Defines all required and optional environment variables
 */
const envSchema = z.object({
  // ============================================
  // Required Variables
  // ============================================

  // Node Environment
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),

  // JWT Configuration
  JWT_ACCESS_SECRET: z
    .string()
    .min(32, 'JWT_ACCESS_SECRET must be at least 32 characters for security'),
  JWT_REFRESH_SECRET: z
    .string()
    .min(32, 'JWT_REFRESH_SECRET must be at least 32 characters for security')
    .refine((val) => {
      // Ensure refresh secret is different from access secret
      const accessSecret = process.env.JWT_ACCESS_SECRET;
      return !accessSecret || val !== accessSecret;
    }, 'JWT_REFRESH_SECRET must be different from JWT_ACCESS_SECRET'),
  JWT_ACCESS_EXPIRY: z.string().default('15m'),
  JWT_REFRESH_EXPIRY: z.string().default('7d'),

  // Supabase Configuration
  NEXT_PUBLIC_SUPABASE_URL: z.string().url('NEXT_PUBLIC_SUPABASE_URL must be a valid URL'),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1, 'NEXT_PUBLIC_SUPABASE_ANON_KEY is required'),
  SUPABASE_SERVICE_ROLE_KEY: z
    .string()
    .min(1, 'SUPABASE_SERVICE_ROLE_KEY is required')
    .optional(),

  // Application URL
  NEXT_PUBLIC_SITE_URL: z
    .string()
    .url('NEXT_PUBLIC_SITE_URL must be a valid URL')
    .default('http://localhost:3000'),

  // ============================================
  // Optional Variables
  // ============================================

  // Redis (for production rate limiting & caching)
  REDIS_URL: z.string().url().optional(),
  REDIS_TOKEN: z.string().optional(),

  // Monitoring & Error Tracking
  SENTRY_DSN: z.string().url().optional(),
  NEXT_PUBLIC_SENTRY_DSN: z.string().url().optional(),
  SENTRY_ORG: z.string().optional(),
  SENTRY_PROJECT: z.string().optional(),

  // Email Service (for password reset, etc.)
  EMAIL_FROM: z.string().email().optional(),
  EMAIL_SERVER_HOST: z.string().optional(),
  EMAIL_SERVER_PORT: z.string().optional(),
  EMAIL_SERVER_USER: z.string().optional(),
  EMAIL_SERVER_PASSWORD: z.string().optional(),

  // Analytics
  NEXT_PUBLIC_GA_MEASUREMENT_ID: z.string().optional(),
  NEXT_PUBLIC_POSTHOG_KEY: z.string().optional(),

  // Feature Flags
  ENABLE_TOKEN_ROTATION: z
    .string()
    .default('true')
    .transform((val) => val === 'true'),
  ENABLE_MFA: z
    .string()
    .default('false')
    .transform((val) => val === 'true'),
  ENABLE_SESSION_TRACKING: z
    .string()
    .default('true')
    .transform((val) => val === 'true'),

  // Rate Limiting Configuration
  RATE_LIMIT_LOGIN: z.string().optional().default('5'),
  RATE_LIMIT_SIGNUP: z.string().optional().default('3'),
  RATE_LIMIT_REFRESH: z.string().optional().default('10'),
});

/**
 * Validated environment variables
 * Type-safe access to all configuration
 */
export type Config = z.infer<typeof envSchema>;

/**
 * Parse and validate environment variables
 * @throws {Error} If validation fails
 */
function validateEnv(): Config {
  try {
    return envSchema.parse(process.env);
  } catch (error) {
    if (error instanceof z.ZodError) {
      const missingVars = error.issues
        .map((err) => {
          const path = err.path.join('.');
          const message = err.message;
          return `  - ${path}: ${message}`;
        })
        .join('\n');

      console.error('\n❌ Environment variable validation failed:\n');
      console.error(missingVars);
      console.error('\nPlease check your .env.local file and ensure all required variables are set.\n');

      throw new Error('Invalid environment configuration');
    }
    throw error;
  }
}

/**
 * Lazy-loaded configuration cache
 * Prevents validation errors during Next.js build phase
 */
let _config: Config | null = null;

/**
 * Get validated configuration object (lazy initialization)
 * Validates on first access, caches result for subsequent calls
 * This prevents build-time errors when env vars aren't available
 */
function getConfig(): Config {
  if (_config === null) {
    _config = validateEnv();
  }
  return _config;
}

/**
 * Validated configuration object
 * Use this throughout your application for type-safe config access
 * Note: Uses getter for lazy validation - won't throw at import time
 */
export const config: Config = new Proxy({} as Config, {
  get(_, prop: keyof Config) {
    return getConfig()[prop];
  },
  ownKeys() {
    return Reflect.ownKeys(getConfig());
  },
  getOwnPropertyDescriptor(_, prop) {
    return Object.getOwnPropertyDescriptor(getConfig(), prop);
  },
});

/**
 * Helper functions for common config checks
 * These are functions to ensure lazy evaluation (won't fail at build time)
 */
export function isProduction(): boolean {
  return getConfig().NODE_ENV === 'production';
}

export function isDevelopment(): boolean {
  return getConfig().NODE_ENV === 'development';
}

export function isTest(): boolean {
  return getConfig().NODE_ENV === 'test';
}

/**
 * JWT Configuration (lazy-loaded)
 */
export const jwtConfig = {
  get accessSecret() {
    return getConfig().JWT_ACCESS_SECRET;
  },
  get refreshSecret() {
    return getConfig().JWT_REFRESH_SECRET;
  },
  get accessExpiry() {
    return getConfig().JWT_ACCESS_EXPIRY;
  },
  get refreshExpiry() {
    return getConfig().JWT_REFRESH_EXPIRY;
  },
};

/**
 * Supabase Configuration (lazy-loaded)
 */
export const supabaseConfig = {
  get url() {
    return getConfig().NEXT_PUBLIC_SUPABASE_URL;
  },
  get anonKey() {
    return getConfig().NEXT_PUBLIC_SUPABASE_ANON_KEY;
  },
  get serviceRoleKey() {
    return getConfig().SUPABASE_SERVICE_ROLE_KEY;
  },
};

/**
 * Application Configuration (lazy-loaded)
 */
export const appConfig = {
  get siteUrl() {
    return getConfig().NEXT_PUBLIC_SITE_URL;
  },
  get enableTokenRotation() {
    return getConfig().ENABLE_TOKEN_ROTATION;
  },
  get enableMFA() {
    return getConfig().ENABLE_MFA;
  },
  get enableSessionTracking() {
    return getConfig().ENABLE_SESSION_TRACKING;
  },
};

/**
 * Rate Limiting Configuration (lazy-loaded)
 */
export const rateLimitConfig = {
  get login() {
    return parseInt(getConfig().RATE_LIMIT_LOGIN, 10);
  },
  get signup() {
    return parseInt(getConfig().RATE_LIMIT_SIGNUP, 10);
  },
  get refresh() {
    return parseInt(getConfig().RATE_LIMIT_REFRESH, 10);
  },
};

/**
 * Redis Configuration (lazy-loaded)
 */
export const redisConfig = {
  get url() {
    return getConfig().REDIS_URL;
  },
  get token() {
    return getConfig().REDIS_TOKEN;
  },
  get enabled() {
    return !!getConfig().REDIS_URL;
  },
};

/**
 * Monitoring Configuration (lazy-loaded)
 */
export const monitoringConfig = {
  get sentry() {
    const cfg = getConfig();
    const dsn = cfg.SENTRY_DSN || cfg.NEXT_PUBLIC_SENTRY_DSN;
    return {
      dsn,
      org: cfg.SENTRY_ORG,
      project: cfg.SENTRY_PROJECT,
      enabled: !!dsn,
    };
  },
};

/**
 * Print configuration summary (safe - doesn't expose secrets)
 */
export function printConfigSummary() {
  if (isDevelopment()) {
    console.log('\n🔧 Configuration Summary:');
    console.log('  Environment:', config.NODE_ENV);
    console.log('  Site URL:', config.NEXT_PUBLIC_SITE_URL);
    console.log('  Supabase URL:', config.NEXT_PUBLIC_SUPABASE_URL);
    console.log('  JWT Access Expiry:', config.JWT_ACCESS_EXPIRY);
    console.log('  JWT Refresh Expiry:', config.JWT_REFRESH_EXPIRY);
    console.log('  Redis:', redisConfig.enabled ? '✅ Enabled' : '❌ Disabled');
    console.log('  Sentry:', monitoringConfig.sentry.enabled ? '✅ Enabled' : '❌ Disabled');
    console.log('  Token Rotation:', appConfig.enableTokenRotation ? '✅ Enabled' : '❌ Disabled');
    console.log('  Session Tracking:', appConfig.enableSessionTracking ? '✅ Enabled' : '❌ Disabled');
    console.log('  MFA:', appConfig.enableMFA ? '✅ Enabled' : '❌ Disabled');
    console.log('');
  }
}

/**
 * Validate specific security requirements
 */
export function validateSecurityConfig() {
  const warnings: string[] = [];
  const isProd = isProduction();

  // Check JWT secret strength
  if (config.JWT_ACCESS_SECRET.length < 64 && isProd) {
    warnings.push('⚠️  JWT_ACCESS_SECRET should be at least 64 characters in production');
  }

  if (config.JWT_REFRESH_SECRET.length < 64 && isProd) {
    warnings.push('⚠️  JWT_REFRESH_SECRET should be at least 64 characters in production');
  }

  // Check if secrets are the same
  if (config.JWT_ACCESS_SECRET === config.JWT_REFRESH_SECRET) {
    warnings.push('⚠️  JWT secrets should be different for access and refresh tokens');
  }

  // Check HTTPS in production
  if (isProd && !config.NEXT_PUBLIC_SITE_URL.startsWith('https://')) {
    warnings.push('⚠️  NEXT_PUBLIC_SITE_URL should use HTTPS in production');
  }

  // Check Redis in production
  if (isProd && !redisConfig.enabled) {
    warnings.push('⚠️  Redis recommended in production for distributed rate limiting');
  }

  // Check Sentry in production
  if (isProd && !monitoringConfig.sentry.enabled) {
    warnings.push('⚠️  Sentry recommended in production for error monitoring');
  }

  if (warnings.length > 0) {
    console.warn('\n⚠️  Security Configuration Warnings:\n');
    warnings.forEach((warning) => console.warn(warning));
    console.warn('');
  }

  return warnings;
}

// Note: Configuration validation and printing now happens lazily on first access
// to avoid build-time errors when environment variables aren't available.
// Call printConfigSummary() or validateSecurityConfig() explicitly at runtime if needed.

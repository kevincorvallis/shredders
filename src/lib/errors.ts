/**
 * Standardized Error Response System
 *
 * Provides consistent error handling across all API endpoints
 * Includes error codes, classes, and response formatting
 */

import { NextResponse } from 'next/server';

/**
 * Standard error codes for the application
 */
export enum ErrorCode {
  // Authentication errors (1xxx)
  INVALID_CREDENTIALS = 'INVALID_CREDENTIALS',
  TOKEN_EXPIRED = 'TOKEN_EXPIRED',
  TOKEN_INVALID = 'TOKEN_INVALID',
  TOKEN_MISSING = 'TOKEN_MISSING',
  TOKEN_REVOKED = 'TOKEN_REVOKED',
  TOKEN_REUSE_DETECTED = 'TOKEN_REUSE_DETECTED',
  SESSION_REVOKED = 'SESSION_REVOKED',
  SESSION_EXPIRED = 'SESSION_EXPIRED',
  UNAUTHORIZED = 'UNAUTHORIZED',
  FORBIDDEN = 'FORBIDDEN',

  // Validation errors (2xxx)
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  INVALID_EMAIL = 'INVALID_EMAIL',
  INVALID_PASSWORD = 'INVALID_PASSWORD',
  WEAK_PASSWORD = 'WEAK_PASSWORD',
  INVALID_USERNAME = 'INVALID_USERNAME',
  MISSING_FIELD = 'MISSING_FIELD',
  INVALID_FORMAT = 'INVALID_FORMAT',

  // Rate limiting errors (3xxx)
  RATE_LIMIT_EXCEEDED = 'RATE_LIMIT_EXCEEDED',
  TOO_MANY_REQUESTS = 'TOO_MANY_REQUESTS',
  TOO_MANY_LOGIN_ATTEMPTS = 'TOO_MANY_LOGIN_ATTEMPTS',
  TOO_MANY_SIGNUP_ATTEMPTS = 'TOO_MANY_SIGNUP_ATTEMPTS',

  // Resource errors (4xxx)
  NOT_FOUND = 'NOT_FOUND',
  USER_NOT_FOUND = 'USER_NOT_FOUND',
  RESOURCE_NOT_FOUND = 'RESOURCE_NOT_FOUND',
  ALREADY_EXISTS = 'ALREADY_EXISTS',
  EMAIL_ALREADY_EXISTS = 'EMAIL_ALREADY_EXISTS',
  USERNAME_TAKEN = 'USERNAME_TAKEN',

  // Server errors (5xxx)
  INTERNAL_ERROR = 'INTERNAL_ERROR',
  DATABASE_ERROR = 'DATABASE_ERROR',
  EXTERNAL_SERVICE_ERROR = 'EXTERNAL_SERVICE_ERROR',
  CONFIGURATION_ERROR = 'CONFIGURATION_ERROR',

  // Account errors (6xxx)
  ACCOUNT_DISABLED = 'ACCOUNT_DISABLED',
  ACCOUNT_LOCKED = 'ACCOUNT_LOCKED',
  EMAIL_NOT_VERIFIED = 'EMAIL_NOT_VERIFIED',
}

/**
 * Standard error response format
 */
export interface ErrorResponse {
  error: {
    code: ErrorCode;
    message: string;
    details?: Record<string, any> | string[];
    timestamp: string;
    requestId?: string;
  };
}

/**
 * Base application error class
 */
export class AppError extends Error {
  public readonly code: ErrorCode;
  public readonly statusCode: number;
  public readonly details?: Record<string, any> | string[];
  public readonly isOperational: boolean;

  constructor(
    code: ErrorCode,
    message: string,
    statusCode: number = 500,
    details?: Record<string, any> | string[],
    isOperational: boolean = true
  ) {
    super(message);
    this.code = code;
    this.statusCode = statusCode;
    this.details = details;
    this.isOperational = isOperational;

    // Maintains proper stack trace for where error was thrown
    Error.captureStackTrace(this, this.constructor);
    Object.setPrototypeOf(this, AppError.prototype);
  }

  toJSON(): ErrorResponse {
    return {
      error: {
        code: this.code,
        message: this.message,
        details: this.details,
        timestamp: new Date().toISOString(),
      },
    };
  }
}

/**
 * Authentication error
 */
export class AuthError extends AppError {
  constructor(
    code: ErrorCode,
    message: string,
    details?: Record<string, any> | string[]
  ) {
    super(code, message, 401, details);
    Object.setPrototypeOf(this, AuthError.prototype);
  }
}

/**
 * Validation error
 */
export class ValidationError extends AppError {
  constructor(message: string, details?: string[]) {
    super(ErrorCode.VALIDATION_ERROR, message, 400, details);
    Object.setPrototypeOf(this, ValidationError.prototype);
  }
}

/**
 * Rate limit error
 */
export class RateLimitError extends AppError {
  public readonly retryAfter?: number;

  constructor(message: string, retryAfter?: number) {
    super(ErrorCode.RATE_LIMIT_EXCEEDED, message, 429, { retryAfter });
    this.retryAfter = retryAfter;
    Object.setPrototypeOf(this, RateLimitError.prototype);
  }
}

/**
 * Not found error
 */
export class NotFoundError extends AppError {
  constructor(resource: string = 'Resource') {
    super(ErrorCode.NOT_FOUND, `${resource} not found`, 404);
    Object.setPrototypeOf(this, NotFoundError.prototype);
  }
}

/**
 * Database error
 */
export class DatabaseError extends AppError {
  constructor(message: string = 'Database operation failed', details?: Record<string, any>) {
    super(ErrorCode.DATABASE_ERROR, message, 500, details, false);
    Object.setPrototypeOf(this, DatabaseError.prototype);
  }
}

/**
 * Helper function to create error responses
 */
export function createErrorResponse(
  error: AppError | Error,
  requestId?: string
): NextResponse<ErrorResponse> {
  if (error instanceof AppError) {
    const response = error.toJSON();
    if (requestId) {
      response.error.requestId = requestId;
    }

    const headers: Record<string, string> = {};
    if (error instanceof RateLimitError && error.retryAfter) {
      headers['Retry-After'] = error.retryAfter.toString();
    }

    return NextResponse.json(response, {
      status: error.statusCode,
      headers: Object.keys(headers).length > 0 ? headers : undefined,
    });
  }

  // Unknown error - don't expose internals
  return NextResponse.json(
    {
      error: {
        code: ErrorCode.INTERNAL_ERROR,
        message: 'An unexpected error occurred',
        timestamp: new Date().toISOString(),
        requestId,
      },
    },
    { status: 500 }
  );
}

/**
 * Specific error factory functions
 */
export const Errors = {
  // Authentication
  invalidCredentials: () =>
    new AuthError(
      ErrorCode.INVALID_CREDENTIALS,
      'Email or password is incorrect'
    ),

  tokenExpired: () =>
    new AuthError(ErrorCode.TOKEN_EXPIRED, 'Access token has expired'),

  tokenInvalid: () =>
    new AuthError(ErrorCode.TOKEN_INVALID, 'Token is invalid or malformed'),

  tokenMissing: () =>
    new AuthError(ErrorCode.TOKEN_MISSING, 'No authentication token provided'),

  tokenRevoked: () =>
    new AuthError(ErrorCode.TOKEN_REVOKED, 'Token has been revoked'),

  tokenReuseDetected: () =>
    new AuthError(
      ErrorCode.TOKEN_REUSE_DETECTED,
      'Token reuse detected. All sessions have been revoked for security.'
    ),

  sessionRevoked: () =>
    new AuthError(ErrorCode.SESSION_REVOKED, 'Session has been revoked'),

  unauthorized: (message: string = 'Unauthorized access') =>
    new AuthError(ErrorCode.UNAUTHORIZED, message),

  forbidden: (message: string = 'Access forbidden') =>
    new AppError(ErrorCode.FORBIDDEN, message, 403),

  // Validation
  validationFailed: (details: string[]) =>
    new ValidationError('Validation failed', details),

  invalidEmail: () =>
    new ValidationError('Invalid email address format', ['email']),

  weakPassword: (requirements: string[]) =>
    new ValidationError('Password does not meet requirements', requirements),

  invalidUsername: (message: string = 'Username contains invalid characters') =>
    new ValidationError(message, ['username']),

  missingField: (field: string) =>
    new ValidationError(`Missing required field: ${field}`, [field]),

  // Rate limiting
  rateLimitExceeded: (retryAfter: number, endpoint?: string) =>
    new RateLimitError(
      endpoint
        ? `Too many ${endpoint} attempts. Please try again in ${retryAfter} seconds.`
        : `Too many requests. Please try again in ${retryAfter} seconds.`,
      retryAfter
    ),

  tooManyLoginAttempts: (retryAfter: number) =>
    new RateLimitError(
      `Too many login attempts. Please try again in ${retryAfter} seconds.`,
      retryAfter
    ),

  // Resources
  userNotFound: () =>
    new NotFoundError('User'),

  resourceNotFound: (resource: string) =>
    new NotFoundError(resource),

  emailAlreadyExists: () =>
    new AppError(
      ErrorCode.EMAIL_ALREADY_EXISTS,
      'An account with this email already exists',
      409
    ),

  usernameAlreadyExists: () =>
    new AppError(
      ErrorCode.USERNAME_TAKEN,
      'This username is already taken',
      409
    ),

  // Server
  internalError: (message: string = 'An unexpected error occurred') =>
    new AppError(ErrorCode.INTERNAL_ERROR, message, 500, undefined, false),

  databaseError: (details?: Record<string, any>) =>
    new DatabaseError('Database operation failed', details),

  configurationError: (message: string) =>
    new AppError(ErrorCode.CONFIGURATION_ERROR, message, 500, undefined, false),

  // Account
  accountDisabled: () =>
    new AppError(
      ErrorCode.ACCOUNT_DISABLED,
      'This account has been disabled',
      403
    ),

  accountLocked: (reason?: string) =>
    new AppError(
      ErrorCode.ACCOUNT_LOCKED,
      reason || 'This account has been temporarily locked',
      403
    ),
};

/**
 * Error handler middleware helper
 */
export function handleError(
  error: unknown,
  context?: { userId?: string; endpoint?: string }
): NextResponse<ErrorResponse> {
  // Log error for monitoring
  if (error instanceof AppError) {
    if (!error.isOperational) {
      // Log non-operational errors (bugs, system failures)
      console.error('[CRITICAL ERROR]', {
        code: error.code,
        message: error.message,
        stack: error.stack,
        context,
      });
    } else {
      // Log operational errors (expected errors like validation)
      console.warn('[OPERATIONAL ERROR]', {
        code: error.code,
        message: error.message,
        context,
      });
    }

    return createErrorResponse(error);
  }

  // Unknown error type
  console.error('[UNEXPECTED ERROR]', {
    error,
    context,
  });

  return createErrorResponse(
    Errors.internalError('An unexpected error occurred')
  );
}

/**
 * Type guard for AppError
 */
export function isAppError(error: unknown): error is AppError {
  return error instanceof AppError;
}

/**
 * Extract error message from unknown error
 */
export function getErrorMessage(error: unknown): string {
  if (error instanceof AppError) {
    return error.message;
  }
  if (error instanceof Error) {
    return error.message;
  }
  if (typeof error === 'string') {
    return error;
  }
  return 'An unexpected error occurred';
}

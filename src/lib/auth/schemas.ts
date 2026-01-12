/**
 * Zod Validation Schemas for Authentication
 *
 * Type-safe input validation for all auth endpoints
 * Prevents injection attacks and ensures data integrity
 */

import { z } from 'zod';

// ============================================
// Login Schema
// ============================================
export const loginSchema = z.object({
  email: z
    .string({ required_error: 'Email is required' })
    .email('Invalid email format')
    .max(255, 'Email must be less than 255 characters')
    .toLowerCase()
    .trim(),
  password: z
    .string({ required_error: 'Password is required' })
    .min(8, 'Password must be at least 8 characters')
    .max(128, 'Password must be less than 128 characters'),
});

export type LoginInput = z.infer<typeof loginSchema>;

// ============================================
// Signup Schema
// ============================================
export const signupSchema = z.object({
  email: z
    .string({ required_error: 'Email is required' })
    .email('Invalid email format')
    .max(255, 'Email must be less than 255 characters')
    .toLowerCase()
    .trim(),
  password: z
    .string({ required_error: 'Password is required' })
    .min(12, 'Password must be at least 12 characters')
    .max(128, 'Password must be less than 128 characters')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
    .regex(/[0-9]/, 'Password must contain at least one number')
    .regex(/[^A-Za-z0-9]/, 'Password must contain at least one special character'),
  username: z
    .string({ required_error: 'Username is required' })
    .min(3, 'Username must be at least 3 characters')
    .max(20, 'Username must be less than 20 characters')
    .regex(
      /^[a-zA-Z0-9_]+$/,
      'Username can only contain letters, numbers, and underscores'
    )
    .trim(),
  displayName: z
    .string()
    .min(1, 'Display name must not be empty')
    .max(50, 'Display name must be less than 50 characters')
    .trim()
    .optional(),
});

export type SignupInput = z.infer<typeof signupSchema>;

// ============================================
// Token Refresh Schema
// ============================================
export const refreshSchema = z.object({
  refreshToken: z
    .string({ required_error: 'Refresh token is required' })
    .min(1, 'Refresh token cannot be empty'),
});

export type RefreshInput = z.infer<typeof refreshSchema>;

// ============================================
// Profile Update Schema
// ============================================
export const updateProfileSchema = z.object({
  displayName: z
    .string()
    .min(1, 'Display name must not be empty')
    .max(50, 'Display name must be less than 50 characters')
    .trim()
    .optional(),
  bio: z
    .string()
    .max(500, 'Bio must be less than 500 characters')
    .trim()
    .optional(),
  avatarUrl: z
    .string()
    .url('Invalid avatar URL')
    .optional()
    .or(z.literal('')), // Allow empty string to remove avatar
  location: z
    .string()
    .max(100, 'Location must be less than 100 characters')
    .trim()
    .optional(),
});

export type UpdateProfileInput = z.infer<typeof updateProfileSchema>;

// ============================================
// Comment Schema
// ============================================
export const createCommentSchema = z.object({
  content: z
    .string({ required_error: 'Comment content is required' })
    .min(1, 'Comment cannot be empty')
    .max(2000, 'Comment must be less than 2000 characters')
    .trim(),
  mountainId: z.string().uuid('Invalid mountain ID').optional(),
  webcamId: z.string().uuid('Invalid webcam ID').optional(),
  photoId: z.string().uuid('Invalid photo ID').optional(),
  checkInId: z.string().uuid('Invalid check-in ID').optional(),
  parentCommentId: z.string().uuid('Invalid parent comment ID').optional(),
}).refine(
  (data) => data.mountainId || data.webcamId || data.photoId || data.checkInId,
  {
    message: 'At least one target (mountainId, webcamId, photoId, or checkInId) is required',
  }
);

export type CreateCommentInput = z.infer<typeof createCommentSchema>;

// ============================================
// Check-in Schema
// ============================================
export const createCheckInSchema = z.object({
  mountainId: z
    .string({ required_error: 'Mountain ID is required' })
    .uuid('Invalid mountain ID'),
  checkInTime: z
    .string()
    .datetime('Invalid check-in time')
    .optional(),
  checkOutTime: z
    .string()
    .datetime('Invalid check-out time')
    .optional(),
  tripReport: z
    .string()
    .max(5000, 'Trip report must be less than 5000 characters')
    .trim()
    .optional(),
  rating: z
    .number()
    .int('Rating must be an integer')
    .min(1, 'Rating must be at least 1')
    .max(5, 'Rating must be at most 5')
    .optional(),
  snowQuality: z
    .string()
    .max(50, 'Snow quality must be less than 50 characters')
    .optional(),
  crowdLevel: z
    .string()
    .max(50, 'Crowd level must be less than 50 characters')
    .optional(),
  weatherConditions: z
    .record(z.any())
    .optional(),
  isPublic: z
    .boolean()
    .default(true)
    .optional(),
});

export type CreateCheckInInput = z.infer<typeof createCheckInSchema>;

// ============================================
// Like Schema
// ============================================
export const createLikeSchema = z.object({
  photoId: z.string().uuid('Invalid photo ID').optional(),
  commentId: z.string().uuid('Invalid comment ID').optional(),
  checkInId: z.string().uuid('Invalid check-in ID').optional(),
  webcamId: z.string().uuid('Invalid webcam ID').optional(),
}).refine(
  (data) => data.photoId || data.commentId || data.checkInId || data.webcamId,
  {
    message: 'At least one target (photoId, commentId, checkInId, or webcamId) is required',
  }
);

export type CreateLikeInput = z.infer<typeof createLikeSchema>;

// ============================================
// Validation Helper Function
// ============================================

/**
 * Validate request data against a Zod schema
 *
 * @param schema - Zod schema to validate against
 * @param data - Data to validate
 * @returns Validation result with parsed data or errors
 *
 * @example
 * const result = validateRequest(loginSchema, requestBody);
 * if (!result.success) {
 *   return NextResponse.json({ error: result.errors }, { status: 400 });
 * }
 * const { email, password } = result.data;
 */
export function validateRequest<T>(
  schema: z.ZodSchema<T>,
  data: unknown
): { success: true; data: T } | { success: false; errors: string[] } {
  try {
    const parsed = schema.parse(data);
    return { success: true, data: parsed };
  } catch (error) {
    if (error instanceof z.ZodError) {
      const errors = error.errors.map((err) => {
        const path = err.path.join('.');
        return path ? `${path}: ${err.message}` : err.message;
      });
      return { success: false, errors };
    }
    return { success: false, errors: ['Validation failed'] };
  }
}

/**
 * Validate request data and return formatted error response
 *
 * @param schema - Zod schema to validate against
 * @param data - Data to validate
 * @returns Parsed data if valid, or throws formatted error
 *
 * @example
 * const { email, password } = validateOrThrow(loginSchema, requestBody);
 */
export function validateOrThrow<T>(schema: z.ZodSchema<T>, data: unknown): T {
  const result = validateRequest(schema, data);
  if (!result.success) {
    throw new Error(result.errors.join(', '));
  }
  return result.data;
}

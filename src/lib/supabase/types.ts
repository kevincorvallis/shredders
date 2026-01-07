/**
 * Supabase Database Types
 *
 * TypeScript types for all database tables, views, and functions.
 * These types provide autocomplete and type safety when querying Supabase.
 *
 * To regenerate these types, run:
 *   npx supabase gen types typescript --project-id nmkavdrvgjkolreoexfe > src/lib/supabase/types.ts
 */

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export interface Database {
  public: {
    Tables: {
      users: {
        Row: {
          id: string
          auth_user_id: string | null
          username: string
          email: string
          display_name: string | null
          avatar_url: string | null
          bio: string | null
          home_mountain_id: string | null
          created_at: string
          updated_at: string
          last_login_at: string | null
          is_active: boolean
          notification_preferences: Json
        }
        Insert: {
          id?: string
          auth_user_id?: string | null
          username: string
          email: string
          display_name?: string | null
          avatar_url?: string | null
          bio?: string | null
          home_mountain_id?: string | null
          created_at?: string
          updated_at?: string
          last_login_at?: string | null
          is_active?: boolean
          notification_preferences?: Json
        }
        Update: {
          id?: string
          auth_user_id?: string | null
          username?: string
          email?: string
          display_name?: string | null
          avatar_url?: string | null
          bio?: string | null
          home_mountain_id?: string | null
          created_at?: string
          updated_at?: string
          last_login_at?: string | null
          is_active?: boolean
          notification_preferences?: Json
        }
      }
      user_photos: {
        Row: {
          id: string
          user_id: string
          mountain_id: string
          storage_path: string
          storage_bucket: string
          public_url: string | null
          thumbnail_url: string | null
          caption: string | null
          taken_at: string | null
          uploaded_at: string
          file_size_bytes: number | null
          mime_type: string | null
          width: number | null
          height: number | null
          is_approved: boolean
          is_flagged: boolean
          moderation_status: string
          likes_count: number
          comments_count: number
          location_name: string | null
        }
        Insert: {
          id?: string
          user_id: string
          mountain_id: string
          storage_path: string
          storage_bucket?: string
          public_url?: string | null
          thumbnail_url?: string | null
          caption?: string | null
          taken_at?: string | null
          uploaded_at?: string
          file_size_bytes?: number | null
          mime_type?: string | null
          width?: number | null
          height?: number | null
          is_approved?: boolean
          is_flagged?: boolean
          moderation_status?: string
          likes_count?: number
          comments_count?: number
          location_name?: string | null
        }
        Update: {
          id?: string
          user_id?: string
          mountain_id?: string
          storage_path?: string
          storage_bucket?: string
          public_url?: string | null
          thumbnail_url?: string | null
          caption?: string | null
          taken_at?: string | null
          uploaded_at?: string
          file_size_bytes?: number | null
          mime_type?: string | null
          width?: number | null
          height?: number | null
          is_approved?: boolean
          is_flagged?: boolean
          moderation_status?: string
          likes_count?: number
          comments_count?: number
          location_name?: string | null
        }
      }
      comments: {
        Row: {
          id: string
          user_id: string
          mountain_id: string | null
          webcam_id: string | null
          photo_id: string | null
          content: string
          created_at: string
          updated_at: string | null
          parent_comment_id: string | null
          is_flagged: boolean
          is_deleted: boolean
          likes_count: number
        }
        Insert: {
          id?: string
          user_id: string
          mountain_id?: string | null
          webcam_id?: string | null
          photo_id?: string | null
          content: string
          created_at?: string
          updated_at?: string | null
          parent_comment_id?: string | null
          is_flagged?: boolean
          is_deleted?: boolean
          likes_count?: number
        }
        Update: {
          id?: string
          user_id?: string
          mountain_id?: string | null
          webcam_id?: string | null
          photo_id?: string | null
          content?: string
          created_at?: string
          updated_at?: string | null
          parent_comment_id?: string | null
          is_flagged?: boolean
          is_deleted?: boolean
          likes_count?: number
        }
      }
      check_ins: {
        Row: {
          id: string
          user_id: string
          mountain_id: string
          check_in_time: string
          check_out_time: string | null
          trip_report: string | null
          rating: number | null
          snow_quality: string | null
          crowd_level: string | null
          weather_conditions: Json | null
          likes_count: number
          comments_count: number
          is_public: boolean
        }
        Insert: {
          id?: string
          user_id: string
          mountain_id: string
          check_in_time?: string
          check_out_time?: string | null
          trip_report?: string | null
          rating?: number | null
          snow_quality?: string | null
          crowd_level?: string | null
          weather_conditions?: Json | null
          likes_count?: number
          comments_count?: number
          is_public?: boolean
        }
        Update: {
          id?: string
          user_id?: string
          mountain_id?: string
          check_in_time?: string
          check_out_time?: string | null
          trip_report?: string | null
          rating?: number | null
          snow_quality?: string | null
          crowd_level?: string | null
          weather_conditions?: Json | null
          likes_count?: number
          comments_count?: number
          is_public?: boolean
        }
      }
      likes: {
        Row: {
          id: string
          user_id: string
          photo_id: string | null
          comment_id: string | null
          check_in_id: string | null
          webcam_id: string | null
          created_at: string
        }
        Insert: {
          id?: string
          user_id: string
          photo_id?: string | null
          comment_id?: string | null
          check_in_id?: string | null
          webcam_id?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          photo_id?: string | null
          comment_id?: string | null
          check_in_id?: string | null
          webcam_id?: string | null
          created_at?: string
        }
      }
      push_notification_tokens: {
        Row: {
          id: string
          user_id: string
          device_token: string
          platform: string
          device_id: string | null
          is_active: boolean
          last_used_at: string
          created_at: string
          app_version: string | null
          os_version: string | null
        }
        Insert: {
          id?: string
          user_id: string
          device_token: string
          platform: string
          device_id?: string | null
          is_active?: boolean
          last_used_at?: string
          created_at?: string
          app_version?: string | null
          os_version?: string | null
        }
        Update: {
          id?: string
          user_id?: string
          device_token?: string
          platform?: string
          device_id?: string | null
          is_active?: boolean
          last_used_at?: string
          created_at?: string
          app_version?: string | null
          os_version?: string | null
        }
      }
      alert_subscriptions: {
        Row: {
          id: string
          user_id: string
          mountain_id: string
          weather_alerts: boolean
          powder_alerts: boolean
          powder_threshold: number
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          mountain_id: string
          weather_alerts?: boolean
          powder_alerts?: boolean
          powder_threshold?: number
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          mountain_id?: string
          weather_alerts?: boolean
          powder_alerts?: boolean
          powder_threshold?: number
          created_at?: string
          updated_at?: string
        }
      }
      mountain_status: {
        Row: {
          id: string
          mountain_id: string
          is_open: boolean | null
          percent_open: number | null
          lifts_open: number | null
          lifts_total: number | null
          runs_open: number | null
          runs_total: number | null
          message: string | null
          conditions_message: string | null
          scraped_at: string
          source_url: string | null
          scraper_version: string | null
          created_at: string
        }
        Insert: {
          id?: string
          mountain_id: string
          is_open?: boolean | null
          percent_open?: number | null
          lifts_open?: number | null
          lifts_total?: number | null
          runs_open?: number | null
          runs_total?: number | null
          message?: string | null
          conditions_message?: string | null
          scraped_at?: string
          source_url?: string | null
          scraper_version?: string | null
          created_at?: string
        }
        Update: {
          id?: string
          mountain_id?: string
          is_open?: boolean | null
          percent_open?: number | null
          lifts_open?: number | null
          lifts_total?: number | null
          runs_open?: number | null
          runs_total?: number | null
          message?: string | null
          conditions_message?: string | null
          scraped_at?: string
          source_url?: string | null
          scraper_version?: string | null
          created_at?: string
        }
      }
      scraper_runs: {
        Row: {
          id: string
          run_id: string
          total_mountains: number | null
          successful_count: number
          failed_count: number
          started_at: string
          completed_at: string | null
          duration_ms: number | null
          status: string
          error_message: string | null
          triggered_by: string | null
          environment: string | null
        }
        Insert: {
          id?: string
          run_id: string
          total_mountains?: number | null
          successful_count?: number
          failed_count?: number
          started_at?: string
          completed_at?: string | null
          duration_ms?: number | null
          status?: string
          error_message?: string | null
          triggered_by?: string | null
          environment?: string | null
        }
        Update: {
          id?: string
          run_id?: string
          total_mountains?: number | null
          successful_count?: number
          failed_count?: number
          started_at?: string
          completed_at?: string | null
          duration_ms?: number | null
          status?: string
          error_message?: string | null
          triggered_by?: string | null
          environment?: string | null
        }
      }
    }
    Views: {
      latest_mountain_status: {
        Row: {
          id: string | null
          mountain_id: string | null
          is_open: boolean | null
          percent_open: number | null
          lifts_open: number | null
          lifts_total: number | null
          runs_open: number | null
          runs_total: number | null
          message: string | null
          conditions_message: string | null
          scraped_at: string | null
          source_url: string | null
        }
      }
      mountain_recent_activity: {
        Row: {
          mountain_id: string | null
          activity_type: string | null
          id: string | null
          user_id: string | null
          activity_time: string | null
          likes_count: number | null
          comments_count: number | null
        }
      }
    }
    Functions: {
      get_mountain_history: {
        Args: {
          p_mountain_id: string
          p_days: number
        }
        Returns: {
          scraped_at: string
          lifts_open: number
          runs_open: number
          message: string
        }[]
      }
      cleanup_old_mountain_status: {
        Args: {}
        Returns: number
      }
    }
  }
}

//
//  SupabaseClientManager.swift
//  PowderTracker
//
//  Shared SupabaseClient singleton to prevent duplicate connections.
//  All services should use this instead of creating their own instances.
//

import Foundation
import Supabase

/// Singleton manager for the shared SupabaseClient instance.
/// Using a single client reduces network connections from 9 to 1,
/// saves memory from duplicate auth state, and eliminates redundant WebSocket connections.
@MainActor
final class SupabaseClientManager {
    static let shared = SupabaseClientManager()

    let client: SupabaseClient

    private init() {
        guard let url = URL(string: AppConfig.supabaseURL) else {
            fatalError("Invalid Supabase URL: \(AppConfig.supabaseURL)")
        }
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: AppConfig.supabaseAnonKey
        )
    }
}

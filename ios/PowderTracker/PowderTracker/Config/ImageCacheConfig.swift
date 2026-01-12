//
//  ImageCacheConfig.swift
//  PowderTracker
//
//  Created by Claude Code
//

import Nuke
import NukeUI
import UIKit

/// Configuration for Nuke image caching system
/// Provides optimized memory and disk cache settings for photo/webcam images
class ImageCacheConfig {

    /// Configure Nuke image pipeline with optimized cache settings
    static func configure() {
        // Memory cache: 150MB
        // Suitable for 30-50 high-res images in memory
        ImageCache.shared.costLimit = 1024 * 1024 * 150

        // Count limit: 100 images
        ImageCache.shared.countLimit = 100

        // Disk cache: 500MB for offline support
        // Allows caching of ~500-1000 images depending on resolution
        DataLoader.sharedUrlCache.diskCapacity = 1024 * 1024 * 500

        // Memory cache for disk: 50MB
        DataLoader.sharedUrlCache.memoryCapacity = 1024 * 1024 * 50

        // Use data cache pipeline for persistent storage
        // This enables aggressive disk caching for offline viewing
        var configuration = ImagePipeline.Configuration.withDataCache

        // Optimize for aggressive caching
        configuration.dataCachePolicy = .automatic

        // Enable decompression in background
        configuration.isDecompressionEnabled = true

        // Progressive decoding for large images
        configuration.isProgressiveDecodingEnabled = true

        // Create and set the pipeline
        ImagePipeline.shared = ImagePipeline(configuration: configuration)

        print("✅ Nuke ImageCache configured: Memory=\(ImageCache.shared.costLimit / 1024 / 1024)MB, Disk=\(DataLoader.sharedUrlCache.diskCapacity / 1024 / 1024)MB")
    }

    /// Reduce cache limits for older devices with less memory
    static func configureForLowMemoryDevice() {
        ImageCache.shared.costLimit = 1024 * 1024 * 75 // 75MB
        ImageCache.shared.countLimit = 50

        print("⚠️ Low memory device detected - reduced cache to 75MB")
    }

    /// Clear all image caches (memory + disk)
    static func clearAllCaches() {
        ImageCache.shared.removeAll()
        ImagePipeline.shared.cache.removeAll()
        DataLoader.sharedUrlCache.removeAllCachedResponses()

        print("🗑️ All image caches cleared")
    }
}

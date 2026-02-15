//
//  ProfileView.swift
//  PowderTracker
//
//  Modern profile view with glassmorphism design.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthService.self) private var authService
    @ObservedObject private var favoritesManager = FavoritesService.shared
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var activeSheet: ProfileSheet?
    @State private var showingSignOutConfirmation = false
    @State private var isSigningOut = false

    private enum ProfileSheet: Identifiable {
        case settings, login, manageFavorites, alertPreferences
        case regionPicker, passPicker, unitsSettings, about
        case snowHistory, weatherAlerts

        var id: String { String(describing: self) }
    }

    // User preferences from AppStorage
    @AppStorage("homeRegion") private var homeRegion = "washington"
    @AppStorage("seasonPass") private var seasonPass = "none"
    @AppStorage("selectedMountainId") private var selectedMountainId = "baker"
    @AppStorage("temperatureUnit") private var temperatureUnit = "F"
    @AppStorage("distanceUnit") private var distanceUnit = "mi"
    
    // Animation states
    @State private var headerScale: CGFloat = 0.9
    @State private var headerOpacity: Double = 0
    @State private var sectionsOffset: CGFloat = 30
    @State private var sectionsOpacity: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic gradient background
                backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: .spacingL) {
                        // User header section
                        userHeaderSection
                            .scaleEffect(headerScale)
                            .opacity(headerOpacity)

                        // Content sections
                        VStack(spacing: .spacingL) {
                            yourMountainsSection
                            alertsSection
                            toolsSection
                            externalResourcesSection
                            appSettingsSection
                        }
                        .offset(y: sectionsOffset)
                        .opacity(sectionsOpacity)
                    }
                    .padding(.horizontal, .spacingL)
                    .padding(.vertical, .spacingM)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if authService.isAuthenticated {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            activeSheet = .settings
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .settings:
                    ProfileSettingsView()
                case .login:
                    UnifiedAuthView()
                        .environment(authService)
                case .manageFavorites:
                    FavoritesManagementSheet()
                case .regionPicker:
                    RegionPickerView()
                case .passPicker:
                    SeasonPassPickerView()
                case .unitsSettings:
                    UnitsSettingsView()
                case .about:
                    AboutView()
                case .snowHistory:
                    NavigationStack {
                        HistoryChartContainer()
                            .navigationTitle("Snow History")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .confirmationAction) {
                                    Button("Done") {
                                        activeSheet = nil
                                    }
                                }
                            }
                    }
                case .weatherAlerts:
                    WeatherAlertsSettingsView()
                case .alertPreferences:
                    PushNotificationSetupView()
                }
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $showingSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    isSigningOut = true
                    HapticFeedback.medium.trigger()
                    Task {
                        do {
                            try await authService.signOut()
                        } catch {
                            HapticFeedback.error.trigger()
                        }
                        isSigningOut = false
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .allowsHitTesting(!isSigningOut)
            .overlay {
                if isSigningOut {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.2)
                        }
                        .transition(.opacity)
                }
            }
            .animation(.smooth(duration: 0.2), value: isSigningOut)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    headerScale = 1.0
                    headerOpacity = 1.0
                    sectionsOffset = 0
                    sectionsOpacity = 1.0
                }
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(white: 0.08), Color(white: 0.12), Color(white: 0.08)]
                : [Color(white: 0.96), Color(white: 0.94), Color(white: 0.98)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Computed Properties

    private var appVersion: String { Bundle.main.appVersion }

    private var unitsSubtitle: String {
        let temp = temperatureUnit == "F" ? "°F" : "°C"
        let dist = distanceUnit == "mi" ? "miles" : "km"
        return "\(temp), \(dist)"
    }

    // MARK: - User Header Section

    @ViewBuilder
    private var userHeaderSection: some View {
        if authService.isAuthenticated, let profile = authService.userProfile {
            // Authenticated user header with glass design
            VStack(spacing: .spacingL) {
                // Avatar with glow
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.pookieCyan.opacity(0.4), .clear],
                                center: .center,
                                startRadius: 30,
                                endRadius: 70
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                    
                    // Avatar
                    ProfileAvatarView(profile: profile, size: 100)
                }
                
                VStack(spacing: .spacingXS) {
                    Text(profile.displayName ?? profile.username)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("@\(profile.username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Riding style badge
                    if let ridingStyle = profile.ridingStyleEnum {
                        RidingStyleBadge(style: ridingStyle, showLabel: true)
                            .padding(.top, .spacingXS)
                    }
                }

                // Quick stats in glass pills
                HStack(spacing: .spacingM) {
                    ProfileStatPill(value: "\(favoritesManager.favoriteIds.count)", label: "Mountains", icon: "mountain.2.fill")
                }
            }
            .padding(.spacingXL)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusHero))
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusHero)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        } else {
            // Not logged in state with glass design
            VStack(spacing: .spacingL) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.pookiePurple.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: 15)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pookieCyan, .pookiePurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(spacing: .spacingS) {
                    Text("Sign in for full features")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Track your photos, check-ins, and activity")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    activeSheet = .login
                } label: {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.spacingM)
                    .background(
                        LinearGradient(
                            colors: [.pookieCyan, .pookiePurple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusButton))
                }
                .accessibilityIdentifier("profile_sign_in_button")
            }
            .padding(.spacingXL)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusHero))
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusHero)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        }
    }

    // MARK: - Your Mountains Section

    private var yourMountainsSection: some View {
        ProfileGlassSection(title: "Your Mountains", icon: "mountain.2.fill") {
            VStack(spacing: 0) {
                ProfileGlassRow(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Favorites",
                    subtitle: "\(favoritesManager.favoriteIds.count) mountains"
                ) {
                    activeSheet = .manageFavorites
                }
                .accessibilityIdentifier("profile_favorites_row")

                Divider().padding(.leading, 52)

                ProfileGlassRow(
                    icon: "location.fill",
                    iconColor: .blue,
                    title: "Home Region",
                    subtitle: HomeRegion(rawValue: homeRegion)?.displayName ?? "Not Set"
                ) {
                    activeSheet = .regionPicker
                }
                .accessibilityIdentifier("profile_region_row")

                Divider().padding(.leading, 52)

                ProfileGlassRow(
                    icon: "ticket.fill",
                    iconColor: .purple,
                    title: "Season Pass",
                    subtitle: SeasonPassType(rawValue: seasonPass)?.displayName ?? "No Pass"
                ) {
                    activeSheet = .passPicker
                }
                .accessibilityIdentifier("profile_pass_row")
            }
        }
    }

    // MARK: - Alerts Section

    private var alertsSection: some View {
        ProfileGlassSection(title: "Alerts & Notifications", icon: "bell.badge.fill") {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.red)
                        .frame(width: 32, height: 32)
                        .background(.red.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text("Push Notifications")
                        .font(.body)

                    Spacer()

                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                        .tint(.pookieCyan)
                }
                .padding(.spacingM)

                Divider().padding(.leading, 52)

                ProfileGlassRow(
                    icon: "snowflake",
                    iconColor: .cyan,
                    title: "Powder Alerts",
                    subtitle: "Get notified for 6\"+ days"
                ) {
                    activeSheet = .alertPreferences
                }

                Divider().padding(.leading, 52)

                ProfileGlassRow(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    title: "Weather Alerts",
                    subtitle: "Storms, road closures"
                ) {
                    activeSheet = .weatherAlerts
                }
            }
        }
    }

    // MARK: - Tools Section

    private var toolsSection: some View {
        ProfileGlassSection(title: "Tools", icon: "wrench.and.screwdriver.fill") {
            VStack(spacing: 0) {
                ProfileGlassRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .cyan,
                    title: "Snow History",
                    subtitle: "View historical snowfall data"
                ) {
                    activeSheet = .snowHistory
                }
            }
        }
    }

    // MARK: - External Resources Section

    private var externalResourcesSection: some View {
        ProfileGlassSection(title: "Resources", icon: "link") {
            VStack(spacing: 0) {
                ProfileGlassRow(
                    icon: "mountain.2.fill",
                    iconColor: .blue,
                    title: "NWAC Avalanche Center",
                    subtitle: "Avalanche forecasts & education"
                ) {
                    if let url = URL(string: "https://nwac.us") {
                        UIApplication.shared.open(url)
                    }
                }

                Divider().padding(.leading, 52)

                ProfileGlassRow(
                    icon: "car.fill",
                    iconColor: .green,
                    title: "WSDOT Pass Reports",
                    subtitle: "Road conditions & closures"
                ) {
                    if let url = URL(string: "https://wsdot.wa.gov/travel/real-time/mountainpasses") {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }

    // MARK: - App Settings Section

    private var appSettingsSection: some View {
        ProfileGlassSection(title: "Settings", icon: "gearshape.fill") {
            VStack(spacing: 0) {
                ProfileGlassRow(
                    icon: "ruler",
                    iconColor: .gray,
                    title: "Units",
                    subtitle: unitsSubtitle
                ) {
                    activeSheet = .unitsSettings
                }

                Divider().padding(.leading, 52)

                ProfileGlassRow(
                    icon: "info.circle.fill",
                    iconColor: .blue,
                    title: "About PowderTracker",
                    subtitle: "Version \(appVersion)"
                ) {
                    activeSheet = .about
                }

                if authService.isAuthenticated {
                    Divider().padding(.leading, 52)

                    Button {
                        HapticFeedback.light.trigger()
                        showingSignOutConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .font(.system(size: 18))
                                .foregroundStyle(.red)
                                .frame(width: 32, height: 32)
                                .background(.red.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            Text("Sign Out")
                                .font(.body)
                                .foregroundStyle(.red)

                            Spacer()
                        }
                        .padding(.spacingM)
                    }
                    .accessibilityIdentifier("profile_sign_out_button")
                }
            }
        }
    }
}

// MARK: - Profile Avatar View

private struct ProfileAvatarView: View {
    let profile: UserProfile
    let size: CGFloat
    
    var body: some View {
        let initial = String(profile.displayName?.first ?? profile.username.first ?? "?").uppercased()
        
        ZStack {
            if let avatarUrl = profile.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        ProfileAvatarPlaceholder(initial: initial, size: size)
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    @unknown default:
                        ProfileAvatarPlaceholder(initial: initial, size: size)
                    }
                }
            } else {
                ProfileAvatarPlaceholder(initial: initial, size: size)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .white.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        )
    }
}

private struct ProfileAvatarPlaceholder: View {
    let initial: String
    let size: CGFloat
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.pookieCyan, .pookiePurple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Text(initial)
                    .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
    }
}

// MARK: - Profile Stat Pill

private struct ProfileStatPill: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: .spacingXS) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, .spacingM)
        .padding(.vertical, .spacingS)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusSmall))
    }
}

// MARK: - Profile Glass Section

private struct ProfileGlassSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            // Section header
            HStack(spacing: .spacingS) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, .spacingS)
            
            // Glass card content
            content
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusCard))
                .overlay(
                    RoundedRectangle(cornerRadius: .cornerRadiusCard)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

// MARK: - Profile Glass Row

private struct ProfileGlassRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(.spacingM)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ProfileView()
        .environment(AuthService.shared)
}

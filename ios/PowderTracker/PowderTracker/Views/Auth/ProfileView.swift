import SwiftUI

struct ProfileView: View {
    @Environment(AuthService.self) private var authService
    @StateObject private var favoritesManager = FavoritesService.shared
    @State private var showingSettings = false
    @State private var showingLogin = false
    @State private var showingManageFavorites = false
    @State private var showingAlertPreferences = false
    @State private var showingSignOutConfirmation = false

    // New sheet states
    @State private var showingRegionPicker = false
    @State private var showingPassPicker = false
    @State private var showingUnitsSettings = false
    @State private var showingAbout = false
    @State private var showingChat = false
    @State private var showingSnowHistory = false
    @State private var showingPatrolReports = false
    @State private var showingWeatherAlerts = false

    // User preferences from AppStorage
    @AppStorage("homeRegion") private var homeRegion = "washington"
    @AppStorage("seasonPass") private var seasonPass = "none"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingL) {
                    // User header section (conditional on auth state)
                    userHeaderSection

                    // Your Mountains section
                    yourMountainsSection

                    // Alerts & Notifications section
                    alertsSection

                    // Tools section
                    toolsSection

                    // External Resources section
                    externalResourcesSection

                    // App Settings section
                    appSettingsSection
                }
                .padding(.horizontal, .spacingL)
                .padding(.vertical, .spacingM)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if authService.isAuthenticated {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                ProfileSettingsView()
            }
            .sheet(isPresented: $showingLogin) {
                UnifiedAuthView()
            }
            .sheet(isPresented: $showingManageFavorites) {
                FavoritesManagementSheet()
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $showingSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await authService.signOut()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            // New sheets
            .sheet(isPresented: $showingRegionPicker) {
                RegionPickerView()
            }
            .sheet(isPresented: $showingPassPicker) {
                SeasonPassPickerView()
            }
            .sheet(isPresented: $showingUnitsSettings) {
                UnitsSettingsView()
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingChat) {
                NavigationStack {
                    ChatView()
                }
            }
            .sheet(isPresented: $showingSnowHistory) {
                NavigationStack {
                    HistoryChartContainer()
                        .navigationTitle("Snow History")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showingSnowHistory = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingPatrolReports) {
                NavigationStack {
                    PatrolView()
                }
            }
            .sheet(isPresented: $showingWeatherAlerts) {
                WeatherAlertsSettingsView()
            }
        }
    }

    // MARK: - Computed Properties

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    @AppStorage("temperatureUnit") private var temperatureUnit = "F"
    @AppStorage("distanceUnit") private var distanceUnit = "mi"

    private var unitsSubtitle: String {
        let temp = temperatureUnit == "F" ? "°F" : "°C"
        let dist = distanceUnit == "mi" ? "miles" : "km"
        return "\(temp), \(dist)"
    }

    // MARK: - User Header Section

    @ViewBuilder
    private var userHeaderSection: some View {
        if authService.isAuthenticated, let profile = authService.userProfile {
            // Authenticated user header
            VStack(spacing: .spacingM) {
                // Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay {
                        Text(String(profile.displayName?.first ?? profile.username.first ?? "?").uppercased())
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                    }

                VStack(spacing: 4) {
                    Text(profile.displayName ?? profile.username)
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("@\(profile.username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Quick stats
                HStack(spacing: .spacingXL) {
                    statItem(value: "0", label: "Photos")
                    statItem(value: "0", label: "Check-ins")
                    statItem(value: "\(favoritesManager.favoriteIds.count)", label: "Mountains")
                }
                .padding(.spacingM)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(.cornerRadiusCard)
            }
            .padding(.spacingL)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusHero)
        } else {
            // Not logged in state
            VStack(spacing: .spacingM) {
                Image(systemName: "person.circle")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)

                Text("Sign in for full features")
                    .font(.headline)

                Text("Track your photos, check-ins, and activity")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    showingLogin = true
                } label: {
                    Text("Sign In")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(.cornerRadiusButton)
                }
                .accessibilityIdentifier("profile_sign_in_button")
                .padding(.top, .spacingS)
            }
            .padding(.spacingL)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusHero)
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Your Mountains Section

    private var yourMountainsSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            SectionHeaderView(title: "Your Mountains")

            VStack(spacing: 0) {
                // Favorites row
                profileRow(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Favorites",
                    subtitle: "\(favoritesManager.favoriteIds.count) mountains"
                ) {
                    showingManageFavorites = true
                }

                Divider().padding(.leading, 44)

                // Home region row
                profileRow(
                    icon: "location.fill",
                    iconColor: .blue,
                    title: "Home Region",
                    subtitle: HomeRegion(rawValue: homeRegion)?.displayName ?? "Not Set"
                ) {
                    showingRegionPicker = true
                }

                Divider().padding(.leading, 44)

                // Pass type row
                profileRow(
                    icon: "ticket.fill",
                    iconColor: .purple,
                    title: "Season Pass",
                    subtitle: SeasonPassType(rawValue: seasonPass)?.displayName ?? "No Pass"
                ) {
                    showingPassPicker = true
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
        }
    }

    // MARK: - Alerts Section

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            SectionHeaderView(title: "Alerts & Notifications")

            VStack(spacing: 0) {
                // Push notifications toggle
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                        .frame(width: 28, height: 28)

                    Text("Push Notifications")
                        .font(.body)

                    Spacer()

                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                }
                .padding(.spacingM)

                Divider().padding(.leading, 44)

                // Powder alerts
                profileRow(
                    icon: "snowflake",
                    iconColor: .blue,
                    title: "Powder Alerts",
                    subtitle: "Get notified for 6\"+ days"
                ) {
                    showingAlertPreferences = true
                }

                Divider().padding(.leading, 44)

                // Weather alerts
                profileRow(
                    icon: "exclamationmark.triangle.fill",
                    iconColor: .orange,
                    title: "Weather Alerts",
                    subtitle: "Storms, road closures"
                ) {
                    showingWeatherAlerts = true
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
        }
    }

    // MARK: - Tools Section

    private var toolsSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            SectionHeaderView(title: "Tools")

            VStack(spacing: 0) {
                // Chat
                profileRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    iconColor: .green,
                    title: "Powder Chat",
                    subtitle: "Get AI-powered recommendations"
                ) {
                    showingChat = true
                }

                Divider().padding(.leading, 44)

                // Snow history
                profileRow(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .cyan,
                    title: "Snow History",
                    subtitle: "View historical snowfall data"
                ) {
                    showingSnowHistory = true
                }

                Divider().padding(.leading, 44)

                // Patrol reports
                profileRow(
                    icon: "cross.fill",
                    iconColor: .red,
                    title: "Ski Patrol Reports",
                    subtitle: "View incident and safety reports"
                ) {
                    showingPatrolReports = true
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
        }
    }

    // MARK: - External Resources Section

    private var externalResourcesSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            SectionHeaderView(title: "Resources")

            VStack(spacing: 0) {
                // NWAC
                profileRow(
                    icon: "mountain.2.fill",
                    iconColor: .blue,
                    title: "NWAC Avalanche Center",
                    subtitle: "Avalanche forecasts & education"
                ) {
                    if let url = URL(string: "https://nwac.us") {
                        UIApplication.shared.open(url)
                    }
                }

                Divider().padding(.leading, 44)

                // WSDOT
                profileRow(
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
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
        }
    }

    // MARK: - App Settings Section

    private var appSettingsSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            SectionHeaderView(title: "Settings")

            VStack(spacing: 0) {
                // Units
                profileRow(
                    icon: "ruler",
                    iconColor: .gray,
                    title: "Units",
                    subtitle: unitsSubtitle
                ) {
                    showingUnitsSettings = true
                }

                Divider().padding(.leading, 44)

                // About
                profileRow(
                    icon: "info.circle.fill",
                    iconColor: .blue,
                    title: "About PowderTracker",
                    subtitle: "Version \(appVersion)"
                ) {
                    showingAbout = true
                }

                if authService.isAuthenticated {
                    Divider().padding(.leading, 44)

                    // Sign out
                    Button {
                        showingSignOutConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                                .frame(width: 28, height: 28)

                            Text("Sign Out")
                                .font(.body)
                                .foregroundColor(.red)

                            Spacer()
                        }
                        .padding(.spacingM)
                    }
                    .accessibilityIdentifier("profile_sign_out_button")
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
        }
    }

    // MARK: - Helper Views

    private func profileRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.spacingM)
        }
    }
}

#Preview {
    ProfileView()
        .environment(AuthService.shared)
}

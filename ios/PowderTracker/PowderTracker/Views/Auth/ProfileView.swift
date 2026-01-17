import SwiftUI

struct ProfileView: View {
    @Environment(AuthService.self) private var authService
    @State private var showingSettings = false
    @State private var showingLogin = false

    var body: some View {
        NavigationStack {
            ScrollView {
                if authService.isAuthenticated, let profile = authService.userProfile {
                    VStack(spacing: 24) {
                        // Profile header
                        VStack(spacing: 16) {
                            // Avatar
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay {
                                    Text(String(profile.displayName?.first ?? profile.username.first ?? "?").uppercased())
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundStyle(.white)
                                }

                            VStack(spacing: 4) {
                                Text(profile.displayName ?? profile.username)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                                    .multilineTextAlignment(.center)

                                Text("@\(profile.username)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }

                            if let bio = profile.bio {
                                Text(bio)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                                    .padding(.horizontal)
                            }

                            // Stats
                            HStack(spacing: 32) {
                                VStack(spacing: 4) {
                                    Text("0")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Text("Photos")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }

                                VStack(spacing: 4) {
                                    Text("0")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Text("Check-ins")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }

                                VStack(spacing: 4) {
                                    Text("0")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Text("Comments")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                            Button {
                                showingSettings = true
                            } label: {
                                Text("Edit Profile")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                        .padding()

                        // Tabs
                        VStack(spacing: 0) {
                            // Tab bar
                            HStack(spacing: 0) {
                                TabButton(title: "Photos", isSelected: true)
                                TabButton(title: "Check-ins", isSelected: false)
                                TabButton(title: "Activity", isSelected: false)
                            }
                            .frame(height: 44)

                            Divider()

                            // Content
                            VStack(spacing: 16) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("No photos yet")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.9)
                                Text("Upload your first photo from a webcam or mountain page")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 80)
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                } else {
                    // Not logged in state
                    VStack(spacing: 20) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 80))
                            .foregroundStyle(.secondary)

                        Text("Sign in to view your profile")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)

                        Text("Create an account to track your photos, check-ins, and activity")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal)

                        Button {
                            showingLogin = true
                        } label: {
                            Text("Sign In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                    }
                    .padding(.top, 100)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingSettings) {
                ProfileSettingsView()
            }
            .sheet(isPresented: $showingLogin) {
                UnifiedAuthView()
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Button {
            // Tab selection action
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .primary : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    VStack {
                        Spacer()
                        if isSelected {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(height: 2)
                        }
                    }
                )
        }
    }
}

#Preview {
    ProfileView()
        .environment(AuthService.shared)
}

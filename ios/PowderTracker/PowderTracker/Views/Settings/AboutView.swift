//
//  AboutView.swift
//  PowderTracker
//
//  About screen with app info, credits, and links.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingXL) {
                    // App Icon & Name
                    appHeader

                    // About Section
                    aboutSection

                    // Links Section
                    linksSection

                    // Credits Section
                    creditsSection

                    // Legal Section
                    legalSection
                }
                .padding(.spacingL)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - App Header

    private var appHeader: some View {
        VStack(spacing: .spacingM) {
            // App icon
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: "snowflake")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(.white)
                }
                .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)

            VStack(spacing: 4) {
                Text("PowderTracker")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, .spacingL)
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            sectionHeader("About")

            VStack(alignment: .leading, spacing: .spacingM) {
                Text("PowderTracker helps you find the best powder days at ski resorts across the Pacific Northwest and beyond.")
                    .font(.body)
                    .foregroundStyle(.primary)

                Text("Track conditions, get powder alerts, plan trips with friends, and never miss a deep day again.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.spacingM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
        }
    }

    // MARK: - Links Section

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            sectionHeader("Links")

            VStack(spacing: 0) {
                linkRow(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Rate on App Store",
                    subtitle: "Help us improve"
                ) {
                    // App Store link would go here
                    if let url = URL(string: "https://apps.apple.com") {
                        UIApplication.shared.open(url)
                    }
                }

                Divider().padding(.leading, 44)

                linkRow(
                    icon: "envelope.fill",
                    iconColor: .blue,
                    title: "Contact Support",
                    subtitle: "Bug reports & suggestions"
                ) {
                    if let url = URL(string: "mailto:contact@aclsolutions.io") {
                        UIApplication.shared.open(url)
                    }
                }

                Divider().padding(.leading, 44)

                linkRow(
                    icon: "globe",
                    iconColor: .green,
                    title: "Website",
                    subtitle: "aclsolutions.io"
                ) {
                    if let url = URL(string: "https://aclsolutions.io/shredders") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
        }
    }

    // MARK: - Credits Section

    private var creditsSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            sectionHeader("Credits")

            VStack(alignment: .leading, spacing: .spacingM) {
                creditItem(title: "Created by", value: "Kevin & Beryl")
                creditItem(title: "Weather Data", value: "OpenWeatherMap, RainViewer")
                creditItem(title: "Avalanche Data", value: "NWAC, Avalanche.org")
                creditItem(title: "Icons", value: "SF Symbols")
            }
            .padding(.spacingM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            sectionHeader("Legal")

            VStack(spacing: 0) {
                linkRow(
                    icon: "doc.text.fill",
                    iconColor: .gray,
                    title: "Privacy Policy",
                    subtitle: nil
                ) {
                    if let url = URL(string: "https://aclsolutions.io/privacy.html") {
                        UIApplication.shared.open(url)
                    }
                }

                Divider().padding(.leading, 44)

                linkRow(
                    icon: "doc.text.fill",
                    iconColor: .gray,
                    title: "Terms of Service",
                    subtitle: nil
                ) {
                    if let url = URL(string: "https://aclsolutions.io/terms.html") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)

            Text("© 2025 ACL Solutions. All rights reserved.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.top, .spacingM)
        }
    }

    // MARK: - Helper Views

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }

    private func creditItem(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    private func linkRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String?,
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

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
    AboutView()
}

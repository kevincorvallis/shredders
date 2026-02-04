//
//  AboutView.swift
//  PowderTracker
//
//  Interactive About screen with app info, PowderScore explanation, and usage guide.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedSection: AboutSection = .powderScore
    @State private var animatePowderScore = false
    @State private var showFactorDetail: PowderScoreFactorInfo? = nil
    @State private var demoScore: Double = 7.5
    @State private var expandedTip: String? = nil

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
                    // App Header with animated icon
                    appHeader

                    // Section Picker
                    sectionPicker

                    // Content based on selection
                    switch selectedSection {
                    case .powderScore:
                        powderScoreSection
                    case .howToUse:
                        howToUseSection
                    case .features:
                        featuresSection
                    case .about:
                        aboutUsSection
                    }
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
        .sheet(item: $showFactorDetail) { factor in
            FactorDetailSheet(factor: factor)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - App Header

    private var appHeader: some View {
        VStack(spacing: .spacingM) {
            // Animated app icon
            ZStack {
                // Gradient background
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LinearGradient.pookieBSnow)
                    .frame(width: 100, height: 100)
                    .shadow(color: .pookiePurple.opacity(0.4), radius: 12, y: 6)

                // Snowflake with animation
                AnimatedSnowflakeIcon(size: 50, color: .white)
            }
            .scaleEffect(animatePowderScore ? 1.0 : 0.9)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    animatePowderScore = true
                }
            }

            VStack(spacing: 4) {
                Text("PowderTracker")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("Never miss a powder day again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .italic()
        }
        .padding(.vertical, .spacingL)
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingS) {
                ForEach(AboutSection.allCases) { section in
                    Button {
                        HapticFeedback.light.trigger()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedSection = section
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: section.icon)
                                .font(.subheadline)
                            Text(section.title)
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(.horizontal, .spacingM)
                        .padding(.vertical, .spacingS)
                        .background {
                            if selectedSection == section {
                                Capsule()
                                    .fill(LinearGradient.powderBlue)
                            } else {
                                Capsule()
                                    .fill(Color(.secondarySystemBackground))
                            }
                        }
                        .foregroundStyle(selectedSection == section ? .white : .primary)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Powder Score Section

    private var powderScoreSection: some View {
        VStack(alignment: .leading, spacing: .spacingL) {
            // Interactive Score Demo
            interactiveScoreDemo

            // How It's Calculated
            VStack(alignment: .leading, spacing: .spacingS) {
                sectionHeader("How It's Calculated")

                Text("The PowderScore is a proprietary algorithm that combines real-time data from multiple sources to give you a single number (1-10) representing powder conditions.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.spacingM)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(.cornerRadiusCard)
            }

            // Factor Breakdown
            VStack(alignment: .leading, spacing: .spacingS) {
                sectionHeader("The Algorithm")

                VStack(spacing: 0) {
                    ForEach(PowderScoreFactorInfo.allFactors) { factor in
                        Button {
                            HapticFeedback.light.trigger()
                            showFactorDetail = factor
                        } label: {
                            factorRow(factor)
                        }

                        if factor.id != PowderScoreFactorInfo.allFactors.last?.id {
                            Divider().padding(.leading, 52)
                        }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(.cornerRadiusCard)
            }

            // Data Sources
            VStack(alignment: .leading, spacing: .spacingS) {
                sectionHeader("Data Sources")

                VStack(alignment: .leading, spacing: .spacingM) {
                    dataSourceRow(
                        icon: "sensor.fill",
                        color: .cyan,
                        name: "SNOTEL",
                        description: "Real-time snow depth & snowfall from NRCS sensors"
                    )
                    dataSourceRow(
                        icon: "cloud.fill",
                        color: .blue,
                        name: "NOAA/NWS",
                        description: "Weather forecasts, wind, temperature, and storm alerts"
                    )
                    dataSourceRow(
                        icon: "thermometer.medium",
                        color: .orange,
                        name: "Open-Meteo",
                        description: "Freezing level and rain risk calculations"
                    )
                    dataSourceRow(
                        icon: "mountain.2.fill",
                        color: .green,
                        name: "Resort APIs",
                        description: "Lift status, terrain, and operating hours"
                    )
                }
                .padding(.spacingM)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(.cornerRadiusCard)
            }
        }
    }

    private var interactiveScoreDemo: some View {
        VStack(spacing: .spacingM) {
            Text("Try It Out")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: .spacingL) {
                // Animated gauge
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 14)

                    Circle()
                        .trim(from: 0, to: demoScore / 10)
                        .stroke(
                            LinearGradient.forScore(demoScore),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: demoScore)

                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", demoScore))
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.forPowderScore(demoScore))
                            .contentTransition(.numericText())

                        Text(scoreLabel(for: demoScore))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .animation(.none, value: demoScore)
                    }
                }
                .frame(width: 140, height: 140)

                // Slider
                VStack(spacing: 4) {
                    Slider(value: $demoScore, in: 1...10, step: 0.1)
                        .tint(Color.forPowderScore(demoScore))

                    HStack {
                        Text("Skip It")
                            .font(.caption2)
                            .foregroundStyle(.red)
                        Spacer()
                        Text("Send It!")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }
                .padding(.horizontal, .spacingM)

                Text("Drag the slider to see how score changes translate to conditions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.spacingL)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusHero)
        }
    }

    private func factorRow(_ factor: PowderScoreFactorInfo) -> some View {
        HStack(spacing: .spacingM) {
            // Icon
            ZStack {
                Circle()
                    .fill(factor.color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: factor.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(factor.color)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(factor.name)
                        .font(.body)
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(Int(factor.weight * 100))%")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(factor.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(factor.color.opacity(0.15))
                        .clipShape(Capsule())
                }

                Text(factor.shortDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary.opacity(0.5))
        }
        .padding(.spacingM)
        .contentShape(Rectangle())
    }

    private func dataSourceRow(icon: String, color: Color, name: String, description: String) -> some View {
        HStack(spacing: .spacingM) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - How To Use Section

    private var howToUseSection: some View {
        VStack(alignment: .leading, spacing: .spacingL) {
            ForEach(UsageTip.allTips) { tip in
                usageTipCard(tip)
            }
        }
    }

    private func usageTipCard(_ tip: UsageTip) -> some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            Button {
                HapticFeedback.light.trigger()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if expandedTip == tip.id {
                        expandedTip = nil
                    } else {
                        expandedTip = tip.id
                    }
                }
            } label: {
                HStack(spacing: .spacingM) {
                    // Step number
                    ZStack {
                        Circle()
                            .fill(LinearGradient.powderBlue)
                            .frame(width: 36, height: 36)

                        Text("\(tip.step)")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(tip.title)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        if expandedTip != tip.id {
                            Text(tip.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: expandedTip == tip.id ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            if expandedTip == tip.id {
                VStack(alignment: .leading, spacing: .spacingS) {
                    Text(tip.description)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    if let proTip = tip.proTip {
                        HStack(alignment: .top, spacing: .spacingS) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                            Text("Pro Tip: \(proTip)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.spacingS)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(.cornerRadiusMicro)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: .spacingL) {
            ForEach(AppFeature.allFeatures) { feature in
                featureCard(feature)
            }
        }
    }

    private func featureCard(_ feature: AppFeature) -> some View {
        HStack(alignment: .top, spacing: .spacingM) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(feature.gradient)
                    .frame(width: 48, height: 48)

                Image(systemName: feature.icon)
                    .font(.title3)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.name)
                    .font(.headline)

                Text(feature.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let badge = feature.badge {
                    Text(badge)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(feature.gradient)
                        .clipShape(Capsule())
                        .padding(.top, 4)
                }
            }
        }
        .padding(.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    // MARK: - About Us Section

    private var aboutUsSection: some View {
        VStack(alignment: .leading, spacing: .spacingL) {
            // Story
            VStack(alignment: .leading, spacing: .spacingS) {
                sectionHeader("Our Story")

                VStack(alignment: .leading, spacing: .spacingM) {
                    Text("PowderTracker was born from countless mornings spent refreshing weather apps, checking webcams, and scrolling through reports just to figure out if it was worth making the drive to the mountain.")

                    Text("We built the app we wished existed: one that combines all the data sources, crunches the numbers, and gives you a simple answer—is today a powder day?")

                    Text("Made with love in the Pacific Northwest, where the snow falls deep and the coffee is strong. ☕️❄️")
                        .italic()
                }
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.spacingM)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(.cornerRadiusCard)
            }

            // Credits
            VStack(alignment: .leading, spacing: .spacingS) {
                sectionHeader("Credits")

                VStack(alignment: .leading, spacing: .spacingM) {
                    creditItem(title: "Created by", value: "Kevin & Beryl")
                    creditItem(title: "Chief Morale Officer", value: "Brock 🐕")
                    creditItem(title: "Weather Data", value: "NOAA, SNOTEL, Open-Meteo")
                    creditItem(title: "Avalanche Data", value: "NWAC, Avalanche.org")
                    creditItem(title: "Icons", value: "SF Symbols")
                }
                .padding(.spacingM)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(.cornerRadiusCard)
            }

            // Links
            VStack(alignment: .leading, spacing: .spacingS) {
                sectionHeader("Connect")

                VStack(spacing: 0) {
                    linkRow(
                        icon: "star.fill",
                        iconColor: .yellow,
                        title: "Rate on App Store",
                        subtitle: "Help us improve"
                    ) {
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

            // Legal
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

    private func scoreLabel(for score: Double) -> String {
        switch score {
        case 9...10: return "EPIC!"
        case 8..<9: return "Excellent"
        case 7..<8: return "Great"
        case 6..<7: return "Good"
        case 5..<6: return "Decent"
        case 4..<5: return "Fair"
        case 3..<4: return "Meh"
        default: return "Skip It"
        }
    }
}

// MARK: - Supporting Types

enum AboutSection: String, CaseIterable, Identifiable {
    case powderScore = "score"
    case howToUse = "guide"
    case features = "features"
    case about = "about"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .powderScore: return "PowderScore"
        case .howToUse: return "How to Use"
        case .features: return "Features"
        case .about: return "About Us"
        }
    }

    var icon: String {
        switch self {
        case .powderScore: return "gauge.with.dots.needle.67percent"
        case .howToUse: return "book.fill"
        case .features: return "sparkles"
        case .about: return "info.circle.fill"
        }
    }
}

struct PowderScoreFactorInfo: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let weight: Double
    let shortDescription: String
    let longDescription: String
    let scoring: [(range: String, score: String, description: String)]

    static let allFactors: [PowderScoreFactorInfo] = [
        PowderScoreFactorInfo(
            id: "snowfall",
            name: "24h Snowfall",
            icon: "cloud.snow.fill",
            color: .cyan,
            weight: 0.24,
            shortDescription: "Fresh snow in the last 24 hours",
            longDescription: "The most important factor. Fresh snow is what makes a powder day. We measure actual snowfall from SNOTEL sensors at or near the resort.",
            scoring: [
                ("12\"+", "10/10", "Epic conditions - drop everything!"),
                ("6-12\"", "8/10", "Great powder day"),
                ("3-6\"", "6/10", "Good refresh, worth the trip"),
                ("1-3\"", "4/10", "Light dusting"),
                ("0\"", "0/10", "No new snow")
            ]
        ),
        PowderScoreFactorInfo(
            id: "density",
            name: "Snow Density",
            icon: "snowflake",
            color: .blue,
            weight: 0.18,
            shortDescription: "Light powder vs heavy/wet",
            longDescription: "Not all snow is created equal. Cold, dry snow creates that floating-on-clouds feeling. We estimate density from temperature and humidity.",
            scoring: [
                ("<25°F, Low humidity", "10/10", "Champagne powder!"),
                ("25-32°F, Moderate humidity", "8/10", "Light, fluffy"),
                ("28-32°F, 70-80% humidity", "5/10", "Medium density"),
                (">32°F or >85% humidity", "2/10", "Heavy, wet, cement-like")
            ]
        ),
        PowderScoreFactorInfo(
            id: "freshness",
            name: "Freshness",
            icon: "clock.fill",
            color: .purple,
            weight: 0.18,
            shortDescription: "How recently the snow fell",
            longDescription: "Snow that fell overnight is untouched. Snow from 2 days ago? Probably tracked out. We compare 24h vs 48h accumulation to estimate timing.",
            scoring: [
                ("Falling now / overnight", "10/10", "First tracks territory"),
                ("6-12 hours ago", "8/10", "Still plenty of stashes"),
                ("12-24 hours ago", "6/10", "Some untouched terrain"),
                ("24-48 hours ago", "4/10", "Mostly tracked"),
                ("48+ hours ago", "2/10", "Old snow")
            ]
        ),
        PowderScoreFactorInfo(
            id: "wind",
            name: "Wind Speed",
            icon: "wind",
            color: .gray,
            weight: 0.10,
            shortDescription: "Affects snow quality & lift operations",
            longDescription: "Strong winds blow powder into wind-loaded pockets or scour it off entirely. They can also close lifts. We factor in both sustained wind and gusts.",
            scoring: [
                ("<5 mph", "10/10", "Perfect - snow stays where it falls"),
                ("5-15 mph", "7/10", "Light wind, creates nice deposits"),
                ("15-25 mph", "4/10", "Moderate - some wind effect"),
                (">25 mph", "1/10", "Strong - lift closures likely")
            ]
        ),
        PowderScoreFactorInfo(
            id: "temperature",
            name: "Temperature",
            icon: "thermometer.medium",
            color: .orange,
            weight: 0.0875,
            shortDescription: "Affects snow preservation",
            longDescription: "Colder temps keep powder light and prevent the surface from getting crusty. But too cold can mean less moisture = less snow.",
            scoring: [
                ("<15°F", "10/10", "Cold & dry - powder preserved"),
                ("15-25°F", "8/10", "Ideal skiing temps"),
                ("25-32°F", "5/10", "Good but snow may settle"),
                (">32°F", "2/10", "Above freezing - may rain")
            ]
        ),
        PowderScoreFactorInfo(
            id: "base",
            name: "Base Depth",
            icon: "arrow.down.to.line.alt",
            color: .green,
            weight: 0.045,
            shortDescription: "Overall snow coverage",
            longDescription: "A deep base means better coverage of obstacles and opens up more terrain. Early or late season, shallow base = limited terrain.",
            scoring: [
                ("72\"+", "10/10", "Deep - everything open"),
                ("48-72\"", "8/10", "Good coverage"),
                ("24-48\"", "6/10", "Moderate - watch for obstacles"),
                ("<24\"", "3/10", "Thin - limited terrain")
            ]
        ),
        PowderScoreFactorInfo(
            id: "crowd",
            name: "Crowd Level",
            icon: "person.3.fill",
            color: .red,
            weight: 0.0525,
            shortDescription: "Expected crowds based on day/time",
            longDescription: "A powder day is only good if you can find untracked snow. Weekday mornings = fresh lines. Weekend afternoons = tracked out by 10am.",
            scoring: [
                ("Weekday, early", "10/10", "Empty mountain"),
                ("Weekday", "7/10", "Light crowds"),
                ("Weekend, early", "5/10", "Get there at opening"),
                ("Weekend, late", "2/10", "Everything tracked")
            ]
        )
    ]
}

struct FactorDetailSheet: View {
    let factor: PowderScoreFactorInfo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacingL) {
                    // Header
                    HStack(spacing: .spacingM) {
                        ZStack {
                            Circle()
                                .fill(factor.color.opacity(0.15))
                                .frame(width: 56, height: 56)

                            Image(systemName: factor.icon)
                                .font(.title2)
                                .foregroundStyle(factor.color)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(factor.name)
                                .font(.title2.weight(.bold))

                            Text("\(Int(factor.weight * 100))% of total score")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Description
                    Text(factor.longDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)

                    // Scoring table
                    VStack(alignment: .leading, spacing: .spacingS) {
                        Text("Scoring")
                            .font(.headline)

                        VStack(spacing: 0) {
                            ForEach(Array(factor.scoring.enumerated()), id: \.offset) { index, item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.range)
                                            .font(.subheadline.weight(.medium))
                                        Text(item.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text(item.score)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(factor.color)
                                }
                                .padding(.spacingM)

                                if index < factor.scoring.count - 1 {
                                    Divider()
                                }
                            }
                        }
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(.cornerRadiusCard)
                    }
                }
                .padding(.spacingL)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(factor.name)
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
}

struct UsageTip: Identifiable {
    let id: String
    let step: Int
    let title: String
    let subtitle: String
    let description: String
    let proTip: String?

    static let allTips: [UsageTip] = [
        UsageTip(
            id: "favorites",
            step: 1,
            title: "Add Your Mountains",
            subtitle: "Star your favorite resorts",
            description: "Tap the star icon on any mountain to add it to your favorites. Your favorites appear on the Today tab for quick access.",
            proTip: "Set a \"Home Region\" in Profile to see nearby mountains first."
        ),
        UsageTip(
            id: "score",
            step: 2,
            title: "Check the PowderScore",
            subtitle: "One number, all the data",
            description: "The PowderScore (1-10) combines fresh snow, weather, and crowd data. Scores 8+ are powder days worth chasing. Scores 5-7 are good skiing. Below 5, maybe wait.",
            proTip: "Tap the score gauge on any mountain for a detailed breakdown of what's contributing to the score."
        ),
        UsageTip(
            id: "alerts",
            step: 3,
            title: "Set Powder Alerts",
            subtitle: "Get notified when it dumps",
            description: "Enable Powder Alerts in Profile → Alerts. We'll send a notification when your favorite mountains get 6\"+ of fresh snow.",
            proTip: "You can customize the threshold from 4\" to 12\" based on your powder tolerance."
        ),
        UsageTip(
            id: "forecast",
            step: 4,
            title: "Plan Your Week",
            subtitle: "7-day forecast at a glance",
            description: "Tap into any mountain to see the 7-day forecast. Look for storm icons and check predicted snowfall totals to plan ahead.",
            proTip: "The best days are often the day AFTER a storm clears—blue skies + fresh snow."
        ),
        UsageTip(
            id: "map",
            step: 5,
            title: "Use Weather Overlays",
            subtitle: "See the storm coming",
            description: "On the Map tab, toggle weather overlays to see radar, snow depth, temperature, and smoke/AQI. Great for watching storms roll in.",
            proTip: "The Radar overlay updates every 10 minutes and shows precipitation intensity."
        ),
        UsageTip(
            id: "events",
            step: 6,
            title: "Plan with Friends",
            subtitle: "Coordinate your crew",
            description: "Create an Event for your next ski trip. Invite friends, pick a mountain, and coordinate carpools. Everyone can see conditions for the chosen mountain.",
            proTip: "RSVP early! It helps your crew know who's in for the early morning wakeup call."
        )
    ]
}

struct AppFeature: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let gradient: LinearGradient
    let badge: String?

    static let allFeatures: [AppFeature] = [
        AppFeature(
            id: "powderscore",
            name: "PowderScore™",
            description: "Our proprietary algorithm crunches data from multiple sources to give you one simple number.",
            icon: "gauge.with.dots.needle.67percent",
            gradient: LinearGradient.powderBlue,
            badge: "EXCLUSIVE"
        ),
        AppFeature(
            id: "realtime",
            name: "Real-Time Conditions",
            description: "Live snowfall, temperature, wind, and lift status from official data sources.",
            icon: "antenna.radiowaves.left.and.right",
            gradient: LinearGradient.statusExcellent,
            badge: nil
        ),
        AppFeature(
            id: "alerts",
            name: "Powder Alerts",
            description: "Push notifications when your mountains get significant fresh snow.",
            icon: "bell.badge.fill",
            gradient: LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing),
            badge: nil
        ),
        AppFeature(
            id: "forecast",
            name: "7-Day Forecasts",
            description: "Plan your week with detailed weather forecasts and predicted snowfall.",
            icon: "calendar",
            gradient: LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing),
            badge: nil
        ),
        AppFeature(
            id: "map",
            name: "Weather Map Overlays",
            description: "Radar, snow depth, temperature, wind, and smoke overlays on an interactive map.",
            icon: "map.fill",
            gradient: LinearGradient(colors: [.teal, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
            badge: nil
        ),
        AppFeature(
            id: "events",
            name: "Group Trip Planning",
            description: "Create ski trips, invite friends, coordinate carpools, and share conditions.",
            icon: "person.3.fill",
            gradient: LinearGradient.pookieBSnow,
            badge: "NEW"
        ),
        AppFeature(
            id: "chat",
            name: "Powder Chat AI",
            description: "Ask our AI assistant for personalized mountain recommendations.",
            icon: "bubble.left.and.bubble.right.fill",
            gradient: LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing),
            badge: "BETA"
        ),
        AppFeature(
            id: "widgets",
            name: "Home Screen Widgets",
            description: "Glanceable conditions for your favorite mountains right on your home screen.",
            icon: "square.grid.2x2.fill",
            gradient: LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing),
            badge: nil
        )
    ]
}

#Preview {
    AboutView()
}

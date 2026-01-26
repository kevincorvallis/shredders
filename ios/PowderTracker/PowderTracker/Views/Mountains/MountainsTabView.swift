import SwiftUI

/// Main Mountains tab with purpose-driven sub-views
/// Each view mode is optimized for a specific user intent
struct MountainsTabView: View {
    @StateObject private var viewModel = MountainSelectionViewModel()
    private var favoritesManager: FavoritesManager { FavoritesManager.shared }
    @State private var selectedMode: MountainViewMode = .conditions
    @Namespace private var namespace

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented mode picker
                modePicker
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Content based on selected mode
                TabView(selection: $selectedMode) {
                    ConditionsView(viewModel: viewModel, favoritesManager: favoritesManager)
                        .tag(MountainViewMode.conditions)

                    PlannerView(viewModel: viewModel, favoritesManager: favoritesManager)
                        .tag(MountainViewMode.planner)

                    ExploreView(viewModel: viewModel, favoritesManager: favoritesManager)
                        .tag(MountainViewMode.explore)

                    MyPassView(viewModel: viewModel, favoritesManager: favoritesManager)
                        .tag(MountainViewMode.myPass)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Mountains")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadMountains()
            }
            .task {
                await viewModel.loadMountains()
            }
        }
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(MountainViewMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedMode = mode
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 18))
                        Text(mode.title)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedMode == mode ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if selectedMode == mode {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue)
                                    .matchedGeometryEffect(id: "selected", in: namespace)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: selectedMode)
            }
        }
        .padding(4)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

// MARK: - View Modes

enum MountainViewMode: String, CaseIterable {
    case conditions = "conditions"
    case planner = "planner"
    case explore = "explore"
    case myPass = "myPass"

    var title: String {
        switch self {
        case .conditions: return "Today"
        case .planner: return "Plan"
        case .explore: return "Explore"
        case .myPass: return "My Pass"
        }
    }

    var icon: String {
        switch self {
        case .conditions: return "sun.snow.fill"
        case .planner: return "calendar"
        case .explore: return "binoculars.fill"
        case .myPass: return "wallet.pass.fill"
        }
    }
}

// MARK: - Conditions View (Today)
/// "Where should I go RIGHT NOW?"
/// Focus: Real-time conditions, what's open, current powder

struct ConditionsView: View {
    @ObservedObject var viewModel: MountainSelectionViewModel
    var favoritesManager: FavoritesManager
    @State private var sortBy: ConditionSort = .bestConditions

    enum ConditionSort: String, CaseIterable {
        case bestConditions = "Best Conditions"
        case nearest = "Nearest"
        case mostSnow = "Most Snow"
        case openLifts = "Most Lifts Open"
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Quick status header
                statusHeader
                    .padding(.horizontal)

                // Sort picker
                sortPicker
                    .padding(.horizontal)

                // Conditions cards
                ForEach(sortedMountains) { mountain in
                    NavigationLink {
                        MountainDetailView(mountain: mountain)
                    } label: {
                        ConditionMountainCard(
                            mountain: mountain,
                            conditions: viewModel.getConditions(for: mountain),
                            score: viewModel.getScore(for: mountain),
                            distance: viewModel.getDistance(to: mountain),
                            isFavorite: favoritesManager.isFavorite(mountain.id),
                            onFavoriteToggle: { toggleFavorite(mountain.id) }
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }

                Spacer(minLength: 50)
            }
            .padding(.top)
        }
    }

    private var statusHeader: some View {
        HStack(spacing: 16) {
            StatusPill(
                value: "\(openMountainsCount)",
                label: "Open",
                color: .green
            )

            StatusPill(
                value: "\(freshSnowCount)",
                label: "Fresh Snow",
                color: .blue
            )

            StatusPill(
                value: avgScore,
                label: "Avg Score",
                color: .yellow
            )
        }
    }

    private var sortPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ConditionSort.allCases, id: \.self) { sort in
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            sortBy = sort
                        }
                    } label: {
                        Text(sort.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(sortBy == sort ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(sortBy == sort ? Color.blue : Color(.tertiarySystemBackground))
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var sortedMountains: [Mountain] {
        let open = viewModel.mountains.filter {
            viewModel.getConditions(for: $0)?.liftStatus?.isOpen ?? false
        }

        switch sortBy {
        case .bestConditions:
            return open.sorted { (viewModel.getScore(for: $0) ?? 0) > (viewModel.getScore(for: $1) ?? 0) }
        case .nearest:
            return open.sorted { (viewModel.getDistance(to: $0) ?? .infinity) < (viewModel.getDistance(to: $1) ?? .infinity) }
        case .mostSnow:
            return open.sorted { (viewModel.getConditions(for: $0)?.snowfall24h ?? 0) > (viewModel.getConditions(for: $1)?.snowfall24h ?? 0) }
        case .openLifts:
            return open.sorted {
                (viewModel.getConditions(for: $0)?.liftStatus?.liftsOpen ?? 0) >
                (viewModel.getConditions(for: $1)?.liftStatus?.liftsOpen ?? 0)
            }
        }
    }

    private var openMountainsCount: Int {
        viewModel.mountains.filter {
            viewModel.getConditions(for: $0)?.liftStatus?.isOpen ?? false
        }.count
    }

    private var freshSnowCount: Int {
        viewModel.mountains.filter {
            (viewModel.getConditions(for: $0)?.snowfall24h ?? 0) >= 3
        }.count
    }

    private var avgScore: String {
        let scores = viewModel.mountains.compactMap { viewModel.getScore(for: $0) }
        guard !scores.isEmpty else { return "--" }
        return String(format: "%.1f", scores.reduce(0, +) / Double(scores.count))
    }

    private func toggleFavorite(_ id: String) {
        if favoritesManager.isFavorite(id) {
            favoritesManager.remove(id)
        } else {
            _ = favoritesManager.add(id)
        }
    }
}

// MARK: - Planner View
/// "Where should I go THIS WEEKEND?"
/// Focus: Forecast, comparison, trip planning

struct PlannerView: View {
    @ObservedObject var viewModel: MountainSelectionViewModel
    var favoritesManager: FavoritesManager
    @State private var selectedDay: PlanDay = .saturday
    @State private var compareList: [String] = []
    @State private var showComparison = false

    enum PlanDay: String, CaseIterable {
        case tomorrow = "Tomorrow"
        case saturday = "Saturday"
        case sunday = "Sunday"
        case nextWeek = "Next Week"
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Day picker
                dayPicker
                    .padding(.horizontal)

                // Comparison toolbar
                if !compareList.isEmpty {
                    comparisonToolbar
                        .padding(.horizontal)
                }

                // Best picks for selected day
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Best for \(selectedDay.rawValue)")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(bestForDay.prefix(5)) { mountain in
                                    PlannerCard(
                                        mountain: mountain,
                                        conditions: viewModel.getConditions(for: mountain),
                                        score: viewModel.getScore(for: mountain),
                                        isInCompareList: compareList.contains(mountain.id),
                                        onCompareToggle: { toggleCompare(mountain.id) }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                // All mountains with forecast
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Mountains")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(viewModel.mountains) { mountain in
                            NavigationLink {
                                MountainDetailView(mountain: mountain)
                            } label: {
                                ForecastRow(
                                    mountain: mountain,
                                    conditions: viewModel.getConditions(for: mountain),
                                    score: viewModel.getScore(for: mountain),
                                    isInCompareList: compareList.contains(mountain.id),
                                    onCompareToggle: { toggleCompare(mountain.id) }
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }
                }

                Spacer(minLength: 50)
            }
            .padding(.top)
        }
        .sheet(isPresented: $showComparison) {
            ComparisonSheet(
                mountains: compareList.compactMap { id in
                    viewModel.mountains.first { $0.id == id }
                },
                viewModel: viewModel
            )
        }
    }

    private var dayPicker: some View {
        HStack(spacing: 8) {
            ForEach(PlanDay.allCases, id: \.self) { day in
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        selectedDay = day
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(dayLabel(day))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(dayNumber(day))
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedDay == day ? Color.blue : Color(.tertiarySystemBackground))
                    .foregroundColor(selectedDay == day ? .white : .primary)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var comparisonToolbar: some View {
        HStack {
            Text("\(compareList.count) selected")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Button("Clear") {
                withAnimation {
                    compareList.removeAll()
                }
            }
            .font(.subheadline)

            Button("Compare") {
                showComparison = true
            }
            .buttonStyle(.borderedProminent)
            .disabled(compareList.count < 2)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var bestForDay: [Mountain] {
        // TODO: Use actual forecast data for selected day
        viewModel.mountains.sorted {
            (viewModel.getScore(for: $0) ?? 0) > (viewModel.getScore(for: $1) ?? 0)
        }
    }

    private func dayLabel(_ day: PlanDay) -> String {
        let calendar = Calendar.current
        let today = Date()

        switch day {
        case .tomorrow:
            return "TOM"
        case .saturday:
            let daysUntilSat = (7 - calendar.component(.weekday, from: today) + 7) % 7
            return daysUntilSat == 0 ? "TODAY" : "SAT"
        case .sunday:
            return "SUN"
        case .nextWeek:
            return "NEXT"
        }
    }

    private func dayNumber(_ day: PlanDay) -> String {
        let calendar = Calendar.current
        let today = Date()

        switch day {
        case .tomorrow:
            let date = calendar.date(byAdding: .day, value: 1, to: today)!
            return "\(calendar.component(.day, from: date))"
        case .saturday:
            let daysUntilSat = (7 - calendar.component(.weekday, from: today) + 7) % 7
            let date = calendar.date(byAdding: .day, value: daysUntilSat, to: today)!
            return "\(calendar.component(.day, from: date))"
        case .sunday:
            let daysUntilSun = (8 - calendar.component(.weekday, from: today)) % 7
            let date = calendar.date(byAdding: .day, value: daysUntilSun, to: today)!
            return "\(calendar.component(.day, from: date))"
        case .nextWeek:
            let date = calendar.date(byAdding: .day, value: 7, to: today)!
            return "\(calendar.component(.day, from: date))"
        }
    }

    private func toggleCompare(_ id: String) {
        if compareList.contains(id) {
            compareList.removeAll { $0 == id }
        } else if compareList.count < 4 {
            compareList.append(id)
        }
    }
}

// MARK: - Explore View
/// "What mountains exist? Find something new"
/// Focus: Discovery, regions, terrain types

struct ExploreView: View {
    @ObservedObject var viewModel: MountainSelectionViewModel
    var favoritesManager: FavoritesManager
    @State private var searchText = ""
    @State private var selectedRegion: ExploreRegion?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Search
                searchBar
                    .padding(.horizontal)

                if searchText.isEmpty {
                    // Browse by Region
                    regionSection

                    // Categories
                    categoriesSection

                    // All Mountains A-Z
                    allMountainsSection
                } else {
                    // Search results
                    searchResultsSection
                }

                Spacer(minLength: 50)
            }
            .padding(.top)
        }
        .sheet(item: $selectedRegion) { region in
            RegionSheet(
                region: region,
                mountains: mountainsInRegion(region),
                viewModel: viewModel,
                favoritesManager: favoritesManager
            )
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search mountains, regions...", text: $searchText)
                .textFieldStyle(.plain)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var regionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Browse by Region", icon: "map.fill")
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ExploreRegion.allCases, id: \.self) { region in
                        RegionTile(
                            region: region,
                            count: mountainsInRegion(region).count,
                            onTap: { selectedRegion = region }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Categories", icon: "square.grid.2x2.fill")
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                CategoryTile(
                    title: "Hidden Gems",
                    subtitle: "Lesser-known favorites",
                    icon: "sparkles",
                    color: .purple,
                    count: hiddenGems.count
                )

                CategoryTile(
                    title: "Family Friendly",
                    subtitle: "Great for all ages",
                    icon: "figure.2.and.child.holdinghands",
                    color: .green,
                    count: familyFriendly.count
                )

                CategoryTile(
                    title: "Expert Terrain",
                    subtitle: "Steep & deep",
                    icon: "figure.skiing.downhill",
                    color: .black,
                    count: expertTerrain.count
                )

                CategoryTile(
                    title: "Night Skiing",
                    subtitle: "Lights on",
                    icon: "moon.stars.fill",
                    color: .indigo,
                    count: nightSkiing.count
                )
            }
            .padding(.horizontal)
        }
    }

    private var allMountainsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "All Mountains", icon: "mountain.2.fill")
                .padding(.horizontal)

            ForEach(viewModel.mountains.sorted { $0.name < $1.name }) { mountain in
                NavigationLink {
                    MountainDetailView(mountain: mountain)
                } label: {
                    ExploreRow(
                        mountain: mountain,
                        isFavorite: favoritesManager.isFavorite(mountain.id)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(searchResults.count) results")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ForEach(searchResults) { mountain in
                NavigationLink {
                    MountainDetailView(mountain: mountain)
                } label: {
                    ExploreRow(
                        mountain: mountain,
                        isFavorite: favoritesManager.isFavorite(mountain.id)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
        }
    }

    private var searchResults: [Mountain] {
        viewModel.mountains.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.shortName.localizedCaseInsensitiveContains(searchText) ||
            $0.region.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func mountainsInRegion(_ region: ExploreRegion) -> [Mountain] {
        viewModel.mountains.filter {
            $0.region.lowercased().contains(region.searchKey.lowercased())
        }
    }

    // Category filters (simplified - would need actual data)
    private var hiddenGems: [Mountain] {
        viewModel.mountains.filter { !favoritesManager.isFavorite($0.id) }
    }

    private var familyFriendly: [Mountain] {
        viewModel.mountains // Would filter by terrain difficulty
    }

    private var expertTerrain: [Mountain] {
        viewModel.mountains // Would filter by expert terrain %
    }

    private var nightSkiing: [Mountain] {
        viewModel.mountains // Would filter by night skiing availability
    }
}

// MARK: - My Pass View
/// "What can I access with my pass?"
/// Focus: Pass filtering, value/savings

struct MyPassView: View {
    @ObservedObject var viewModel: MountainSelectionViewModel
    var favoritesManager: FavoritesManager
    @State private var selectedPass: PassSelection = .all

    enum PassSelection: String, CaseIterable {
        case all = "All"
        case epic = "Epic"
        case ikon = "Ikon"
        case independent = "Independent"

        var passType: PassType? {
            switch self {
            case .all: return nil
            case .epic: return .epic
            case .ikon: return .ikon
            case .independent: return .independent
            }
        }

        var color: Color {
            switch self {
            case .all: return .gray
            case .epic: return .purple
            case .ikon: return .orange
            case .independent: return .blue
            }
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Pass selector
                passPicker
                    .padding(.horizontal)

                // Pass benefits summary (if specific pass selected)
                if selectedPass != .all {
                    passSummary
                        .padding(.horizontal)
                }

                // Mountains for selected pass
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(filteredMountains.count) Mountains")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(filteredMountains) { mountain in
                        NavigationLink {
                            MountainDetailView(mountain: mountain)
                        } label: {
                            PassMountainRow(
                                mountain: mountain,
                                conditions: viewModel.getConditions(for: mountain),
                                score: viewModel.getScore(for: mountain),
                                isFavorite: favoritesManager.isFavorite(mountain.id),
                                onFavoriteToggle: { toggleFavorite(mountain.id) }
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }

                Spacer(minLength: 50)
            }
            .padding(.top)
        }
    }

    private var passPicker: some View {
        HStack(spacing: 8) {
            ForEach(PassSelection.allCases, id: \.self) { pass in
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        selectedPass = pass
                    }
                } label: {
                    HStack(spacing: 6) {
                        if pass != .all {
                            Circle()
                                .fill(pass.color)
                                .frame(width: 8, height: 8)
                        }
                        Text(pass.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedPass == pass ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(selectedPass == pass ? pass.color : Color(.tertiarySystemBackground))
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var passSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(selectedPass.rawValue + " Pass")
                        .font(.headline)
                    Text("\(filteredMountains.count) mountains included")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Pass logo would go here
                Circle()
                    .fill(selectedPass.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(selectedPass.rawValue.prefix(1))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(selectedPass.color)
                    )
            }

            // Quick stats
            HStack(spacing: 16) {
                PassStat(value: "\(openOnPass)", label: "Open Now")
                PassStat(value: "\(freshOnPass)", label: "Fresh Snow")
                PassStat(value: bestScoreOnPass, label: "Best Score")
            }
        }
        .padding()
        .background(selectedPass.color.opacity(0.1))
        .cornerRadius(16)
    }

    private var filteredMountains: [Mountain] {
        guard let passType = selectedPass.passType else {
            return viewModel.mountains.sorted {
                (viewModel.getScore(for: $0) ?? 0) > (viewModel.getScore(for: $1) ?? 0)
            }
        }
        return viewModel.mountains
            .filter { $0.passType == passType }
            .sorted { (viewModel.getScore(for: $0) ?? 0) > (viewModel.getScore(for: $1) ?? 0) }
    }

    private var openOnPass: Int {
        filteredMountains.filter {
            viewModel.getConditions(for: $0)?.liftStatus?.isOpen ?? false
        }.count
    }

    private var freshOnPass: Int {
        filteredMountains.filter {
            (viewModel.getConditions(for: $0)?.snowfall24h ?? 0) >= 3
        }.count
    }

    private var bestScoreOnPass: String {
        let best = filteredMountains.compactMap { viewModel.getScore(for: $0) }.max() ?? 0
        return String(format: "%.1f", best)
    }

    private func toggleFavorite(_ id: String) {
        if favoritesManager.isFavorite(id) {
            favoritesManager.remove(id)
        } else {
            _ = favoritesManager.add(id)
        }
    }
}

// MARK: - Supporting Types

enum ExploreRegion: String, CaseIterable, Identifiable {
    case washington, oregon, idaho, britishColumbia, montana, california

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .washington: return "Washington"
        case .oregon: return "Oregon"
        case .idaho: return "Idaho"
        case .britishColumbia: return "British Columbia"
        case .montana: return "Montana"
        case .california: return "California"
        }
    }

    var searchKey: String {
        switch self {
        case .britishColumbia: return "british columbia"
        default: return rawValue
        }
    }

    var icon: String {
        switch self {
        case .washington: return "w.square.fill"
        case .oregon: return "o.square.fill"
        case .idaho: return "i.square.fill"
        case .britishColumbia: return "b.square.fill"
        case .montana: return "m.square.fill"
        case .california: return "c.square.fill"
        }
    }

    var color: Color {
        switch self {
        case .washington: return .blue
        case .oregon: return .green
        case .idaho: return .orange
        case .britishColumbia: return .red
        case .montana: return .purple
        case .california: return .yellow
        }
    }
}

// MARK: - Component Views

struct StatusPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ConditionMountainCard: View {
    let mountain: Mountain
    let conditions: MountainConditions?
    let score: Double?
    let distance: Double?
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Logo
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 56
            )

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(mountain.shortName)
                        .font(.headline)

                    if let status = conditions?.liftStatus, status.isOpen {
                        Text("OPEN")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 12) {
                    if let conditions = conditions {
                        Label("\(conditions.snowfall24h)\"", systemImage: "cloud.snow.fill")
                            .font(.caption)
                            .foregroundColor(.blue)

                        if let lifts = conditions.liftStatus {
                            Label("\(lifts.liftsOpen)/\(lifts.liftsTotal)", systemImage: "cablecar.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let distance = distance {
                        Label("\(Int(distance))mi", systemImage: "location.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Score
            if let score = score {
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", score))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor(score))
                    Text("score")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Favorite
            Button(action: onFavoriteToggle) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundColor(isFavorite ? .yellow : .secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 7 { return .green }
        if score >= 5 { return .yellow }
        return .orange
    }
}

struct PlannerCard: View {
    let mountain: Mountain
    let conditions: MountainConditions?
    let score: Double?
    let isInCompareList: Bool
    let onCompareToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                MountainLogoView(
                    logoUrl: mountain.logo,
                    color: mountain.color,
                    size: 50
                )
                .frame(maxWidth: .infinity)
                .frame(height: 70)
                .background(Color(hex: mountain.color)?.opacity(0.15) ?? Color.blue.opacity(0.15))

                Button(action: onCompareToggle) {
                    Image(systemName: isInCompareList ? "checkmark.circle.fill" : "plus.circle")
                        .font(.title3)
                        .foregroundColor(isInCompareList ? .blue : .white)
                        .shadow(radius: 2)
                }
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(mountain.shortName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                if let score = score {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(score >= 7 ? Color.green : score >= 5 ? Color.yellow : Color.orange)
                            .frame(width: 6, height: 6)
                        Text(String(format: "%.1f", score))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .frame(width: 120)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isInCompareList ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct ForecastRow: View {
    let mountain: Mountain
    let conditions: MountainConditions?
    let score: Double?
    let isInCompareList: Bool
    let onCompareToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onCompareToggle) {
                Image(systemName: isInCompareList ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isInCompareList ? .blue : .secondary)
            }

            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 40
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(mountain.shortName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(mountain.region.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Forecast preview (simplified)
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { day in
                    VStack(spacing: 2) {
                        Image(systemName: day == 0 ? "sun.max.fill" : "cloud.snow.fill")
                            .font(.caption)
                            .foregroundColor(day == 0 ? .yellow : .blue)
                        Text("\(Int.random(in: 0...6))\"")
                            .font(.caption2)
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }
}

struct RegionTile: View {
    let region: ExploreRegion
    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: region.icon)
                    .font(.title2)
                    .foregroundColor(region.color)

                Text(region.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("\(count) mountains")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 130)
            .padding()
            .background(region.color.opacity(0.1))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct CategoryTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                Spacer()
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct ExploreRow: View {
    let mountain: Mountain
    let isFavorite: Bool

    var body: some View {
        HStack(spacing: 12) {
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 40
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(mountain.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(mountain.region.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let passType = mountain.passType, passType != .independent {
                Text(passType.rawValue.capitalized)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(passType == .epic ? .purple : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(passType == .epic ? Color.purple.opacity(0.1) : Color.orange.opacity(0.1))
                    .cornerRadius(6)
            }

            if isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct PassMountainRow: View {
    let mountain: Mountain
    let conditions: MountainConditions?
    let score: Double?
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 44
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(mountain.shortName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    if let conditions = conditions {
                        if conditions.liftStatus?.isOpen ?? false {
                            Text("Open")
                                .font(.caption2)
                                .foregroundColor(.green)
                        } else {
                            Text("Closed")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }

                        Text("•")
                            .foregroundColor(.secondary)

                        Text("\(conditions.snowfall24h)\" 24h")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if let score = score {
                Text(String(format: "%.1f", score))
                    .font(.headline)
                    .foregroundColor(score >= 7 ? .green : score >= 5 ? .yellow : .orange)
            }

            Button(action: onFavoriteToggle) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundColor(isFavorite ? .yellow : .secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct PassStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RegionSheet: View {
    let region: ExploreRegion
    let mountains: [Mountain]
    @ObservedObject var viewModel: MountainSelectionViewModel
    var favoritesManager: FavoritesManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(mountains) { mountain in
                NavigationLink {
                    MountainDetailView(mountain: mountain)
                } label: {
                    HStack {
                        MountainLogoView(
                            logoUrl: mountain.logo,
                            color: mountain.color,
                            size: 40
                        )

                        VStack(alignment: .leading) {
                            Text(mountain.name)
                                .font(.headline)
                            if let score = viewModel.getScore(for: mountain) {
                                Text(String(format: "Score: %.1f", score))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if favoritesManager.isFavorite(mountain.id) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            .navigationTitle(region.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct ComparisonSheet: View {
    let mountains: [Mountain]
    let viewModel: MountainSelectionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 1) {
                    // Row labels
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("")
                            .frame(height: 100)
                        ComparisonLabel("Powder Score")
                        ComparisonLabel("24h Snow")
                        ComparisonLabel("48h Snow")
                        ComparisonLabel("Temperature")
                        ComparisonLabel("Lifts Open")
                        ComparisonLabel("Pass Type")
                    }
                    .padding(.leading)

                    // Mountain columns
                    ForEach(mountains) { mountain in
                        VStack(spacing: 0) {
                            // Header
                            VStack(spacing: 4) {
                                MountainLogoView(
                                    logoUrl: mountain.logo,
                                    color: mountain.color,
                                    size: 50
                                )
                                Text(mountain.shortName)
                                    .font(.headline)
                            }
                            .frame(height: 100)

                            // Data rows
                            ComparisonValue(viewModel.getScore(for: mountain).map { String(format: "%.1f", $0) } ?? "--")
                            ComparisonValue("\(viewModel.getConditions(for: mountain)?.snowfall24h ?? 0)\"")
                            ComparisonValue("\(viewModel.getConditions(for: mountain)?.snowfall48h ?? 0)\"")
                            ComparisonValue(viewModel.getConditions(for: mountain)?.temperature.map { "\($0)°F" } ?? "--")
                            ComparisonValue(viewModel.getConditions(for: mountain)?.liftStatus.map { "\($0.liftsOpen)/\($0.liftsTotal)" } ?? "--")
                            ComparisonValue(mountain.passType?.rawValue.capitalized ?? "Independent")
                        }
                        .frame(width: 100)
                    }
                }
                .padding()
            }
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct ComparisonLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(height: 44)
    }
}

struct ComparisonValue: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemGroupedBackground))
    }
}

// MARK: - Preview

#Preview {
    MountainsTabView()
}

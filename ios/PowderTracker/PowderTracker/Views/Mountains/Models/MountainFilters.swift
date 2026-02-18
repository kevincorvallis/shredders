import SwiftUI

// MARK: - Sort & Filter Options

enum SortOption: String, CaseIterable {
    case distance = "Distance"
    case name = "Name"
    case snowfall = "Snowfall"
    case powderScore = "Powder Score"
    case favorites = "Favorites"

    var icon: String {
        switch self {
        case .distance: return "location"
        case .name: return "textformat.abc"
        case .snowfall: return "snowflake"
        case .powderScore: return "star.fill"
        case .favorites: return "star"
        }
    }
}

enum PassFilter: String, CaseIterable {
    case all = "All Passes"
    case epic = "Epic"
    case ikon = "Ikon"
    case independent = "Independent"
    case favorites = "Favorites"
    case freshPowder = "Fresh Powder"

    var passType: PassType? {
        switch self {
        case .epic: return .epic
        case .ikon: return .ikon
        case .independent: return .independent
        default: return nil
        }
    }

    /// For MountainMapView compatibility
    var passTypeKey: PassType? {
        passType
    }

    var icon: String {
        switch self {
        case .all: return "mountain.2"
        case .epic: return "ticket"
        case .ikon: return "star.square"
        case .independent: return "building.2"
        case .favorites: return "star.fill"
        case .freshPowder: return "snowflake"
        }
    }
}

// MARK: - Filter Chip Component

struct FilterChipView: View {
    let icon: String
    let label: String
    var isActive: Bool = false

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(label)
                .font(.subheadline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isActive ? Color.blue : Color(.tertiarySystemFill))
        .foregroundColor(isActive ? .white : .primary)
        .clipShape(Capsule())
    }
}

// MARK: - Supporting Types

enum QuickFilter: String, CaseIterable {
    case favorites = "Favorites"
    case epic = "Epic"
    case ikon = "Ikon"
    case freshPowder = "Fresh Snow"
    case open = "Open Now"

    var icon: String {
        switch self {
        case .favorites: return "star.fill"
        case .epic: return "e.square.fill"
        case .ikon: return "i.square.fill"
        case .freshPowder: return "snowflake"
        case .open: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .favorites: return .yellow
        case .epic: return .purple
        case .ikon: return .orange
        case .freshPowder: return .blue
        case .open: return .green
        }
    }
}

enum MountainRegion: String, CaseIterable, Identifiable {
    case washington = "washington"
    case oregon = "oregon"
    case idaho = "idaho"
    case britishColumbia = "british columbia"
    case utah = "utah"
    case montana = "montana"
    case california = "california"
    case colorado = "colorado"
    case wyoming = "wyoming"
    case vermont = "vermont"
    case newmexico = "newmexico"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .washington: return "Washington"
        case .oregon: return "Oregon"
        case .idaho: return "Idaho"
        case .britishColumbia: return "British Columbia"
        case .utah: return "Utah"
        case .montana: return "Montana"
        case .california: return "California"
        case .colorado: return "Colorado"
        case .wyoming: return "Wyoming"
        case .vermont: return "Vermont"
        case .newmexico: return "New Mexico"
        }
    }

    var icon: String {
        switch self {
        case .washington: return "w.square.fill"
        case .oregon: return "o.square.fill"
        case .idaho: return "i.square.fill"
        case .britishColumbia: return "b.square.fill"
        case .utah: return "u.square.fill"
        case .montana: return "m.square.fill"
        case .california: return "c.square.fill"
        case .colorado: return "mountain.2.fill"
        case .wyoming: return "wind"
        case .vermont: return "v.square.fill"
        case .newmexico: return "sun.max.fill"
        }
    }

    var color: Color {
        switch self {
        case .washington: return .blue
        case .oregon: return .green
        case .idaho: return .orange
        case .britishColumbia: return .red
        case .utah: return .indigo
        case .montana: return .purple
        case .california: return .yellow
        case .colorado: return .red
        case .wyoming: return .teal
        case .vermont: return .mint
        case .newmexico: return .brown
        }
    }
}

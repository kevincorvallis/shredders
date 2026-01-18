import SwiftUI

/// Section header with optional icon
struct SectionHeaderView: View {
    let title: String
    let icon: String?
    let iconColor: Color

    init(title: String, icon: String? = nil, iconColor: Color = .orange) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
    }

    var body: some View {
        Group {
            if let icon = icon {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.headline)
                    Text(title)
                        .font(.headline)
                }
            } else {
                Text(title)
                    .sectionHeader()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: .spacingL) {
        SectionHeaderView(title: "Simple Header")
        SectionHeaderView(title: "Leave Soon", icon: "bolt.fill")
        SectionHeaderView(title: "Active Alerts", icon: "exclamationmark.triangle.fill")
    }
    .padding()
}

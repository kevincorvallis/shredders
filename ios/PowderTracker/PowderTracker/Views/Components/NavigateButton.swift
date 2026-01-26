import SwiftUI
import MapKit

struct NavigateButton: View {
    let mountain: Mountain
    let variant: Variant
    let size: Size

    enum Variant {
        case primary
        case secondary
    }

    enum Size {
        case small
        case medium
        case large
    }

    var body: some View {
        Button {
            openMaps()
        } label: {
            HStack(spacing: spacing) {
                Image(systemName: "location.fill")
                    .font(iconFont)
                Text("Navigate")
                    .font(textFont)
                    .fontWeight(fontWeight)
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .accessibilityLabel("Navigate to \(mountain.name)")
        .accessibilityHint("Opens Maps app with driving directions")
    }

    private func openMaps() {
        let coordinate = mountain.location.coordinate
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = mountain.name

        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    // MARK: - Styling Properties

    private var spacing: CGFloat {
        switch size {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        }
    }

    private var iconFont: Font {
        switch size {
        case .small: return .caption
        case .medium: return .subheadline
        case .large: return .body
        }
    }

    private var textFont: Font {
        switch size {
        case .small: return .caption
        case .medium: return .subheadline
        case .large: return .body
        }
    }

    private var fontWeight: Font.Weight {
        variant == .primary ? .semibold : .medium
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .small: return 6
        case .medium: return 10
        case .large: return 14
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary: return .white
        case .secondary: return .white
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary: return .blue
        case .secondary: return Color(.secondarySystemFill)
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary: return .clear
        case .secondary: return Color(.separator)
        }
    }

    private var borderWidth: CGFloat {
        variant == .secondary ? 1 : 0
    }
}

#Preview("Primary - Large") {
    NavigateButton(
        mountain: Mountain.mock,
        variant: .primary,
        size: .large
    )
    .padding()
}

#Preview("Secondary - Medium") {
    NavigateButton(
        mountain: Mountain.mock,
        variant: .secondary,
        size: .medium
    )
    .padding()
}

#Preview("Secondary - Small") {
    NavigateButton(
        mountain: Mountain.mock,
        variant: .secondary,
        size: .small
    )
    .padding()
}

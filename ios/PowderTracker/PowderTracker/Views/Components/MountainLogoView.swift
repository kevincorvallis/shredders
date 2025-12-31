import SwiftUI

struct MountainLogoView: View {
    let logoUrl: String?
    let color: String
    let size: CGFloat

    init(logoUrl: String?, color: String, size: CGFloat = 40) {
        self.logoUrl = logoUrl
        self.color = color
        self.size = size
    }

    private var fullLogoUrl: URL? {
        guard let logoUrl = logoUrl, !logoUrl.isEmpty else { return nil }
        // Convert API base URL from /api to just the domain
        let baseUrl = AppConfig.apiBaseURL.replacingOccurrences(of: "/api", with: "")
        return URL(string: "\(baseUrl)\(logoUrl)")
    }

    var body: some View {
        if let url = fullLogoUrl {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                case .failure, .empty:
                    fallbackView
                @unknown default:
                    fallbackView
                }
            }
        } else {
            fallbackView
        }
    }

    private var fallbackView: some View {
        Circle()
            .fill(Color(hex: color) ?? .blue)
            .frame(width: size, height: size)
            .overlay(
                Text(extractInitial())
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    private func extractInitial() -> String {
        if let logoUrl = logoUrl,
           let filename = logoUrl.split(separator: "/").last,
           let initial = filename.split(separator: ".").first?.first {
            return String(initial).uppercased()
        }
        return "M"
    }
}

#Preview {
    VStack(spacing: 20) {
        // Logo with valid URL
        MountainLogoView(
            logoUrl: "/logos/baker.svg",
            color: "#4A90E2",
            size: 60
        )

        // Fallback view (no logo URL)
        MountainLogoView(
            logoUrl: nil,
            color: "#E74C3C",
            size: 60
        )

        // Small size
        MountainLogoView(
            logoUrl: "/logos/crystal.svg",
            color: "#9B59B6",
            size: 40
        )
    }
    .padding()
}

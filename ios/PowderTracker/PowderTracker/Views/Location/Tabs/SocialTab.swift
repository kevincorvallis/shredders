import SwiftUI

struct SocialTab: View {
    @ObservedObject var viewModel: LocationViewModel
    let mountain: Mountain

    var body: some View {
        VStack(spacing: 16) {
            Text("User photos and check-ins coming soon")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

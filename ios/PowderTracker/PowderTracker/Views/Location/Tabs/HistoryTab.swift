import SwiftUI

struct HistoryTab: View {
    @ObservedObject var viewModel: LocationViewModel
    let mountain: Mountain

    var body: some View {
        VStack(spacing: 16) {
            Text("Historical snow depth data coming soon")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

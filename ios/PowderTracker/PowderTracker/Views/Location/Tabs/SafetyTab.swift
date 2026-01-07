import SwiftUI

struct SafetyTab: View {
    @ObservedObject var viewModel: LocationViewModel
    let mountain: Mountain

    var body: some View {
        VStack(spacing: 16) {
            Text("Safety alerts and conditions coming soon")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}

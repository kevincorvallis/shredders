import SwiftUI

struct WebcamsTab: View {
    var viewModel: LocationViewModel
    let mountain: Mountain

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.hasWebcams {
                WebcamsSection(viewModel: viewModel)
            } else {
                Text("No webcams available")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

import SwiftUI

struct LiftsTab: View {
    var viewModel: LocationViewModel
    let mountain: Mountain

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.liftData != nil, let mountainDetail = viewModel.locationData?.mountain {
                LocationMapSection(
                    mountain: mountain,
                    mountainDetail: mountainDetail,
                    liftData: viewModel.liftData
                )
            } else {
                Text("Lift map data not available")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

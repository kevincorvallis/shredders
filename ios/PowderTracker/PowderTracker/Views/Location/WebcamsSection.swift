import SwiftUI
import Nuke
import NukeUI

struct WebcamsSection: View {
    @ObservedObject var viewModel: LocationViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Resort Webcams
            if let mountain = viewModel.locationData?.mountain,
               !mountain.webcams.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    // Section Header
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.blue)
                        Text("Resort Webcams")
                            .font(.headline)
                    }

                    // Webcams Scroll View
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(mountain.webcams) { webcam in
                                LocationResortWebcamCard(webcam: webcam)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            }

            // Road Webcams
            if let roadWebcams = viewModel.locationData?.mountain.roadWebcams,
               !roadWebcams.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    // Section Header
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.blue)
                        Text("Road Webcams")
                            .font(.headline)
                    }

                    // Webcams Scroll View
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(roadWebcams) { webcam in
                                LocationRoadWebcamCard(webcam: webcam)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
        }
    }
}

struct LocationRoadWebcamCard: View {
    let webcam: MountainDetail.RoadWebcam
    @State private var isImageExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Webcam Image with Nuke caching
            LazyImage(url: URL(string: webcam.url)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 250, height: 180)
                        .clipped()
                        .cornerRadius(8)
                        .onTapGesture {
                            isImageExpanded = true
                        }
                } else if state.error != nil {
                    ZStack {
                        Color(.systemGray5)
                        VStack {
                            Image(systemName: "camera.metering.unknown")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text("Failed to load")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 250, height: 180)
                    .cornerRadius(8)
                } else {
                    ProgressView()
                        .frame(width: 250, height: 180)
                }
            }
            .processors([ImageProcessors.Resize(width: 250)])
            .priority(.high)

            // Webcam Info
            VStack(alignment: .leading, spacing: 4) {
                Text(webcam.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "road.lanes")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text(webcam.highway)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let milepost = webcam.milepost {
                        Text("MP \(milepost)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(width: 250, alignment: .leading)
        }
        .frame(width: 250)
        .sheet(isPresented: $isImageExpanded) {
            WebcamExpandedView(webcam: webcam, isPresented: $isImageExpanded)
        }
    }
}

struct WebcamExpandedView: View {
    let webcam: MountainDetail.RoadWebcam
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack {
                LazyImage(url: URL(string: webcam.url)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if state.error != nil {
                        VStack {
                            Image(systemName: "camera.metering.unknown")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Failed to load image")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ProgressView()
                    }
                }
                .priority(.high)
    
                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    Text(webcam.name)
                        .font(.headline)

                    HStack {
                        Image(systemName: "road.lanes")
                        Text(webcam.highway)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)

                    if let milepost = webcam.milepost {
                        HStack {
                            Image(systemName: "mappin.circle")
                            Text("MP \(milepost)")
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                    }

                    HStack {
                        Image(systemName: "building")
                        Text(webcam.agency)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Webcam")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct LocationResortWebcamCard: View {
    let webcam: MountainDetail.Webcam
    @State private var isImageExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Webcam Image with Nuke caching
            LazyImage(url: URL(string: webcam.url)) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 250, height: 180)
                        .clipped()
                        .cornerRadius(8)
                        .onTapGesture {
                            isImageExpanded = true
                        }
                } else if state.error != nil {
                    ZStack {
                        Color(.systemGray5)
                        VStack {
                            Image(systemName: "camera.metering.unknown")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text("Failed to load")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 250, height: 180)
                    .cornerRadius(8)
                } else {
                    ProgressView()
                        .frame(width: 250, height: 180)
                }
            }
            .processors([ImageProcessors.Resize(width: 250)])
            .priority(.high)

            // Webcam Info
            VStack(alignment: .leading, spacing: 4) {
                Text(webcam.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
            }
            .frame(width: 250, alignment: .leading)
        }
        .frame(width: 250)
        .sheet(isPresented: $isImageExpanded) {
            ResortWebcamExpandedView(webcam: webcam, isPresented: $isImageExpanded)
        }
    }
}

struct ResortWebcamExpandedView: View {
    let webcam: MountainDetail.Webcam
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            VStack {
                LazyImage(url: URL(string: webcam.url)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if state.error != nil {
                        VStack {
                            Image(systemName: "camera.metering.unknown")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Failed to load image")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ProgressView()
                    }
                }
                .priority(.high)
    
                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    Text(webcam.name)
                        .font(.headline)

                    if let refreshUrl = webcam.refreshUrl {
                        Link(destination: URL(string: refreshUrl)!) {
                            HStack {
                                Image(systemName: "link")
                                Text("View on resort website")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Webcam")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

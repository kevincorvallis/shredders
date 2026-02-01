//
//  AvatarEditorView.swift
//  PowderTracker
//
//  Avatar editor view with PHPickerViewController for selecting profile images.
//  No camera permissions needed - uses iOS 14+ limited photo picker.
//

import SwiftUI
import PhotosUI
import UIKit

/// SwiftUI wrapper for PHPickerViewController to select profile images
struct ProfileImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ProfileImagePicker

        init(_ parent: ProfileImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else {
                return
            }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                    if let error = error {
                        print("Error loading image: \(error.localizedDescription)")
                        return
                    }

                    DispatchQueue.main.async {
                        self?.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}

// MARK: - Avatar Editor View

/// A view for selecting and editing profile avatars
struct AvatarEditorView: View {
    @Binding var selectedImage: UIImage?
    let currentAvatarUrl: String?
    let onSave: (UIImage) async throws -> Void

    @State private var showingImagePicker = false
    @State private var showingCropper = false
    @State private var rawImageForCropping: UIImage?
    @State private var isUploading = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: .spacingXL) {
                Spacer()

                // Avatar Preview
                ZStack {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                            )
                    } else if let urlString = currentAvatarUrl, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                placeholderAvatar
                            case .empty:
                                ProgressView()
                            @unknown default:
                                placeholderAvatar
                            }
                        }
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                    } else {
                        placeholderAvatar
                    }

                    // Edit overlay
                    Circle()
                        .fill(.black.opacity(0.3))
                        .frame(width: 150, height: 150)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                        )
                        .opacity(0.8)
                }
                .onTapGesture {
                    showingImagePicker = true
                }

                Text("Tap to select a photo")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Spacer()

                // Action Buttons
                VStack(spacing: .spacingM) {
                    if selectedImage != nil {
                        Button {
                            Task {
                                await saveAvatar()
                            }
                        } label: {
                            HStack {
                                if isUploading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                }
                                Text(isUploading ? "Uploading..." : "Save Photo")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(.cornerRadiusButton)
                        }
                        .disabled(isUploading)
                    }

                    Button {
                        showingImagePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Choose from Library")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(.primary)
                        .cornerRadius(.cornerRadiusButton)
                    }
                }
                .padding(.horizontal, .spacingL)
                .padding(.bottom, .spacingXL)
            }
            .navigationTitle("Profile Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ProfileImagePicker(selectedImage: $rawImageForCropping)
            }
            .onChange(of: rawImageForCropping) { _, newImage in
                if newImage != nil {
                    showingCropper = true
                }
            }
            .fullScreenCover(isPresented: $showingCropper) {
                if let rawImage = rawImageForCropping {
                    CircularImageCropper(
                        image: rawImage,
                        onCrop: { croppedImage in
                            selectedImage = croppedImage
                            showingCropper = false
                            rawImageForCropping = nil
                            HapticFeedback.success.trigger()
                        },
                        onCancel: {
                            showingCropper = false
                            rawImageForCropping = nil
                        }
                    )
                }
            }
        }
    }

    private var placeholderAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 150, height: 150)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.white.opacity(0.8))
            )
    }

    private func saveAvatar() async {
        guard let image = selectedImage else { return }

        isUploading = true
        errorMessage = nil

        do {
            try await onSave(image)
            HapticFeedback.success.trigger()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.error.trigger()
        }

        isUploading = false
    }
}

// MARK: - Preview

#Preview {
    AvatarEditorView(
        selectedImage: .constant(nil),
        currentAvatarUrl: nil,
        onSave: { _ in }
    )
}

import SwiftUI
import PhotosUI

struct PhotoUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService
    @StateObject private var photoService = PhotoService.shared

    let mountainId: String
    let webcamId: String?

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var caption = ""
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Image preview or picker button
                    if let image = selectedImage {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 300)
                                .clipped()
                                .cornerRadius(.cornerRadiusCard)

                            Button {
                                selectedImage = nil
                                selectedItem = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .background(
                                        Circle()
                                            .fill(.black.opacity(0.5))
                                    )
                            }
                            .padding(8)
                        }
                        .padding(.horizontal)
                    } else {
                        VStack(spacing: 16) {
                            // Camera button
                            Button {
                                showCamera = true
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                    Text("Take Photo")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .background(Color(.systemGray6))
                                .cornerRadius(.cornerRadiusCard)
                            }
                            .foregroundStyle(.primary)

                            // Photo library button
                            Button {
                                showPhotoPicker = true
                            } label: {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 40))
                                    Text("Choose from Library")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .background(Color(.systemGray6))
                                .cornerRadius(.cornerRadiusCard)
                            }
                            .foregroundStyle(.primary)
                        }
                        .padding(.horizontal)
                    }

                    // Caption input
                    if selectedImage != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Caption (optional)")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            TextField("Add a caption...", text: $caption, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                        }
                        .padding(.horizontal)
                    }

                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    // Upload progress
                    if photoService.isUploading {
                        VStack(spacing: 8) {
                            ProgressView(value: photoService.uploadProgress)
                                .progressViewStyle(.linear)
                            Text("Uploading... \(Int(photoService.uploadProgress * 100))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Upload Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(photoService.isUploading)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Upload") {
                        Task {
                            await uploadPhoto()
                        }
                    }
                    .disabled(selectedImage == nil || photoService.isUploading)
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera, selectedImage: $selectedImage)
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedItem,
                matching: .images
            )
            .onChange(of: selectedItem) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
        }
    }

    private func uploadPhoto() async {
        guard let image = selectedImage else { return }

        errorMessage = nil

        do {
            _ = try await photoService.uploadPhoto(
                image: image,
                mountainId: mountainId,
                webcamId: webcamId,
                caption: caption.isEmpty ? nil : caption
            )

            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// UIKit wrapper for camera
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    PhotoUploadView(mountainId: "baker", webcamId: nil)
        .environment(AuthService.shared)
}

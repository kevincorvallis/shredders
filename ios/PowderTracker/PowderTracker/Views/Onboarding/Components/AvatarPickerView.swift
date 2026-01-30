//
//  AvatarPickerView.swift
//  PowderTracker
//
//  Circular avatar picker with camera badge.
//

import SwiftUI
import PhotosUI

struct AvatarPickerView: View {
    @Binding var selectedImage: UIImage?
    @Binding var selectedItem: PhotosPickerItem?
    var isUploading: Bool = false

    private let size: CGFloat = 120

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                // Avatar circle
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: size, height: size)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                        )
                }

                // Camera badge
                Circle()
                    .fill(Color.blue)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Group {
                            if isUploading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white)
                            }
                        }
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .offset(x: size / 2 - 18, y: size / 2 - 18)

                // Border
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 3)
                    .frame(width: size, height: size)
            }
        }
        .disabled(isUploading)
        .accessibilityLabel("Profile photo picker")
        .accessibilityHint(selectedImage != nil ? "Double tap to change photo" : "Double tap to add photo")
    }
}

#Preview("Empty") {
    AvatarPickerView(
        selectedImage: .constant(nil),
        selectedItem: .constant(nil)
    )
}

#Preview("With Image") {
    AvatarPickerView(
        selectedImage: .constant(UIImage(systemName: "person.circle.fill")),
        selectedItem: .constant(nil)
    )
}

#Preview("Uploading") {
    AvatarPickerView(
        selectedImage: .constant(UIImage(systemName: "person.circle.fill")),
        selectedItem: .constant(nil),
        isUploading: true
    )
}

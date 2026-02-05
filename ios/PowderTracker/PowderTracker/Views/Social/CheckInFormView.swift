import SwiftUI
import PhotosUI

struct CheckInFormView: View {
    let mountainId: String
    let onCheckInCreated: ((CheckIn) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService

    @State private var tripReport = ""
    @State private var rating: Int? = nil
    @State private var selectedSnowQuality: SnowQuality? = nil
    @State private var selectedCrowdLevel: CrowdLevel? = nil
    @State private var isPublic = true
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    // Photo + AI classification
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhoto: UIImage? = nil
    @State private var classificationResult: SnowClassification? = nil
    @State private var isClassifying = false
    @State private var snowQualityIsAISuggested = false

    var body: some View {
        NavigationStack {
            Form {
                // Rating Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overall Rating")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { value in
                                Button {
                                    rating = value
                                } label: {
                                    Text("\(value)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .frame(width: 50, height: 50)
                                        .background(rating == value ? Color.blue : Color(.systemGray6))
                                        .foregroundStyle(rating == value ? .white : .primary)
                                        .cornerRadius(.cornerRadiusButton)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Rating")
                }

                // Photo Section (with AI snow classifier)
                Section {
                    photoPickerSection
                } header: {
                    Text("Photo")
                } footer: {
                    Text("Optional - Add a slope photo to auto-detect snow conditions")
                }

                // Conditions Section
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Picker("Snow Quality", selection: Binding(
                            get: { selectedSnowQuality },
                            set: { newValue in
                                selectedSnowQuality = newValue
                                snowQualityIsAISuggested = false
                            }
                        )) {
                            Text("Select...").tag(nil as SnowQuality?)
                            ForEach(SnowQuality.allCases, id: \.self) { quality in
                                Text(quality.displayName).tag(quality as SnowQuality?)
                            }
                        }

                        if selectedSnowQuality != nil {
                            HStack(spacing: 4) {
                                Image(systemName: snowQualityIsAISuggested ? "sparkles" : "hand.tap")
                                    .font(.caption2)
                                Text(snowQualityIsAISuggested ? "AI suggested" : "Manual")
                                    .font(.caption2)
                            }
                            .foregroundStyle(snowQualityIsAISuggested ? .blue : .secondary)
                        }
                    }

                    Picker("Crowd Level", selection: $selectedCrowdLevel) {
                        Text("Select...").tag(nil as CrowdLevel?)
                        ForEach(CrowdLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level as CrowdLevel?)
                        }
                    }
                } header: {
                    Text("Conditions")
                }

                // Trip Report Section
                Section {
                    ZStack(alignment: .topLeading) {
                        if tripReport.isEmpty {
                            Text("Share your experience...")
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                        }

                        TextEditor(text: $tripReport)
                            .frame(minHeight: 120)
                            .opacity(tripReport.isEmpty ? 0.5 : 1)
                    }

                    HStack {
                        Spacer()
                        Text("\(tripReport.count)/5000")
                            .font(.caption)
                            .foregroundStyle(tripReport.count > 5000 ? .red : .secondary)
                    }
                } header: {
                    Text("Trip Report")
                } footer: {
                    Text("Optional - Share details about your experience")
                }

                // Visibility Section
                Section {
                    Toggle("Make this check-in public", isOn: $isPublic)
                } footer: {
                    Text("Public check-ins are visible to all users")
                }

                // Error message
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Check In") {
                        Task {
                            await submitCheckIn()
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
        }
    }

    // MARK: - Photo Picker + AI Classification

    @ViewBuilder
    private var photoPickerSection: some View {
        if let photo = selectedPhoto {
            // Show selected photo with remove button
            VStack(spacing: 8) {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack {
                    if isClassifying {
                        ProgressView()
                            .controlSize(.small)
                        Text("Analyzing snow conditions...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let result = classificationResult {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Text("Detected: \(result.quality.displayName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("(\(Int(result.confidence * 100))%)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Spacer()

                    Button(role: .destructive) {
                        withAnimation {
                            selectedPhoto = nil
                            selectedPhotoItem = nil
                            classificationResult = nil
                            if snowQualityIsAISuggested {
                                selectedSnowQuality = nil
                                snowQualityIsAISuggested = false
                            }
                        }
                    } label: {
                        Label("Remove", systemImage: "xmark.circle.fill")
                            .font(.caption)
                    }
                }
            }
        } else {
            // Photo picker button
            PhotosPicker(
                selection: $selectedPhotoItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    Text("Add Slope Photo")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    await loadAndClassifyPhoto(newItem)
                }
            }
        }
    }

    private func loadAndClassifyPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }

        // Load the image data
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            return
        }

        selectedPhoto = image

        // Run the classifier
        isClassifying = true
        let result = await SnowConditionClassifier.shared.classify(image)
        isClassifying = false

        classificationResult = result

        // Auto-populate snow quality if confidence is good and user hasn't manually selected
        if let result, selectedSnowQuality == nil {
            selectedSnowQuality = result.quality
            snowQualityIsAISuggested = true
        }
    }

    // MARK: - Submit

    private func submitCheckIn() async {
        guard authService.isAuthenticated else {
            errorMessage = "Please sign in to check in"
            return
        }

        if tripReport.count > 5000 {
            errorMessage = "Trip report must be less than 5000 characters"
            return
        }

        isSubmitting = true
        errorMessage = nil

        do {
            let checkIn = try await CheckInService.shared.createCheckIn(
                mountainId: mountainId,
                tripReport: tripReport.isEmpty ? nil : tripReport,
                rating: rating,
                snowQuality: selectedSnowQuality?.rawValue,
                crowdLevel: selectedCrowdLevel?.rawValue,
                isPublic: isPublic
            )

            onCheckInCreated?(checkIn)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }

        isSubmitting = false
    }
}

#Preview {
    CheckInFormView(mountainId: "baker", onCheckInCreated: nil)
        .environment(AuthService.shared)
}

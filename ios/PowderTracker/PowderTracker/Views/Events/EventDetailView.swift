import SwiftUI
import CoreImage.CIFilterBuiltins

struct EventDetailView: View {
    let eventId: String

    @Environment(\.dismiss) private var dismiss
    @State private var event: EventWithDetails?
    @State private var isLoading = true
    @State private var error: String?
    @State private var isRSVPing = false
    @State private var showingShareSheet = false
    @State private var showingQRCode = false
    @State private var showingEditSheet = false
    @State private var showingCancelAlert = false
    @State private var currentUserRSVPStatus: RSVPStatus?
    @State private var toast: ToastMessage?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let error = error {
                errorView(message: error)
            } else if let event = event {
                eventContent(event: event)
            }
        }
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Creator menu (edit/cancel)
            if let event = event, event.isCreator == true {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit Event", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showingCancelAlert = true
                        } label: {
                            Label("Cancel Event", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }

            // Share menu
            if let event = event, event.inviteToken != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingShareSheet = true
                        } label: {
                            Label("Share Event", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            showingQRCode = true
                        } label: {
                            Label("Show QR Code", systemImage: "qrcode")
                        }

                        Button {
                            copyLinkToClipboard()
                        } label: {
                            Label("Copy Link", systemImage: "doc.on.doc")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .refreshable {
            await loadEvent()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let token = event?.inviteToken {
                let url = shareURL(token: token)
                ShareSheet(items: [url, shareMessage])
            }
        }
        .sheet(isPresented: $showingQRCode) {
            if let token = event?.inviteToken {
                QRCodeSheet(url: shareURL(token: token), eventTitle: event?.title ?? "Event")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            if let event = event {
                EventEditView(event: event) {
                    Task { await loadEvent() }
                }
            }
        }
        .alert("Cancel Event", isPresented: $showingCancelAlert) {
            Button("Keep Event", role: .cancel) {}
            Button("Cancel Event", role: .destructive) {
                Task { await cancelEvent() }
            }
        } message: {
            Text("Are you sure you want to cancel this event? All attendees will be notified and the event will be removed.")
        }
        .toast($toast)
        .task {
            await loadEvent()
        }
    }

    // MARK: - Computed Properties

    private var shareMessage: String {
        guard let event = event else { return "" }
        return """
        Join me skiing at \(event.mountainName ?? event.mountainId)! 🎿

        \(event.title)
        📅 \(event.formattedDate)
        \(event.formattedTime.map { "⏰ Departing \($0)" } ?? "")
        👥 \(event.goingCount) people going
        """
    }

    private func shareURL(token: String) -> URL {
        URL(string: "\(AppConfig.apiBaseURL.replacingOccurrences(of: "/api", with: ""))/events/invite/\(token)")!
    }

    // MARK: - Subviews

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(message)
                .foregroundStyle(.secondary)
            Button("Retry") {
                Task { await loadEvent() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func eventContent(event: EventWithDetails) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Event Info Card
                eventInfoCard(event: event)

                // Forecast Card (for event day)
                if let forecast = event.conditions?.forecast {
                    forecastCard(forecast: forecast, eventDate: event.eventDate)
                }

                // Current Conditions Card
                if let conditions = event.conditions {
                    conditionsCard(conditions: conditions)
                }

                // Attendees Card
                attendeesCard(event: event)

                // RSVP Buttons
                if event.isCreator != true {
                    rsvpButtons(event: event)
                }
            }
            .padding()
        }
    }

    private func eventInfoCard(event: EventWithDetails) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(event.title)
                .font(.title2)
                .fontWeight(.bold)

            Label(event.mountainName ?? event.mountainId, systemImage: "mountain.2.fill")
                .font(.headline)
                .foregroundStyle(.blue)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Label(event.formattedDate, systemImage: "calendar")

                if let time = event.formattedTime {
                    Label("Departing at \(time)", systemImage: "clock")
                }

                if let location = event.departureLocation {
                    Label(location, systemImage: "mappin.and.ellipse")
                }

                if let level = event.skillLevel {
                    Label(level.displayName, systemImage: "speedometer")
                }

                if event.carpoolAvailable {
                    Label("Carpool available (\(event.carpoolSeats ?? 0) seats)", systemImage: "car.fill")
                        .foregroundStyle(.green)
                }
            }
            .foregroundStyle(.secondary)

            if let notes = event.notes {
                Divider()
                Text(notes)
                    .font(.body)
            }

            Divider()

            // Organizer
            HStack(spacing: 12) {
                Circle()
                    .fill(.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(String(event.creator.displayNameOrUsername.prefix(1)))
                            .foregroundStyle(.blue)
                            .fontWeight(.semibold)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Organized by")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(event.creator.displayNameOrUsername)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Forecast Card (NEW)

    private func forecastCard(forecast: EventForecast, eventDate: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "cloud.snow.fill")
                    .foregroundStyle(.cyan)
                Text("Forecast for \(formatEventDate(eventDate))")
                    .font(.headline)
            }

            HStack(spacing: 0) {
                // High temp
                VStack(spacing: 4) {
                    Text("\(Int(forecast.high))°")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    Text("High")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Low temp
                VStack(spacing: 4) {
                    Text("\(Int(forecast.low))°")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    Text("Low")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Snowfall
                VStack(spacing: 4) {
                    HStack(spacing: 2) {
                        Text("\(Int(forecast.snowfall))\"")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.cyan)
                        if forecast.snowfall >= 6 {
                            Image(systemName: "snowflake")
                                .font(.caption)
                                .foregroundStyle(.cyan)
                        }
                    }
                    Text("Snow")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            // Conditions banner
            HStack {
                Text(weatherIcon(for: forecast.conditions))
                    .font(.title2)
                Text(forecast.conditions)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()

                // Powder day indicator
                if forecast.snowfall >= 6 {
                    Text("Powder Day!")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.cyan)
                        .clipShape(Capsule())
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatEventDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else { return dateString }
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }

    private func weatherIcon(for conditions: String) -> String {
        let lowercased = conditions.lowercased()
        if lowercased.contains("snow") || lowercased.contains("blizzard") { return "❄️" }
        if lowercased.contains("rain") { return "🌧️" }
        if lowercased.contains("cloud") { return "☁️" }
        if lowercased.contains("sun") || lowercased.contains("clear") { return "☀️" }
        if lowercased.contains("wind") { return "💨" }
        if lowercased.contains("fog") { return "🌫️" }
        return "🌤️"
    }

    private func conditionsCard(conditions: EventConditions) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Conditions")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                if let score = conditions.powderScore {
                    conditionItem(
                        label: "Powder Score",
                        value: String(format: "%.1f", score),
                        color: powderScoreColor(score)
                    )
                }
                if let snow = conditions.snowfall24h {
                    conditionItem(
                        label: "24h Snowfall",
                        value: "\(Int(snow))\"",
                        color: .cyan
                    )
                }
                if let temp = conditions.temperature {
                    conditionItem(
                        label: "Temperature",
                        value: "\(Int(temp))°F",
                        color: .primary
                    )
                }
                if let depth = conditions.snowDepth {
                    conditionItem(
                        label: "Snow Depth",
                        value: "\(Int(depth))\"",
                        color: .primary
                    )
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func powderScoreColor(_ score: Double) -> Color {
        switch score {
        case 8...: return .green
        case 6..<8: return .blue
        case 4..<6: return .orange
        default: return .secondary
        }
    }

    private func conditionItem(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
    }

    private func attendeesCard(event: EventWithDetails) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Who's Going")
                    .font(.headline)

                Spacer()

                Text("\(event.goingCount) going, \(event.maybeCount) maybe")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if event.attendees.isEmpty {
                Text("No attendees yet")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                // Overlapping avatars for compact display
                HStack(spacing: -8) {
                    ForEach(event.attendees.prefix(5)) { attendee in
                        Circle()
                            .fill(attendee.status == .going ? .blue.opacity(0.2) : .orange.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .overlay {
                                Text(String(attendee.user.displayNameOrUsername.prefix(1)))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            )
                    }

                    if event.attendees.count > 5 {
                        Circle()
                            .fill(.gray.opacity(0.3))
                            .frame(width: 36, height: 36)
                            .overlay {
                                Text("+\(event.attendees.count - 5)")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 2)
                            )
                    }

                    Spacer()
                }
                .padding(.vertical, 4)

                // Full list
                ForEach(event.attendees) { attendee in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(.gray.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay {
                                Text(String(attendee.user.displayNameOrUsername.prefix(1)))
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }

                        Text(attendee.user.displayNameOrUsername)
                            .font(.subheadline)

                        Spacer()

                        HStack(spacing: 8) {
                            if attendee.isDriver {
                                Label("Driver", systemImage: "car.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.green.opacity(0.1))
                                    .clipShape(Capsule())
                            }

                            if attendee.needsRide {
                                Text("Needs ride")
                                    .font(.caption2)
                                    .foregroundStyle(.purple)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.purple.opacity(0.1))
                                    .clipShape(Capsule())
                            }

                            Text(attendee.status.displayName)
                                .font(.caption2)
                                .foregroundStyle(attendee.status == .going ? .blue : .orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(attendee.status == .going ? .blue.opacity(0.1) : .orange.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func rsvpButtons(event: EventWithDetails) -> some View {
        HStack(spacing: 16) {
            Button {
                Task { await rsvp(status: .going) }
            } label: {
                HStack {
                    if currentUserRSVPStatus == .going {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text("I'm In!")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(currentUserRSVPStatus == .going ? .green : .green.opacity(0.2))
                .foregroundStyle(currentUserRSVPStatus == .going ? .white : .green)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isRSVPing)

            Button {
                Task { await rsvp(status: .maybe) }
            } label: {
                HStack {
                    if currentUserRSVPStatus == .maybe {
                        Image(systemName: "questionmark.circle.fill")
                    }
                    Text("Maybe")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(currentUserRSVPStatus == .maybe ? .orange : .orange.opacity(0.2))
                .foregroundStyle(currentUserRSVPStatus == .maybe ? .white : .orange)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isRSVPing)
        }
    }

    // MARK: - Actions

    private func copyLinkToClipboard() {
        guard let token = event?.inviteToken else { return }
        UIPasteboard.general.url = shareURL(token: token)
        HapticFeedback.success.trigger()
        toast = ToastMessage(
            type: .success,
            title: "Link Copied",
            message: "Share link copied to clipboard"
        )
    }

    private func loadEvent() async {
        isLoading = event == nil
        error = nil

        do {
            let loadedEvent = try await EventService.shared.fetchEvent(id: eventId)
            event = loadedEvent
            currentUserRSVPStatus = loadedEvent.userRSVPStatus
        } catch let err as EventServiceError {
            error = err.localizedDescription
        } catch {
            self.error = "Failed to load event"
        }

        isLoading = false
    }

    private func rsvp(status: RSVPStatus) async {
        isRSVPing = true
        HapticFeedback.light.trigger()

        do {
            let response = try await EventService.shared.rsvp(eventId: eventId, status: status)
            currentUserRSVPStatus = response.attendee.status
            HapticFeedback.success.trigger()
            toast = ToastMessage(
                type: .success,
                title: status == .going ? "You're in!" : "Got it!",
                message: status == .going ? "See you on the mountain!" : "We'll keep you posted"
            )
        } catch let err as EventServiceError {
            HapticFeedback.error.trigger()
            toast = ToastMessage(
                type: .error,
                title: "Couldn't update RSVP",
                message: err.localizedDescription
            )
        } catch {
            HapticFeedback.error.trigger()
            toast = ToastMessage(
                type: .error,
                title: "Couldn't update RSVP",
                message: "Please try again"
            )
        }

        isRSVPing = false
        await loadEvent()
    }

    private func cancelEvent() async {
        do {
            try await EventService.shared.cancelEvent(id: eventId)
            HapticFeedback.success.trigger()
            dismiss()
        } catch let err as EventServiceError {
            HapticFeedback.error.trigger()
            toast = ToastMessage(
                type: .error,
                title: "Couldn't cancel event",
                message: err.localizedDescription
            )
        } catch {
            HapticFeedback.error.trigger()
            toast = ToastMessage(
                type: .error,
                title: "Couldn't cancel event",
                message: "Please try again"
            )
        }
    }
}

// MARK: - QR Code Sheet

struct QRCodeSheet: View {
    let url: URL
    let eventTitle: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Scan to Join")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(eventTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Image(uiImage: generateQRCode(from: url.absoluteString))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .padding(16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)

                Text("Share this QR code with friends")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    saveQRCode()
                } label: {
                    Label("Save to Photos", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 32)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func generateQRCode(from string: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)

            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }

        return UIImage(systemName: "qrcode") ?? UIImage()
    }

    private func saveQRCode() {
        let image = generateQRCode(from: url.absoluteString)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        HapticFeedback.success.trigger()
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        EventDetailView(eventId: "preview-id")
    }
}

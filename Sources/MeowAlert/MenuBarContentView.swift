import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct MenuBarContentView: View {
    @ObservedObject var monitor: AlertMonitor
    @ObservedObject var settings: SettingsStore
    @StateObject private var cityCatalog = CityCatalog()
    @State private var cityQuery = ""
    @State private var isManagingCities = false
    @State private var isAlertPulseActive = false
    @State private var isHowItWorksPresented = false
    @State private var isUsagePresented = false
    @State private var isDevelopmentMode = false
    @State private var soundImportMessage: String?

    private var availableSounds: [AlertSoundOption] {
        AlertSoundCatalog.availableSounds()
    }

    var body: some View {
        panelContent
            .padding(16)
            .frame(width: 348)
            .background(panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(panelBorder)
            .tint(Color(red: 0.92, green: 0.14, blue: 0.12))
            .onAppear {
                updateAlertPulse(isAlerting: monitor.status == .alert)
            }
            .onChange(of: monitor.status) { newValue in
                updateAlertPulse(isAlerting: newValue == .alert)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.88), value: isManagingCities)
    }

    private var panelContent: some View {
        VStack(alignment: .trailing, spacing: 14) {
            statusSection
            contentSection
            watchedAreasSection
            soundSection
            developmentModeSection
            actionsSection
            footerSection
        }
    }

    private var watchedAreasSection: some View {
        WatchedAreasCard(
            settings: settings,
            cityCatalog: cityCatalog,
            cityQuery: $cityQuery,
            isExpanded: $isManagingCities
        )
    }

    private var statusSection: some View {
        StatusCard(
            title: statusTitle,
            icon: statusIcon,
            palette: statusPalette,
            watchedCityCount: settings.watchedCities.count,
            isMonitoring: Binding(
                get: { monitor.isMonitoring },
                set: { newValue in
                    guard newValue != monitor.isMonitoring else { return }
                    toggleMonitoring()
                }
            ),
            lastPollAt: monitor.lastPollAt,
            message: monitor.statusMessage,
            messageKind: monitor.statusMessageKind,
            isPulsing: monitor.status == .alert && isAlertPulseActive
        )
    }

    @ViewBuilder
    private var contentSection: some View {
        if let alert = monitor.activeAlert, !monitor.matchingCities.isEmpty {
            AlertCard(alert: alert, matchingCities: monitor.matchingCities)
        } else {
            EmptyStateCard(pollingIntervalSeconds: settings.pollingIntervalSeconds)
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        if isDevelopmentMode {
            VStack(alignment: .trailing, spacing: 10) {
                secondaryActionRow
                pollingIntervalControl
            }
        }
    }

    private var soundSection: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack {
                Label("צליל", systemImage: "speaker.wave.2.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Toggle("", isOn: $settings.soundEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
            }

            VStack(alignment: .trailing, spacing: 8) {
                Picker("", selection: $settings.selectedAlertSoundFileName) {
                    ForEach(availableSounds) { sound in
                        Text(sound.displayName)
                            .tag(sound.fileName)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .environment(\.layoutDirection, .rightToLeft)
                .disabled(!settings.soundEnabled || availableSounds.isEmpty)

                HStack {
                    Button("העלאת MP3") {
                        openMP3Panel()
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer(minLength: 0)
                }

                if let soundImportMessage, !soundImportMessage.isEmpty {
                    Text(soundImportMessage)
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.72))
                } else if availableSounds.isEmpty {
                    Text("אין צלילים זמינים באפליקציה.")
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.6))
                } else if !settings.soundEnabled {
                    Text("הפעילו צליל כדי לבחור צליל התראה.")
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.6))
                } else {
                    Text("הצליל יושמע בעת התראה")
                        .font(.caption2)
                        .foregroundStyle(Color.white.opacity(0.6))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(Color.white.opacity(0.05))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var secondaryActionRow: some View {
        ActionRowButton(
            title: "התראת בדיקה",
            systemImage: "bell.badge",
            prominence: .secondary,
            action: sendTestAlert
        )
    }

    private var pollingIntervalControl: some View {
        VStack(alignment: .trailing, spacing: 10) {
            HStack(spacing: 8) {
                Label("מרווח בדיקת התראה", systemImage: "timer")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.88))

                Spacer(minLength: 0)

                Text(formattedPollingInterval(settings.pollingIntervalSeconds))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.88, green: 0.20, blue: 0.16).opacity(0.9))
                    .clipShape(Capsule())
            }

            Text("זמן קצר יותר = בדיקות תכופות יותר ועומס גבוה יותר.")
                .font(.caption2)
                .foregroundStyle(Color.white.opacity(0.62))
                .frame(maxWidth: .infinity, alignment: .trailing)

            Slider(
                value: $settings.pollingIntervalSeconds,
                in: 2...20,
                step: 1
            )
            .tint(Color(red: 0.90, green: 0.19, blue: 0.16))

            HStack {
                Text("2 שנ׳")
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.52))

                Spacer(minLength: 0)

                Text("20 שנ׳")
                    .font(.caption2)
                    .foregroundStyle(Color.white.opacity(0.52))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(Color.white.opacity(0.05))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var developmentModeSection: some View {
        HStack {
            HStack(spacing: 10) {
                Toggle("", isOn: $isDevelopmentMode)
                    .labelsHidden()
                    .toggleStyle(.switch)

                Text("מצב פיתוח")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.05))
            .overlay {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            }
            .clipShape(Capsule())

            Spacer(minLength: 0)
        }
    }

    private var footerSection: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                Button {
                    isHowItWorksPresented.toggle()
                } label: {
                    Label("איך זה עובד", systemImage: "info.circle")
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(red: 0.47, green: 0.22, blue: 0.21))
                .popover(isPresented: $isHowItWorksPresented, arrowEdge: .bottom) {
                    HowItWorksPopover()
                }

                Button {
                    isUsagePresented.toggle()
                } label: {
                    Label("אופן השימוש", systemImage: "list.bullet.circle")
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color(red: 0.47, green: 0.22, blue: 0.21))
                .popover(isPresented: $isUsagePresented, arrowEdge: .bottom) {
                    UsagePopover()
                }

                Spacer()

                Button("יציאה", role: .destructive, action: quitApp)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color(red: 0.96, green: 0.32, blue: 0.28))
            }
            .padding(.top, 12)
        }
    }

    private var panelBorder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
    }

    private var panelBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.10, green: 0.14, blue: 0.20),
                Color(red: 0.04, green: 0.08, blue: 0.14)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var statusTitle: String {
        switch monitor.status {
        case .idle:
            return "לא פעיל"
        case .monitoring:
            return "ניטור פעיל"
        case .alert:
            return "צבע אדום"
        case .error:
            return "שגיאת חיבור"
        }
    }

    private var statusIcon: String {
        switch monitor.status {
        case .idle:
            return "pause.circle"
        case .monitoring:
            return "dot.radiowaves.left.and.right"
        case .alert:
            return "exclamationmark.triangle.fill"
        case .error:
            return "wifi.slash"
        }
    }

    private var statusPalette: StatusPalette {
        switch monitor.status {
        case .idle:
            return StatusPalette(
                background: Color(red: 0.13, green: 0.18, blue: 0.25),
                border: Color.white.opacity(0.08),
                badgeFill: Color(red: 0.28, green: 0.33, blue: 0.40),
                badgeForeground: .white,
                secondaryText: Color(red: 0.78, green: 0.81, blue: 0.87)
            )
        case .monitoring:
            return StatusPalette(
                background: Color(red: 0.13, green: 0.18, blue: 0.25),
                border: Color(red: 0.92, green: 0.14, blue: 0.12).opacity(0.25),
                badgeFill: Color(red: 0.87, green: 0.16, blue: 0.13),
                badgeForeground: .white,
                secondaryText: Color(red: 0.84, green: 0.85, blue: 0.89)
            )
        case .alert:
            return StatusPalette(
                background: Color(red: 0.20, green: 0.07, blue: 0.08),
                border: Color(red: 0.97, green: 0.19, blue: 0.16).opacity(0.45),
                badgeFill: Color(red: 0.95, green: 0.16, blue: 0.14),
                badgeForeground: .white,
                secondaryText: Color(red: 0.95, green: 0.86, blue: 0.86)
            )
        case .error:
            return StatusPalette(
                background: Color(red: 0.19, green: 0.14, blue: 0.10),
                border: Color(red: 0.90, green: 0.68, blue: 0.27).opacity(0.35),
                badgeFill: Color(red: 0.90, green: 0.68, blue: 0.27),
                badgeForeground: Color(red: 0.18, green: 0.11, blue: 0.03),
                secondaryText: Color(red: 0.93, green: 0.86, blue: 0.72)
            )
        }
    }

    private func updateAlertPulse(isAlerting: Bool) {
        if isAlerting {
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                isAlertPulseActive = true
            }
        } else {
            isAlertPulseActive = false
        }
    }

    private func toggleMonitoring() {
        monitor.toggleMonitoring()
    }

    private func sendTestAlert() {
        Task {
            await monitor.sendTestNotification()
        }
    }

    private func openMP3Panel() {
        NSApp.activate(ignoringOtherApps: true)

        let panel = NSOpenPanel()
        panel.title = "בחרו קובץ MP3"
        panel.message = "הקובץ יישמר כאפשרות צליל התראה."
        panel.prompt = "בחירה"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.mp3]

        guard panel.runModal() == .OK, let sourceURL = panel.url else { return }
        do {
            let importedOption = try AlertSoundCatalog.importCustomMP3(from: sourceURL)
            settings.selectedAlertSoundFileName = importedOption.fileName
            soundImportMessage = "צליל חדש נוסף ונבחר."
        } catch {
            soundImportMessage = error.localizedDescription
        }
    }

    private func formattedPollingInterval(_ seconds: Double) -> String {
        "כל \(Int(seconds.rounded())) שניות"
    }

    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

private struct WatchedAreasCard: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var cityCatalog: CityCatalog
    @Binding var cityQuery: String
    @Binding var isExpanded: Bool
    @FocusState private var isSearchFocused: Bool

    private let selectedColumns = [
        GridItem(.adaptive(minimum: 110), spacing: 8, alignment: .trailing)
    ]

    private var trimmedCityQuery: String {
        cityQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canAddTypedCity: Bool {
        cityCatalog.isKnownCity(cityQuery)
    }

    private var citySuggestions: [String] {
        guard !trimmedCityQuery.isEmpty else { return [] }
        return Array(
            cityCatalog
                .suggestions(for: cityQuery, excluding: settings.watchedCities)
                .prefix(6)
        )
    }

    private var suggestionsListHeight: CGFloat {
        let rowHeight: CGFloat = 37
        let dividerHeight = max(0, citySuggestions.count - 1)
        let visibleHeight = CGFloat(citySuggestions.count) * rowHeight + CGFloat(dividerHeight)
        return min(max(visibleHeight, rowHeight), 96)
    }

    private var collapsedPreviewCities: [String] {
        Array(settings.watchedCities.prefix(2))
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            header

            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                collapsedPreview
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(Color.white.opacity(0.05))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture {
            guard !isExpanded else { return }
            toggleExpandedState()
        }
        .onChange(of: isExpanded) { newValue in
            if newValue {
                DispatchQueue.main.async {
                    isSearchFocused = true
                }
            } else {
                cityQuery = ""
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 6) {
                Text("אזורים במעקב")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text("\(settings.watchedCities.count) נבחרו")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.70))
            }
            .lineLimit(1)

            Spacer()

            Button {
                toggleExpandedState()
            } label: {
                HStack(spacing: 6) {
                    Text(isExpanded ? "הסתר" : "עוד")
                        .font(.caption.weight(.semibold))
                    Image(systemName: "chevron.left")
                        .font(.caption2.weight(.bold))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.09))
                .overlay {
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                }
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var collapsedPreview: some View {
        if collapsedPreviewCities.isEmpty {
            Text("הוסיפו לפחות עיר אחת כדי לקבל התראות תואמות.")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.68))
                .multilineTextAlignment(.trailing)
        } else {
            HStack(spacing: 8) {
                Spacer(minLength: 0)

                ForEach(collapsedPreviewCities, id: \.self) { city in
                    Text(city)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundStyle(.white)
                        .background(Color.white.opacity(0.08))
                        .overlay {
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                        }
                        .clipShape(Capsule())
                }

                let remainingCount = settings.watchedCities.count - collapsedPreviewCities.count
                if remainingCount > 0 {
                    Text("+עוד \(remainingCount)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.82))
                }
            }
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .trailing, spacing: 12) {
            searchRow
            suggestionsSection
            selectedAreasSection
        }
    }

    private var searchRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField("חיפוש עיר", text: $cityQuery)
                    .textFieldStyle(.plain)
                    .focused($isSearchFocused)
                    .multilineTextAlignment(.trailing)
                    .onSubmit {
                        addTypedCity()
                    }

                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.white.opacity(0.65))
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(Color.white.opacity(0.06))
            .overlay {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            Button {
                addTypedCity()
            } label: {
                Label("הוספה", systemImage: "plus")
                    .font(.caption.weight(.semibold))
                    .frame(minWidth: 68, minHeight: 36)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canAddTypedCity)
        }
    }

    private var selectedAreasSection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Text("אזורים שנבחרו")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(settings.watchedCities.count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.70))
            }

            if settings.watchedCities.isEmpty {
                Text("הוסיפו לפחות עיר אחת כדי לקבל התראות תואמות.")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.68))
            } else {
                ScrollView {
                    LazyVGrid(columns: selectedColumns, alignment: .trailing, spacing: 8) {
                        ForEach(settings.watchedCities, id: \.self) { city in
                            EditableCityChip(city: city) {
                                settings.removeCity(city)
                            }
                        }
                    }
                }
                .frame(minHeight: 72, maxHeight: 110)
            }
        }
    }

    @ViewBuilder
    private var suggestionsSection: some View {
        if citySuggestions.isEmpty {
            if trimmedCityQuery.isEmpty {
                Text("התחילו להקליד כדי לראות אזורים תואמים.")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.68))
                    .multilineTextAlignment(.trailing)
            } else if !canAddTypedCity {
                Text("עדיין אין התאמה מדויקת לעיר. המשיכו להקליד כדי לצמצם.")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.68))
                    .multilineTextAlignment(.trailing)
            }
        } else {
            VStack(alignment: .trailing, spacing: 7) {
                Text("הצעות")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(citySuggestions.enumerated()), id: \.element) { index, city in
                            SuggestionRow(city: city) {
                                settings.addCity(city)
                                cityQuery = ""
                                isSearchFocused = true
                            }

                            if index < citySuggestions.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
                .frame(height: suggestionsListHeight)
                .background(Color.white.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private func addTypedCity() {
        guard canAddTypedCity else { return }
        settings.addCity(cityQuery)
        cityQuery = ""
        isSearchFocused = true
    }

    private func toggleExpandedState() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.88)) {
            isExpanded.toggle()
        }
    }
}

private struct EditableCityChip: View {
    let city: String
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Text(city)
                .font(.caption.weight(.medium))
                .lineLimit(1)
                .foregroundStyle(.white)
            Button(action: remove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color(red: 0.68, green: 0.24, blue: 0.22))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("הסרה של \(city)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.08))
        .overlay {
            Capsule()
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        }
        .clipShape(Capsule())
    }
}

private struct SuggestionRow: View {
    let city: String
    let add: () -> Void

    var body: some View {
        Button(action: add) {
            HStack {
                Text(city)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color(red: 0.92, green: 0.14, blue: 0.12))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("הוספה של \(city)")
    }
}

private struct StatusPalette {
    let background: Color
    let border: Color
    let badgeFill: Color
    let badgeForeground: Color
    let secondaryText: Color
}

private struct StatusCard: View {
    let title: String
    let icon: String
    let palette: StatusPalette
    let watchedCityCount: Int
    @Binding var isMonitoring: Bool
    let lastPollAt: Date?
    let message: String?
    let messageKind: AlertMonitor.StatusMessageKind?
    let isPulsing: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                HStack(spacing: 7) {
                    Image(systemName: icon)
                        .imageScale(.medium)
                        .scaleEffect(isPulsing ? 1.06 : 1.0)
                    Text(title)
                        .font(.caption.weight(.semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(palette.badgeFill)
                .foregroundStyle(palette.badgeForeground)
                .clipShape(Capsule())
                .accessibilityLabel("סטטוס \(title)")

                Spacer()

                Toggle("", isOn: $isMonitoring)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .accessibilityLabel(isMonitoring ? "כיבוי ניטור" : "הפעלת ניטור")
            }

            HStack(spacing: 12) {
                Label {
                    Text("\(watchedCityCount) אזורים במעקב")
                } icon: {
                    Image(systemName: "location")
                }

                Spacer(minLength: 8)

                if let lastPollAt {
                    Text("נבדק לאחרונה \(lastPollAt.formatted(date: .omitted, time: .standard))")
                } else {
                    Text("ממתין לבדיקה ראשונה")
                }
            }
            .font(.caption)
            .foregroundStyle(palette.secondaryText)

            if let message, let messageKind {
                Label {
                    Text(message)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.trailing)
                } icon: {
                    Image(systemName: messageIcon(for: messageKind))
                }
                .font(.caption)
                .foregroundStyle(messageColor(for: messageKind))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(palette.background)
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(palette.border, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func messageIcon(for kind: AlertMonitor.StatusMessageKind) -> String {
        switch kind {
        case .alert:
            return "exclamationmark.shield.fill"
        case .error:
            return "wifi.exclamationmark"
        case .warning:
            return "speaker.wave.2.bubble"
        case .info:
            return "clock.badge.checkmark"
        }
    }

    private func messageColor(for kind: AlertMonitor.StatusMessageKind) -> Color {
        switch kind {
        case .alert:
            return .white
        case .error:
            return Color(red: 0.98, green: 0.86, blue: 0.55)
        case .warning:
            return Color(red: 0.98, green: 0.90, blue: 0.70)
        case .info:
            return palette.secondaryText
        }
    }
}

private struct AlertCard: View {
    let alert: AlertResponse
    let matchingCities: [String]

    private let chipColumns = [
        GridItem(.adaptive(minimum: 90), spacing: 8, alignment: .trailing)
    ]

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            HStack {
                Text(alert.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("פעיל עכשיו")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color(red: 0.99, green: 0.87, blue: 0.87))
            }

            LazyVGrid(columns: chipColumns, alignment: .trailing, spacing: 8) {
                ForEach(matchingCities, id: \.self) { city in
                    Text(city)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .foregroundStyle(.white)
                        .background(Color.white.opacity(0.10))
                        .overlay {
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                        }
                        .clipShape(Capsule())
                }
            }

            Text(alert.desc)
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.94, green: 0.91, blue: 0.91))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.trailing)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.21, green: 0.07, blue: 0.09),
                    Color(red: 0.12, green: 0.05, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(red: 0.96, green: 0.18, blue: 0.15).opacity(0.35), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct EmptyStateCard: View {
    let pollingIntervalSeconds: Double

    private var pollingIntervalText: String {
        "כל \(Int(pollingIntervalSeconds.rounded())) שניות"
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "shield.lefthalf.filled.badge.checkmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.96, green: 0.23, blue: 0.18),
                                Color(red: 0.85, green: 0.14, blue: 0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .trailing, spacing: 4) {
                    Text("כרגע אין התראות באיזורך")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    Text("האפליקציה מחכה להתראה. אפשר להמשיך לעבוד.")
                        .font(.subheadline)
                        .foregroundStyle(Color(red: 0.83, green: 0.86, blue: 0.90))
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                Text("בדיקה מול פיקוד העורף")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 0.98, green: 0.90, blue: 0.89))
                Circle()
                    .fill(Color(red: 0.95, green: 0.20, blue: 0.16))
                    .frame(width: 6, height: 6)
                Text(pollingIntervalText)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.75))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.20, blue: 0.28),
                    Color(red: 0.11, green: 0.16, blue: 0.24)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private enum ActionButtonProminence {
    case primary
    case secondary
}

private struct ActionRowButton: View {
    let title: String
    let systemImage: String
    let prominence: ActionButtonProminence
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 34)
        }
        .buttonStyle(ActionRowButtonStyle(prominence: prominence))
    }
}

private struct ActionRowButtonStyle: ButtonStyle {
    let prominence: ActionButtonProminence

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .background(background(isPressed: configuration.isPressed))
            .foregroundStyle(foreground)
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(border, lineWidth: prominence == .primary ? 0 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
    }

    private var foreground: Color {
        switch prominence {
        case .primary:
            return .white
        case .secondary:
            return .white
        }
    }

    private var border: Color {
        Color.white.opacity(0.10)
    }

    private func background(isPressed: Bool) -> Color {
        switch prominence {
        case .primary:
            return isPressed
                ? Color(red: 0.81, green: 0.12, blue: 0.11)
                : Color(red: 0.92, green: 0.14, blue: 0.12)
        case .secondary:
            return isPressed
                ? Color.white.opacity(0.10)
                : Color.white.opacity(0.06)
        }
    }
}

private struct HowItWorksPopover: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Label("איך זה עובד", systemImage: "dot.radiowaves.left.and.right")
                .font(.headline)
                .foregroundStyle(Color(red: 0.47, green: 0.22, blue: 0.21))

            Text("האפליקציה בודקת את פיד ההתראות של פיקוד העורף כל כמה שניות, משווה שמות ערים מול האזורים שבמעקב שלכם, ושולחת התראה מקומית כשיש התאמה.")
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.32, green: 0.24, blue: 0.24))
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.trailing)
        }
        .padding(16)
        .frame(width: 280, alignment: .trailing)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.97, blue: 0.97),
                    Color(red: 0.97, green: 0.93, blue: 0.93)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

private struct UsagePopover: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            Label("אופן השימוש", systemImage: "list.bullet.circle")
                .font(.headline)
                .foregroundStyle(Color(red: 0.47, green: 0.22, blue: 0.21))

            Text("1. בחרו ערים למעקב.\n2. ודאו שהניטור פעיל.\n3. תקבלו התראה בזמן אמת")
                .font(.subheadline)
                .foregroundStyle(Color(red: 0.32, green: 0.24, blue: 0.24))
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(width: 290, alignment: .trailing)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.97, blue: 0.97),
                    Color(red: 0.97, green: 0.93, blue: 0.93)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

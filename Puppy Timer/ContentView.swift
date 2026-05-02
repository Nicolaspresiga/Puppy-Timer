//
//  ContentView.swift
//  Puppy Timer
//
//  Created by Nicolas Marin Presiga on 5/1/26.
//

import SwiftUI
import SwiftData
import UserNotifications

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [PuppyProfile]
    @Query(sort: \PuppyEvent.timestamp, order: .reverse) private var events: [PuppyEvent]
    @State private var animatedLogType: PuppyEventType?

    var body: some View {
        NavigationStack {
            if let profile = profiles.first {
                dashboard(for: profile)
                    .navigationTitle("Puppy Timer")
                    .toolbar {
                        NavigationLink {
                            PuppyProfileForm(profile: profile)
                        } label: {
                            Label("Edit puppy", systemImage: "slider.horizontal.3")
                        }
                    }
            } else {
                PuppyProfileForm(profile: nil)
                    .navigationTitle("Puppy Setup")
            }
        }
        .tint(AppPalette.primaryGreen)
    }

    private func dashboard(for profile: PuppyProfile) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header(for: profile)
                recommendationCard(for: profile)
                quickLogGrid(for: profile)
                todaySummary
                timeline
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 110)
        }
        .background(AppPalette.background)
        .scrollIndicators(.visible)
    }

    private func header(for profile: PuppyProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppPalette.primaryGreen)
                        .frame(width: 64, height: 64)

                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("\(profile.name)'s day")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.primaryGreen)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(profileSummary(for: profile))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Label(ageWindowTitle(for: profile), systemImage: "clock.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppPalette.primaryGreen)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(AppPalette.softGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text("Log each event to keep the next potty window accurate.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppPalette.primaryGreen.opacity(0.08), lineWidth: 1)
        )
    }

    private func profileSummary(for profile: PuppyProfile) -> String {
        var details: [String] = []

        if profile.ageInMonths == 1 {
            details.append("1 month old")
        } else {
            details.append("\(profile.ageInMonths) months old")
        }

        if !profile.color.isEmpty {
            details.append(profile.color)
        }

        if !profile.breed.isEmpty {
            details.append(profile.breed)
        }

        return details.joined(separator: " - ")
    }

    private func ageWindowTitle(for profile: PuppyProfile) -> String {
        if profile.ageInMonths <= 2 {
            return "Short window"
        }

        if profile.ageInMonths <= 4 {
            return "Medium window"
        }

        return "Longer window"
    }

    private func recommendationCard(for profile: PuppyProfile) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Next potty window", systemImage: "timer")
                .font(.headline)
                .foregroundStyle(AppPalette.primaryGreen.opacity(0.72))

            VStack(alignment: .leading, spacing: 6) {
                Text(nextPottyTitle(for: profile))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.primaryGreen)

                Text(nextPottyReason(for: profile))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 14) {
                lastEventTile(title: "Last pee", type: .pee)
                lastEventTile(title: "Last poop", type: .poop)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func quickLogGrid(for profile: PuppyProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick log")
                .font(.title2.bold())
                .foregroundStyle(AppPalette.primaryGreen)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(PuppyEventType.allCases) { type in
                    Button {
                        addEvent(type, profile: profile)
                    } label: {
                        quickLogButtonLabel(for: type)
                    }
                    .buttonStyle(QuickLogButtonStyle())
                }
            }
        }
    }

    private func quickLogButtonLabel(for type: PuppyEventType) -> some View {
        let isAnimating = animatedLogType == type

        return HStack(spacing: 10) {
            Image(systemName: type.systemImage)
                .font(.headline)
                .frame(width: 26, height: 26)
                .scaleEffect(isAnimating ? 1.24 : 1)

            Text(type.title)
                .font(.headline)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.headline)
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(isAnimating ? 1 : 0.4)
        }
        .padding(14)
        .frame(minHeight: 56)
        .foregroundStyle(AppPalette.primaryGreen)
        .background(isAnimating ? AppPalette.primaryGreen.opacity(0.16) : buttonBackground(for: type))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppPalette.primaryGreen.opacity(isAnimating ? 0.34 : 0.08), lineWidth: 1)
        )
        .scaleEffect(isAnimating ? 1.03 : 1)
        .animation(.spring(response: 0.24, dampingFraction: 0.58), value: animatedLogType)
    }

    private var todaySummary: some View {
        HStack(spacing: 12) {
            summaryTile(title: "Accidents", value: "\(countToday(.accident))")
            summaryTile(title: "Meals", value: "\(countToday(.meal))")
            summaryTile(title: "Potty logs", value: "\(countToday(.pee) + countToday(.poop))")
        }
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.title2.bold())
                .foregroundStyle(AppPalette.primaryGreen)

            if todaysEvents.isEmpty {
                ContentUnavailableView(
                    "No logs yet",
                    systemImage: "pawprint.fill",
                    description: Text("Tap a quick log button to start today's puppy timeline.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(AppPalette.card)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(todaysEvents) { event in
                        HStack(spacing: 12) {
                            Image(systemName: event.type.systemImage)
                                .foregroundStyle(AppPalette.primaryGreen)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.type.title)
                                    .font(.headline)

                                Text(event.timestamp, format: .dateTime.hour().minute())
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 12)

                        if event.id != todaysEvents.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .background(AppPalette.card)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private var todaysEvents: [PuppyEvent] {
        events.filter { Calendar.current.isDateInToday($0.timestamp) }
    }

    private func nextPottyTitle(for profile: PuppyProfile) -> String {
        guard let latest = events.first else {
            return "Start with a log"
        }

        let target = suggestedPottyDate(after: latest, profile: profile)
        if target <= Date() {
            return "Take out now"
        }

        let minutes = max(1, Calendar.current.dateComponents([.minute], from: Date(), to: target).minute ?? 1)
        return "In \(minutes) min"
    }

    private func nextPottyReason(for profile: PuppyProfile) -> String {
        guard let latest = events.first else {
            return "Log a wake-up, meal, water, play, pee, or poop to start \(profile.name)'s first potty timer."
        }

        let ageNote = pottyAgeNote(for: profile)

        switch latest.type {
        case .wake:
            return "Puppies usually need to go right after waking up. \(ageNote)"
        case .meal:
            return "Meal logged. A potty break is often useful soon after eating. \(ageNote)"
        case .water:
            return "Water logged. Watch for a potty window soon. \(ageNote)"
        case .play:
            return "Play can trigger a potty need, especially with young puppies. \(ageNote)"
        case .accident:
            return "Accident logged. The next reminder window is shortened for \(profile.name)."
        case .pee, .poop:
            return "Potty logged. The next check is based on \(profile.name)'s age."
        case .nap:
            return "Nap logged. The important timer starts when your puppy wakes."
        }
    }

    private func addEvent(_ type: PuppyEventType, profile: PuppyProfile) {
        let event = PuppyEvent(type: type)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            animatedLogType = type
            modelContext.insert(event)
        }

        schedulePottyReminder(after: event, profile: profile)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                if animatedLogType == type {
                    animatedLogType = nil
                }
            }
        }
    }

    private func suggestedPottyDate(after event: PuppyEvent, profile: PuppyProfile) -> Date {
        let minutes: Int

        switch event.type {
        case .wake:
            minutes = 5
        case .meal:
            minutes = ageAdjustedMinutes(for: profile, young: 10, middle: 15, older: 25)
        case .water:
            minutes = ageAdjustedMinutes(for: profile, young: 15, middle: 20, older: 30)
        case .play:
            minutes = ageAdjustedMinutes(for: profile, young: 8, middle: 12, older: 20)
        case .accident:
            minutes = ageAdjustedMinutes(for: profile, young: 15, middle: 20, older: 30)
        case .pee, .poop:
            minutes = ageAdjustedMinutes(for: profile, young: 35, middle: 55, older: 90)
        case .nap:
            minutes = ageAdjustedMinutes(for: profile, young: 45, middle: 75, older: 120)
        }

        return Calendar.current.date(byAdding: .minute, value: minutes, to: event.timestamp) ?? event.timestamp
    }

    private func schedulePottyReminder(after event: PuppyEvent, profile: PuppyProfile) {
        let reminderDate = suggestedPottyDate(after: event, profile: profile)
        let seconds = reminderDate.timeIntervalSinceNow
        let notificationTitle = "\(profile.name) may need a potty break"
        let notificationMessage = notificationBody(for: event, puppyName: profile.name)

        guard seconds > 1 else { return }

        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            center.removePendingNotificationRequests(withIdentifiers: ["next-potty-reminder"])

            let content = UNMutableNotificationContent()
            content.title = notificationTitle
            content.body = notificationMessage
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(60, seconds), repeats: false)
            let request = UNNotificationRequest(identifier: "next-potty-reminder", content: content, trigger: trigger)

            center.add(request)
        }
    }

    private func notificationBody(for event: PuppyEvent, puppyName: String) -> String {
        switch event.type {
        case .wake:
            return "Wake-up logged. Take \(puppyName) out soon."
        case .meal:
            return "Meal logged. It is time to check for a potty break."
        case .water:
            return "Water logged. Watch for \(puppyName)'s next potty window."
        case .play:
            return "Play logged. A potty break may help prevent accidents."
        case .accident:
            return "Accident logged. Try a shorter potty window this time."
        case .pee, .poop:
            return "Potty logged. This is the next age-based check-in."
        case .nap:
            return "Nap logged. Check in when \(puppyName) is likely to wake."
        }
    }

    private func ageAdjustedMinutes(for profile: PuppyProfile, young: Int, middle: Int, older: Int) -> Int {
        if profile.ageInMonths <= 2 {
            return young
        }

        if profile.ageInMonths <= 4 {
            return middle
        }

        return older
    }

    private func pottyAgeNote(for profile: PuppyProfile) -> String {
        if profile.ageInMonths <= 2 {
            return "At this age, keep the window short."
        }

        if profile.ageInMonths <= 4 {
            return "The timer uses a medium puppy window."
        }

        return "Older puppies can usually wait a bit longer."
    }

    private func lastEventTile(title: String, type: PuppyEventType) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let event = events.first(where: { $0.type == type }) {
                Text(relativeTime(since: event.timestamp))
                    .font(.headline)
            } else {
                Text("Not yet")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.softGreen)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func summaryTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title2.bold())

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func countToday(_ type: PuppyEventType) -> Int {
        todaysEvents.filter { $0.type == type }.count
    }

    private func relativeTime(since date: Date) -> String {
        let minutes = max(0, Calendar.current.dateComponents([.minute], from: date, to: Date()).minute ?? 0)

        if minutes < 1 {
            return "Just now"
        }

        if minutes < 60 {
            return "\(minutes)m ago"
        }

        return "\(minutes / 60)h \(minutes % 60)m ago"
    }

    private func buttonBackground(for type: PuppyEventType) -> Color {
        switch type {
        case .pee:
            AppPalette.mint
        case .poop:
            AppPalette.sage
        case .accident:
            AppPalette.warning
        case .meal:
            AppPalette.warm
        case .water:
            AppPalette.lightGreen
        case .nap:
            AppPalette.calm
        case .wake:
            AppPalette.sunlit
        case .play:
            AppPalette.fresh
        }
    }
}

enum AppPalette {
    static let primaryGreen = Color(red: 8 / 255, green: 64 / 255, blue: 27 / 255)
    static let background = Color(red: 246 / 255, green: 249 / 255, blue: 244 / 255)
    static let card = Color.white
    static let softGreen = Color(red: 232 / 255, green: 241 / 255, blue: 230 / 255)
    static let mint = Color(red: 218 / 255, green: 239 / 255, blue: 226 / 255)
    static let sage = Color(red: 226 / 255, green: 236 / 255, blue: 218 / 255)
    static let warning = Color(red: 243 / 255, green: 226 / 255, blue: 218 / 255)
    static let warm = Color(red: 242 / 255, green: 235 / 255, blue: 218 / 255)
    static let lightGreen = Color(red: 224 / 255, green: 241 / 255, blue: 229 / 255)
    static let calm = Color(red: 226 / 255, green: 234 / 255, blue: 222 / 255)
    static let sunlit = Color(red: 240 / 255, green: 238 / 255, blue: 213 / 255)
    static let fresh = Color(red: 213 / 255, green: 235 / 255, blue: 218 / 255)
}

struct QuickLogButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.72 : 1)
            .shadow(
                color: .black.opacity(configuration.isPressed ? 0.03 : 0),
                radius: configuration.isPressed ? 2 : 0,
                y: configuration.isPressed ? 1 : 0
            )
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

struct PuppyProfileForm: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: SetupField?

    let profile: PuppyProfile?
    private let colorOptions = ["Black", "Brown", "Gray", "Cream", "White", "Golden"]
    private let breedSuggestions = ["French Bulldog", "Golden Retriever", "Labrador", "German Shepherd", "Poodle", "Mixed"]

    @State private var name: String
    @State private var ageInMonths: Int
    @State private var color: String
    @State private var breed: String

    init(profile: PuppyProfile?) {
        self.profile = profile
        _name = State(initialValue: profile?.name ?? "")
        _ageInMonths = State(initialValue: profile?.ageInMonths ?? 2)
        _color = State(initialValue: profile?.color ?? "")
        _breed = State(initialValue: profile?.breed ?? "")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                profilePreview
                nameSection
                ageSection
                colorSection
                breedSection
                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 80)
        }
        .background(AppPalette.background)
        .tint(AppPalette.primaryGreen)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }

    private var profilePreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(selectedColor.opacity(0.25))
                        .frame(width: 76, height: 76)

                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(AppPalette.primaryGreen)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(trimmedName.isEmpty ? "Your puppy" : trimmedName)
                        .font(.title.bold())
                        .foregroundStyle(AppPalette.primaryGreen)

                    Text(previewDetails)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            ProgressView(value: setupProgress)
                .tint(AppPalette.primaryGreen)
        }
        .padding(20)
        .background(AppPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var nameSection: some View {
        setupSection(title: "Name", systemImage: "pencil") {
            setupTextField(placeholder: "Ares", text: $name, field: .name)
                .textContentType(.name)
        }
    }

    private var ageSection: some View {
        setupSection(title: "Age", systemImage: "calendar") {
            HStack(spacing: 14) {
                Button {
                    updateAge(by: -1)
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(SetupIconButtonStyle())
                .disabled(ageInMonths <= 1)

                VStack(spacing: 4) {
                    Text("\(ageInMonths)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.primaryGreen)

                    Text(ageInMonths == 1 ? "month old" : "months old")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AppPalette.softGreen)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Button {
                    updateAge(by: 1)
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(SetupIconButtonStyle())
                .disabled(ageInMonths >= 24)
            }
        }
    }

    private var colorSection: some View {
        setupSection(title: "Color", systemImage: "paintpalette.fill") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(colorOptions, id: \.self) { option in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.74)) {
                            color = option
                        }
                    } label: {
                        colorOptionLabel(option)
                    }
                    .buttonStyle(QuickLogButtonStyle())
                }
            }
        }
    }

    private var breedSection: some View {
        setupSection(title: "Breed", systemImage: "tag.fill") {
            VStack(alignment: .leading, spacing: 12) {
                setupTextField(placeholder: "French Bulldog", text: $breed, field: .breed)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(breedSuggestions, id: \.self) { suggestion in
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.74)) {
                                    breed = suggestion
                                }
                            } label: {
                                Text(suggestion)
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .frame(height: 36)
                                    .foregroundStyle(selectedBreed(suggestion) ? .white : AppPalette.primaryGreen)
                                    .background(selectedBreed(suggestion) ? AppPalette.primaryGreen : AppPalette.softGreen)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                            .buttonStyle(QuickLogButtonStyle())
                        }
                    }
                }
            }
        }
    }

    private var saveButton: some View {
        Button(action: saveProfile) {
            Label(profile == nil ? "Start Puppy Timer" : "Save Changes", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
        }
        .buttonStyle(PrimarySetupButtonStyle())
        .disabled(trimmedName.isEmpty)
        .opacity(trimmedName.isEmpty ? 0.45 : 1)
    }

    private func setupSection<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(AppPalette.primaryGreen)

            content()
        }
        .padding(16)
        .background(AppPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func setupTextField(placeholder: String, text: Binding<String>, field: SetupField) -> some View {
        TextField("", text: text, prompt: Text(placeholder).foregroundStyle(.secondary))
            .focused($focusedField, equals: field)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .font(.title3.weight(.semibold))
            .padding(14)
            .frame(minHeight: 54)
            .background(AppPalette.softGreen)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(focusedField == field ? AppPalette.primaryGreen : AppPalette.primaryGreen.opacity(0.08), lineWidth: focusedField == field ? 2 : 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = field
            }
            .onSubmit {
                focusedField = nil
            }
    }

    private func colorOptionLabel(_ option: String) -> some View {
        let isSelected = selectedColorName(option)

        return HStack(spacing: 8) {
            Circle()
                .fill(colorSwatch(for: option))
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(AppPalette.primaryGreen.opacity(0.25), lineWidth: 1)
                )

            Text(option)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .foregroundStyle(isSelected ? .white : AppPalette.primaryGreen)
        .background(isSelected ? AppPalette.primaryGreen : AppPalette.softGreen)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var previewDetails: String {
        let displayColor = trimmedColor.isEmpty ? "Color" : trimmedColor
        let displayBreed = trimmedBreed.isEmpty ? "Breed" : trimmedBreed
        return "\(ageInMonths) \(ageInMonths == 1 ? "month" : "months") old - \(displayColor) - \(displayBreed)"
    }

    private var setupProgress: Double {
        var completed = 0
        completed += trimmedName.isEmpty ? 0 : 1
        completed += trimmedColor.isEmpty ? 0 : 1
        completed += trimmedBreed.isEmpty ? 0 : 1
        return Double(completed) / 3
    }

    private var selectedColor: Color {
        colorSwatch(for: trimmedColor)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedColor: String {
        color.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedBreed: String {
        breed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func selectedColorName(_ option: String) -> Bool {
        trimmedColor.localizedCaseInsensitiveCompare(option) == .orderedSame
    }

    private func selectedBreed(_ suggestion: String) -> Bool {
        trimmedBreed.localizedCaseInsensitiveCompare(suggestion) == .orderedSame
    }

    private func updateAge(by value: Int) {
        withAnimation(.spring(response: 0.24, dampingFraction: 0.72)) {
            ageInMonths = min(24, max(1, ageInMonths + value))
        }
    }

    private func colorSwatch(for name: String) -> Color {
        switch name.lowercased() {
        case "black":
            return Color(red: 32 / 255, green: 34 / 255, blue: 31 / 255)
        case "brown":
            return Color(red: 126 / 255, green: 78 / 255, blue: 44 / 255)
        case "gray", "grey":
            return Color(red: 143 / 255, green: 148 / 255, blue: 143 / 255)
        case "cream":
            return Color(red: 232 / 255, green: 218 / 255, blue: 185 / 255)
        case "white":
            return Color(red: 245 / 255, green: 245 / 255, blue: 238 / 255)
        case "golden":
            return Color(red: 205 / 255, green: 151 / 255, blue: 62 / 255)
        default:
            return AppPalette.softGreen
        }
    }

    private func saveProfile() {
        if let profile {
            profile.name = trimmedName
            profile.ageInMonths = ageInMonths
            profile.color = trimmedColor
            profile.breed = trimmedBreed
        } else {
            modelContext.insert(PuppyProfile(name: trimmedName, ageInMonths: ageInMonths, color: trimmedColor, breed: trimmedBreed))
        }

        dismiss()
    }
}

struct SetupIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .background(AppPalette.primaryGreen)
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

struct PrimarySetupButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(AppPalette.primaryGreen)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private enum SetupField {
    case name
    case breed
}

#Preview {
    ContentView()
        .modelContainer(for: [PuppyProfile.self, PuppyEvent.self], inMemory: true)
}

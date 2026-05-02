//
//  ContentView.swift
//  Puppy Timer
//
//  Created by Nicolas Marin Presiga on 5/1/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [PuppyProfile]
    @Query(sort: \PuppyEvent.timestamp, order: .reverse) private var events: [PuppyEvent]

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
    }

    private func dashboard(for profile: PuppyProfile) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header(for: profile)
                recommendationCard
                quickLogGrid
                todaySummary
                timeline
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func header(for profile: PuppyProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(profile.name)'s day")
                    .font(.largeTitle.bold())

                Text(profileSummary(for: profile))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Log what just happened. Puppy Timer will suggest what probably needs to happen next.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
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

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Next potty window", systemImage: "timer")
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text(nextPottyTitle)
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Text(nextPottyReason)
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
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var quickLogGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick log")
                .font(.title2.bold())

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(PuppyEventType.allCases) { type in
                    Button {
                        addEvent(type)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: type.systemImage)
                                .font(.headline)
                                .frame(width: 26, height: 26)

                            Text(type.title)
                                .font(.headline)

                            Spacer()
                        }
                        .padding(14)
                        .frame(minHeight: 56)
                        .foregroundStyle(.primary)
                        .background(color(for: type).opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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

            if todaysEvents.isEmpty {
                ContentUnavailableView(
                    "No logs yet",
                    systemImage: "pawprint.fill",
                    description: Text("Tap a quick log button to start today's puppy timeline.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(todaysEvents) { event in
                        HStack(spacing: 12) {
                            Image(systemName: event.type.systemImage)
                                .foregroundStyle(color(for: event.type))
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
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    private var todaysEvents: [PuppyEvent] {
        events.filter { Calendar.current.isDateInToday($0.timestamp) }
    }

    private var nextPottyTitle: String {
        guard let latest = events.first else {
            return "Start with a log"
        }

        let target = suggestedPottyDate(after: latest)
        if target <= Date() {
            return "Take out now"
        }

        let minutes = max(1, Calendar.current.dateComponents([.minute], from: Date(), to: target).minute ?? 1)
        return "In \(minutes) min"
    }

    private var nextPottyReason: String {
        guard let latest = events.first else {
            return "Log a wake-up, meal, water, play, pee, or poop to start the first potty timer."
        }

        switch latest.type {
        case .wake:
            return "Puppies usually need to go right after waking up."
        case .meal:
            return "Meal logged. A potty break is often useful soon after eating."
        case .water:
            return "Water logged. Watch for a potty window soon."
        case .play:
            return "Play can trigger a potty need, especially with young puppies."
        case .accident:
            return "Accident logged. The next reminder window is shortened."
        case .pee, .poop:
            return "Potty logged. The next check is based on a short awake interval."
        case .nap:
            return "Nap logged. The important timer starts when your puppy wakes."
        }
    }

    private func addEvent(_ type: PuppyEventType) {
        withAnimation {
            modelContext.insert(PuppyEvent(type: type))
        }
    }

    private func suggestedPottyDate(after event: PuppyEvent) -> Date {
        let minutes: Int

        switch event.type {
        case .wake:
            minutes = 5
        case .meal:
            minutes = 15
        case .water:
            minutes = 20
        case .play:
            minutes = 10
        case .accident:
            minutes = 20
        case .pee, .poop:
            minutes = 45
        case .nap:
            minutes = 90
        }

        return Calendar.current.date(byAdding: .minute, value: minutes, to: event.timestamp) ?? event.timestamp
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
        .background(Color(.secondarySystemGroupedBackground))
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
        .background(.white)
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

    private func color(for type: PuppyEventType) -> Color {
        switch type.tintName {
        case "cyan": .cyan
        case "brown": .brown
        case "red": .red
        case "orange": .orange
        case "blue": .blue
        case "indigo": .indigo
        case "yellow": .yellow
        case "green": .green
        default: .accentColor
        }
    }
}

struct PuppyProfileForm: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let profile: PuppyProfile?

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
        Form {
            Section {
                TextField("Name", text: $name)
                    .textContentType(.name)

                Stepper(value: $ageInMonths, in: 1...24) {
                    Text(ageLabel)
                }

                TextField("Color", text: $color)
                TextField("Breed", text: $breed)
            } header: {
                Text("Puppy")
            }

            Section {
                Button(action: saveProfile) {
                    Label(profile == nil ? "Start Puppy Timer" : "Save Changes", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(trimmedName.isEmpty)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }

    private var ageLabel: String {
        if ageInMonths == 1 {
            return "Age: 1 month"
        }

        return "Age: \(ageInMonths) months"
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

#Preview {
    ContentView()
        .modelContainer(for: [PuppyProfile.self, PuppyEvent.self], inMemory: true)
}

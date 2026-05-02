//
//  Item.swift
//  Puppy Timer
//
//  Created by Nicolas Marin Presiga on 5/1/26.
//

import Foundation
import SwiftData

@Model
final class PuppyProfile {
    var name: String
    var ageInMonths: Int
    var color: String
    var breed: String

    init(name: String, ageInMonths: Int, color: String, breed: String) {
        self.name = name
        self.ageInMonths = ageInMonths
        self.color = color
        self.breed = breed
    }
}

@Model
final class PuppyEvent {
    var typeRawValue: String
    var timestamp: Date

    init(type: PuppyEventType, timestamp: Date = Date()) {
        self.typeRawValue = type.rawValue
        self.timestamp = timestamp
    }

    var type: PuppyEventType {
        PuppyEventType(rawValue: typeRawValue) ?? .pee
    }
}

enum PuppyEventType: String, CaseIterable, Identifiable {
    case pee
    case poop
    case accident
    case meal
    case water
    case nap
    case wake
    case play

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pee: "Pee"
        case .poop: "Poop"
        case .accident: "Accident"
        case .meal: "Meal"
        case .water: "Water"
        case .nap: "Nap"
        case .wake: "Wake"
        case .play: "Play"
        }
    }

    var systemImage: String {
        switch self {
        case .pee: "drop.fill"
        case .poop: "circle.fill"
        case .accident: "exclamationmark.triangle.fill"
        case .meal: "fork.knife"
        case .water: "waterbottle.fill"
        case .nap: "moon.fill"
        case .wake: "sun.max.fill"
        case .play: "tennisball.fill"
        }
    }

    var tintName: String {
        switch self {
        case .pee: "cyan"
        case .poop: "brown"
        case .accident: "red"
        case .meal: "orange"
        case .water: "blue"
        case .nap: "indigo"
        case .wake: "yellow"
        case .play: "green"
        }
    }
}

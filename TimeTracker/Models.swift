//
//  WorkView.swift
//  TimeTracker
//
//  Created by Thomas Bürger on 17.10.25.
//

import Foundation

struct Exercise: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var muscleGroup: String
    var lastReps: Int = 8
    var lastWeight: Double = 0
}

struct WorkoutSet: Codable, Identifiable {
    var id: String = UUID().uuidString
    var exerciseId: String
    var reps: Int
    var weight: Double
    var sets: Int
    var completed: Int = 0
}

struct WorkoutSession: Codable, Identifiable {
    var id: String = UUID().uuidString
    var workoutId: String
    var date: Date
    var duration: Int
    var completed: Bool
}

struct SleepSession: Codable, Identifiable {
    var id: String = UUID().uuidString
    var startTime: Date
    var endTime: Date
}

struct TrackerData: Codable {
    var workCategories: [CategoryItem] = []
    var sportsCategories: [CategoryItem] = []
    var workouts: [Workout] = []
    var exercises: [Exercise] = []
    var gymDays: [Int] = []
    var sleepData: SleepData = SleepData()
}

struct CategoryItem: Codable, Identifiable {
    var id: String
    var name: String
    var total: Double = 0
    var today: Double = 0
    var week: Double = 0
    var lastDate: String = ""
    var lastWeek: String = ""
    var isRunning: Bool = false
    var startTime: Date?
    var dailyTimes: [String: Double] = [:]
    
    enum CodingKeys: String, CodingKey {
        case id, name, total, today, week, lastDate, lastWeek, dailyTimes
    }
}

// Zusätzliche Structs für tatsächliche Workout-Durchführung
struct CompletedExerciseSet: Codable, Identifiable {
    var id: String = UUID().uuidString
    var exerciseId: String
    var reps: Int
    var weight: Double
    var completed: Bool = false
}

struct CompletedWorkoutSession: Codable, Identifiable {
    var id: String = UUID().uuidString
    var workoutId: String
    var date: Date
    var duration: Int
    var completedExercises: [CompletedExerciseSet] = []
}

// Workout Struct erweitern
struct Workout: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var sets: [WorkoutSet] = []
    var sessions: [WorkoutSession] = []
    var completedSessions: [CompletedWorkoutSession] = [] // Neue Property für tatsächliche Durchführung
}

struct SleepData: Codable {
    var isSleeping: Bool = false
    var sleepStartTime: Date?
    var alarmTime: Date?
    var sleepSessions: [SleepSession] = []
    var systemAlarmId: String? // ID des System-Alarms
}

// Sleep Statistics mit erweiterten Daten
struct SleepStatistics: Codable {
    var avgDuration: Double
    var avgBedtime: Double
    var avgWakeTime: Double
    var bedtimeVariation: Double
    var wakeVariation: Double
    var consistencyScore: Double
}

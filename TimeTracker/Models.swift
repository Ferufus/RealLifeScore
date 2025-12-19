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
    var exerciseType: ExerciseType = .gym
}

// NEU: Exercise Type Enum
enum ExerciseType: String, Codable {
case gym = "gym"
case calisthenics = "calisthenics"
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
    var contacts: [ContactProfile] = []
    var habits: [Habit] = []
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
    var systemAlarmId: String?
    
    // NEU: Wind-Down-Phase
    var windDownEnabled: Bool = false
    var windDownDuration: Int = 30 // Minuten
    var windDownScheduledTime: Date?
    var windDownNotificationId: String?
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

// MARK: - Social Contacts

enum ContactClass: String, Codable, CaseIterable {
    case friends = "Friends"
    case closeFriends = "Close Friends"
    case family = "Family"
    case closeFamily = "Close Family"
    case colleagues = "Colleagues"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .friends: return "person.2.fill"
        case .closeFriends: return "heart.fill"
        case .family: return "house.fill"
        case .closeFamily: return "heart.circle.fill"
        case .colleagues: return "briefcase.fill"
        case .other: return "person.fill"
        }
    }
    
    var color: String {
        switch self {
        case .friends: return "blue"
        case .closeFriends: return "pink"
        case .family: return "green"
        case .closeFamily: return "purple"
        case .colleagues: return "orange"
        case .other: return "gray"
        }
    }
}

struct ContactProfile: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var phoneNumber: String?
    var contactClass: ContactClass = .other
    
    // Profile Information
    var currentNews: String = "" // Was gibt's Neues?
    var preferences: String = "" // Vorlieben
    var interests: String = "" // Sport, Hobbies, etc.
    var notes: String = "" // Zusätzliche Notizen
    
    // Call Scheduling
    var scheduledCalls: [ScheduledCall] = []
    
    // Metadata
    var lastContact: Date?
    var createdAt: Date = Date()
}

struct ScheduledCall: Codable, Identifiable {
    var id: String = UUID().uuidString
    var contactId: String
    var scheduledTime: Date
    var note: String = ""
    var completed: Bool = false
    var notificationId: String?
}

// MARK: - Habits

enum HabitType: String, Codable {
    case good = "good"
    case bad = "bad"
    
    var icon: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .bad: return "xmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .good: return "green"
        case .bad: return "red"
        }
    }
}

struct HabitEntry: Codable, Identifiable {
    var id: String = UUID().uuidString
    var habitId: String
    var date: Date
    var completed: Bool
    var note: String = ""
}

struct Habit: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var description: String = ""
    var type: HabitType
    var createdAt: Date = Date()
    var entries: [HabitEntry] = []
    var reminderEnabled: Bool = false
    var reminderTime: Date?
    var notificationId: String?
    
    // Stats
    var currentStreak: Int {
        calculateStreak()
    }
    
    var longestStreak: Int {
        calculateLongestStreak()
    }
    
    var completionRate: Double {
        guard !entries.isEmpty else { return 0 }
        let completed = entries.filter { $0.completed }.count
        return Double(completed) / Double(entries.count) * 100
    }
    
    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        let sortedEntries = entries.sorted { $0.date > $1.date }
        
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())
        
        for entry in sortedEntries {
            let entryDate = calendar.startOfDay(for: entry.date)
            
            if entryDate == currentDate && entry.completed {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if entryDate < currentDate {
                break
            }
        }
        
        return streak
    }
    
    private func calculateLongestStreak() -> Int {
        let calendar = Calendar.current
        let sortedEntries = entries.sorted { $0.date < $1.date }
        
        var longestStreak = 0
        var currentStreak = 0
        var lastDate: Date?
        
        for entry in sortedEntries where entry.completed {
            let entryDate = calendar.startOfDay(for: entry.date)
            
            if let last = lastDate {
                let daysDiff = calendar.dateComponents([.day], from: last, to: entryDate).day ?? 0
                if daysDiff == 1 {
                    currentStreak += 1
                } else {
                    longestStreak = max(longestStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            
            lastDate = entryDate
        }
        
        return max(longestStreak, currentStreak)
    }
}

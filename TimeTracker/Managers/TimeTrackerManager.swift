//
//  TimeTrackerManager.swift
//  TimeTracker
//
//  Created by Thomas Bürger on 17.10.25.
//

import SwiftUI
import UserNotifications
import Combine
import UIKit
import MediaPlayer

class TimeTrackerManager: ObservableObject {
    @Published var data: TrackerData
    @Published var showingPositiveMessage = false
    @Published var positiveMessage = ""
    
    private var timer: Timer?
    private let userDefaults = UserDefaults.standard
    private let dataKey = "timeTrackerDataV4"
    
    // App State Tracking
    private var scenePhase: ScenePhase = .active
    
    init() {
        self.data = TimeTrackerManager.loadData()
        initializeExercises()
        requestNotificationPermission()
        startTimer()
        setupAppStateObservers()
        scheduleDailyHabitReviewNotification()
    }
    
    // MARK: - App State Management
    func updateScenePhase(_ phase: ScenePhase) {
        let oldPhase = scenePhase
        scenePhase = phase
        
        switch (oldPhase, phase) {
        case (.active, .inactive), (.active, .background):
            // App wird minimiert oder in Hintergrund geschoben
            stopAllRunningTimers()
        case (.inactive, .active), (.background, .active):
            // App wird wieder aktiv
            // Timer werden nicht automatisch neu gestartet
            break
        default:
            break
        }
    }
    
    private func setupAppStateObservers() {
        // Observer für App-Wechsel
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.stopAllRunningTimers()
        }
    }
    
    private func stopAllRunningTimers() {
        // Stoppe alle laufenden Work-Timer
        for index in data.workCategories.indices where data.workCategories[index].isRunning {
            stopTimer(category: &data.workCategories[index])
        }
        
        // Stoppe alle laufenden Sports-Timer
        for index in data.sportsCategories.indices where data.sportsCategories[index].isRunning {
            stopTimer(category: &data.sportsCategories[index])
        }
        
        saveData()
    }
    
    private func stopTimer(category: inout CategoryItem) {
        guard category.isRunning, let startTime = category.startTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime) / 60 // Minuten
        let todayString = dateString(from: Date())
        
        category.today += elapsed
        category.week += elapsed
        category.total += elapsed
        category.dailyTimes[todayString, default: 0] += elapsed
        
        category.isRunning = false
        category.startTime = nil
    }
    
    // MARK: - Data Management
    static func loadData() -> TrackerData {
        guard let data = UserDefaults.standard.data(forKey: "timeTrackerDataV4"),
              let decoded = try? JSONDecoder().decode(TrackerData.self, from: data) else {
            return TrackerData()
        }
        return decoded
    }
    
    func saveData() {
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: dataKey)
        }
    }
    
    // MARK: - Timer Management
    func toggleTimer(id: String, type: String) {
        // Stoppe zuerst alle anderen laufenden Timer
        stopAllOtherTimers(except: id, type: type)
        
        let now = Date()
        let todayString = dateString(from: now)
        let weekString = weekString(from: now)
        
        if type == "work" {
            if let index = data.workCategories.firstIndex(where: { $0.id == id }) {
                if data.workCategories[index].isRunning {
                    stopTimer(category: &data.workCategories[index])
                } else {
                    startTimer(category: &data.workCategories[index], now: now, todayString: todayString, weekString: weekString)
                }
            }
        } else {
            if let index = data.sportsCategories.firstIndex(where: { $0.id == id }) {
                if data.sportsCategories[index].isRunning {
                    stopTimer(category: &data.sportsCategories[index])
                } else {
                    startTimer(category: &data.sportsCategories[index], now: now, todayString: todayString, weekString: weekString)
                }
            }
        }
        saveData()
    }
    
    private func stopAllOtherTimers(except categoryId: String, type: String) {
        // Stoppe alle Work-Timer außer dem angegebenen
        for index in data.workCategories.indices where data.workCategories[index].id != categoryId && data.workCategories[index].isRunning {
            stopTimer(category: &data.workCategories[index])
        }
        
        // Stoppe alle Sports-Timer außer dem angegebenen
        for index in data.sportsCategories.indices where data.sportsCategories[index].id != categoryId && data.sportsCategories[index].isRunning {
            stopTimer(category: &data.sportsCategories[index])
        }
    }
    
    private func startTimer(category: inout CategoryItem, now: Date, todayString: String, weekString: String) {
        category.isRunning = true
        category.startTime = now
        
        // Wochenreset
        if category.lastWeek != weekString {
            category.week = 0
            category.lastWeek = weekString
        }
        
        // Tagesreset
        if category.lastDate != todayString {
            category.today = 0
            category.lastDate = todayString
        }
    }
    
    // MARK: - Helper Methods
    func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func weekString(from date: Date) -> String {
        let calendar = Calendar.current
        let year = calendar.component(.yearForWeekOfYear, from: date)
        let week = calendar.component(.weekOfYear, from: date)
        return "\(year)-\(week)"
    }
    
    // Rest der Methoden (initializeExercises, toggleGymDay, etc.) hier einfügen
    // ... (kopiere den Rest des TimeTrackerManager Codes hier rein)
    
    func initializeExercises() {
        if data.exercises.isEmpty {
            // GYM EXERCISES (bestehend)
            let gymExercises: [(String, [String])] = [
                ("Chest", ["Bench Press", "Incline Press", "Cable Fly", "Dumbbell Press"]),
                ("Back", ["Deadlift", "Bent Row", "Pull-up", "Lat Pulldown"]),
                ("Shoulders", ["Shoulder Press", "Lateral Raise", "Shrug", "Front Raise"]),
                ("Legs", ["Squat", "Leg Press", "Leg Curl", "Leg Extension"]),
                ("Arms", ["Bicep Curl", "Tricep Dips", "Hammer Curl", "Overhead Extension"]),
                ("Core", ["Plank", "Ab Wheel", "Cable Crunch", "Russian Twist"])
            ]
            
            for (group, exercises) in gymExercises {
                for exercise in exercises {
                    data.exercises.append(Exercise(
                        name: exercise,
                        muscleGroup: group,
                        exerciseType: .gym
                    ))
                }
            }
            
            // CALISTHENICS EXERCISES (NEU)
            let calisthenicsExercises: [(String, [String])] = [
                ("Chest", ["Push-ups", "Diamond Push-ups", "Decline Push-ups", "Archer Push-ups"]),
                ("Back", ["Pull-ups", "Chin-ups", "Inverted Rows", "Superman Holds"]),
                ("Shoulders", ["Pike Push-ups", "Handstand Push-ups", "Plank to Down Dog", "Arm Circles"]),
                ("Legs", ["Bodyweight Squats", "Lunges", "Bulgarian Split Squats", "Pistol Squats"]),
                ("Arms", ["Close Grip Push-ups", "Tricep Dips", "Inverted Curls", "Diamond Push-ups"]),
                ("Core", ["Plank", "Mountain Climbers", "Leg Raises", "Hollow Body Hold"])
            ]
            
            for (group, exercises) in calisthenicsExercises {
                for exercise in exercises {
                    data.exercises.append(Exercise(
                        name: exercise,
                        muscleGroup: group,
                        exerciseType: .calisthenics
                    ))
                }
            }
            
            saveData()
        }
    }
    
    func toggleGymDay(_ day: Int) {
        if data.gymDays.contains(day) {
            data.gymDays.removeAll { $0 == day }
            cancelGymNotifications(for: day)
        } else {
            data.gymDays.append(day)
            scheduleGymNotifications(for: day)
        }
        saveData()
    }
    
    private func scheduleGymNotifications(for day: Int) {
        var components = DateComponents()
        components.weekday = day
        components.hour = 8
        components.minute = 0
        
        let content = UNMutableNotificationContent()
        content.title = "🏋️ Gym Time!"
        content.body = "Time to hit the gym!"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "gym_\(day)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelGymNotifications(for day: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["gym_\(day)"])
    }
    
    func createWorkout(name: String) -> Workout {
        let newWorkout = Workout(name: name)
        data.workouts.append(newWorkout)
        saveData()
        return newWorkout
    }
    
    func addExerciseToWorkout(workoutId: String, exerciseId: String, sets: Int, reps: Int, weight: Double) {
        if let workoutIndex = data.workouts.firstIndex(where: { $0.id == workoutId }) {
            let newSet = WorkoutSet(exerciseId: exerciseId, reps: reps, weight: weight, sets: sets)
            data.workouts[workoutIndex].sets.append(newSet)
            
            if let exerciseIndex = data.exercises.firstIndex(where: { $0.id == exerciseId }) {
                data.exercises[exerciseIndex].lastReps = reps
                data.exercises[exerciseIndex].lastWeight = weight
            }
            
            saveData()
        }
    }
    
    func endWorkoutSession(workoutId: String, startTime: Date) {
        let duration = Int(Date().timeIntervalSince(startTime))
        let session = WorkoutSession(workoutId: workoutId, date: Date(), duration: duration, completed: true)
        
        if let workoutIndex = data.workouts.firstIndex(where: { $0.id == workoutId }) {
            data.workouts[workoutIndex].sessions.append(session)
        }
        saveData()
    }
    
    func getAverageDuration(workoutId: String) -> Int {
        guard let workout = data.workouts.first(where: { $0.id == workoutId }) else { return 0 }
        guard !workout.sessions.isEmpty else { return 0 }
        let total = workout.sessions.reduce(0) { $0 + $1.duration }
        return total / workout.sessions.count
    }
    
    func getCurrentTime(id: String, type: String) -> (today: Double, week: Double, total: Double) {
        let category = type == "work"
            ? data.workCategories.first(where: { $0.id == id })
            : data.sportsCategories.first(where: { $0.id == id })
        
        guard let cat = category else { return (0, 0, 0) }
        
        var today = cat.today
        var week = cat.week
        var total = cat.total
        
        if cat.isRunning, let startTime = cat.startTime {
            let elapsed = Date().timeIntervalSince(startTime) / 60
            today += elapsed
            week += elapsed
            total += elapsed
        }
        
        return (today, week, total)
    }
    
    func addCategory(name: String, type: String) {
        let newCategory = CategoryItem(
            id: UUID().uuidString,
            name: name,
            lastDate: dateString(from: Date()),
            lastWeek: weekString(from: Date())
        )
        
        if type == "work" {
            data.workCategories.append(newCategory)
        } else {
            data.sportsCategories.append(newCategory)
        }
        saveData()
    }
    
    func deleteCategory(id: String, type: String) {
        if type == "work" {
            data.workCategories.removeAll { $0.id == id }
        } else {
            data.sportsCategories.removeAll { $0.id == id }
        }
        saveData()
    }
    
    func getSleepStatistics() -> (avgDuration: Double, avgBedtime: Double, avgWakeTime: Double, bedtimeVariation: Double, wakeVariation: Double) {
        guard !data.sleepData.sleepSessions.isEmpty else {
            return (0, 0, 0, 0, 0)
        }
        
        let sessions = data.sleepData.sleepSessions
        let calendar = Calendar.current
        
        var durations: [Double] = []
        var bedtimes: [Double] = []
        var wakeTimes: [Double] = []
        
        for session in sessions {
            let duration = session.endTime.timeIntervalSince(session.startTime) / 3600
            durations.append(duration)
            
            let bedHour = Double(calendar.component(.hour, from: session.startTime))
            let bedMinute = Double(calendar.component(.minute, from: session.startTime))
            bedtimes.append(bedHour + bedMinute / 60.0)
            
            let wakeHour = Double(calendar.component(.hour, from: session.endTime))
            let wakeMinute = Double(calendar.component(.minute, from: session.endTime))
            wakeTimes.append(wakeHour + wakeMinute / 60.0)
        }
        
        let avgDuration = durations.reduce(0, +) / Double(durations.count)
        let avgBedtime = bedtimes.reduce(0, +) / Double(bedtimes.count)
        let avgWakeTime = wakeTimes.reduce(0, +) / Double(wakeTimes.count)
        
        let bedtimeVariance = bedtimes.map { pow($0 - avgBedtime, 2) }.reduce(0, +) / Double(bedtimes.count)
        let bedtimeStdDev = sqrt(bedtimeVariance)
        
        let wakeVariance = wakeTimes.map { pow($0 - avgWakeTime, 2) }.reduce(0, +) / Double(wakeTimes.count)
        let wakeStdDev = sqrt(wakeVariance)
        
        return (avgDuration, avgBedtime, avgWakeTime, bedtimeStdDev * 60, wakeStdDev * 60)
    }
    
    private func scheduleAlarm(for time: Date) {
        cancelAlarm()
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ Wake Up!"
        content.body = "Time to start your day!"
        content.sound = .defaultCritical
        
        var targetDate = time
        let calendar = Calendar.current
        let now = Date()
        
        if time <= now {
            targetDate = calendar.date(byAdding: .day, value: 1, to: time)!
        }
        
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: targetDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: "sleepAlarm", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelAlarm() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["sleepAlarm"])
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
    
    func cleanup() {
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    func deleteWorkout(workoutId: String) {
        data.workouts.removeAll { $0.id == workoutId }
        saveData()
    }
    
    func deleteExerciseFromWorkout(workoutId: String, setIndex: Int) {
        if let workoutIndex = data.workouts.firstIndex(where: { $0.id == workoutId }) {
            if setIndex < data.workouts[workoutIndex].sets.count {
                data.workouts[workoutIndex].sets.remove(at: setIndex)
                saveData()
            }
        }
    }
    
    func updateWorkoutSetReps(workoutId: String, setIndex: Int, newReps: Int) {
        if let workoutIndex = data.workouts.firstIndex(where: { $0.id == workoutId }) {
            if setIndex < data.workouts[workoutIndex].sets.count {
                data.workouts[workoutIndex].sets[setIndex].reps = newReps
                saveData()
            }
        }
    }
    
    func updateWorkoutSetWeight(workoutId: String, setIndex: Int, newWeight: Double) {
        if let workoutIndex = data.workouts.firstIndex(where: { $0.id == workoutId }) {
            if setIndex < data.workouts[workoutIndex].sets.count {
                data.workouts[workoutIndex].sets[setIndex].weight = newWeight
                saveData()
            }
        }
    }

    func startWorkoutSession(workoutId: String) -> CompletedWorkoutSession {
        let session = CompletedWorkoutSession(
            workoutId: workoutId,
            date: Date(),
            duration: 0,
            completedExercises: []
        )
        
        if let workoutIndex = data.workouts.firstIndex(where: { $0.id == workoutId }) {
            data.workouts[workoutIndex].completedSessions.append(session)
            saveData()
        }
        
        return session
    }

    func updateCompletedWorkoutSession(workoutId: String, sessionId: String, exercises: [CompletedExerciseSet], duration: Int) {
        if let workoutIndex = data.workouts.firstIndex(where: { $0.id == workoutId }),
           let sessionIndex = data.workouts[workoutIndex].completedSessions.firstIndex(where: { $0.id == sessionId }) {
            
            data.workouts[workoutIndex].completedSessions[sessionIndex].completedExercises = exercises
            data.workouts[workoutIndex].completedSessions[sessionIndex].duration = duration
            saveData()
        }
    }

    func getCompletedSessionsForDate(_ date: Date) -> [CompletedWorkoutSession] {
        let calendar = Calendar.current
        var sessions: [CompletedWorkoutSession] = []
        
        for workout in data.workouts {
            let sessionsForDate = workout.completedSessions.filter { session in
                calendar.isDate(session.date, inSameDayAs: date)
            }
            sessions.append(contentsOf: sessionsForDate)
        }
        
        return sessions
    }

    func getWorkoutCompletionDates() -> [Date] {
        var dates: [Date] = []
        
        for workout in data.workouts {
            for session in workout.completedSessions {
                dates.append(session.date)
            }
        }
        
        return dates
    }
        
    func toggleSleepMode(alarmTime: Date?) {
        if data.sleepData.isSleeping {
            wakeUp()
        } else {
            goToSleep(alarmTime: alarmTime)
        }
    }
    
    private func goToSleep(alarmTime: Date?) {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        data.sleepData.isSleeping = true
        data.sleepData.sleepStartTime = now
        data.sleepData.alarmTime = alarmTime
        
        // System-Alarm erstellen
        if let alarmTime = alarmTime {
            scheduleSystemAlarm(for: alarmTime)
        }
        
        // Positive Nachricht basierend auf der Uhrzeit
        if hour < 22 {
            positiveMessage = "🌙 Great choice! Going to bed early is excellent for your health!"
            showingPositiveMessage = true
        } else if hour >= 23 {
            positiveMessage = "🌙 Better late than never! Your body will thank you for the rest."
            showingPositiveMessage = true
        }
        
        saveData()
    }
    
    private func wakeUp() {
        guard let sleepStart = data.sleepData.sleepStartTime else { return }
        
        let now = Date()
        let sleepDuration = now.timeIntervalSince(sleepStart) / 3600
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        // Sleep-Session speichern
        let session = SleepSession(startTime: sleepStart, endTime: now)
        data.sleepData.sleepSessions.append(session)
        
        // Alte Sessions aufräumen (letzte 30 behalten)
        if data.sleepData.sleepSessions.count > 30 {
            data.sleepData.sleepSessions.removeFirst()
        }
        
        // Positive Nachricht basierend auf Schlafdauer und Aufstehzeit
        if hour < 7 && sleepDuration >= 8 {
            positiveMessage = "☀️ Wonderful! You woke up early after a full night's sleep!"
            showingPositiveMessage = true
        } else if sleepDuration < 6 {
            positiveMessage = "💤 You might want to get more sleep tonight. Your body needs rest!"
            showingPositiveMessage = true
        }
        
        data.sleepData.isSleeping = false
        data.sleepData.sleepStartTime = nil
        data.sleepData.alarmTime = nil
        
        // System-Alarm entfernen
        cancelSystemAlarm()
        saveData()
    }
    
    // MARK: - System Alarm Integration
    
    private func scheduleSystemAlarm(for time: Date) {
        cancelSystemAlarm()
        
        let center = UNUserNotificationCenter.current()
        
        // Erstelle eine eindeutige ID für diesen Alarm
        let alarmId = "sleepAlarm_\(UUID().uuidString)"
        data.sleepData.systemAlarmId = alarmId
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ Wake Up Time!"
        content.body = "Time to start your day! Hope you had a good rest."
        content.sound = UNNotificationSound.defaultCritical
        content.categoryIdentifier = "ALARM"
        
        // Vibrationsmuster für Alarm
        content.userInfo = ["alarm_type": "sleep_alarm"]
        
        // Stelle sicher, dass die Zeit in der Zukunft liegt
        var targetDate = time
        let calendar = Calendar.current
        let now = Date()
        
        if time <= now {
            targetDate = calendar.date(byAdding: .day, value: 1, to: time)!
        }
        
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: targetDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: alarmId, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("Error scheduling alarm: \(error.localizedDescription)")
                // Fallback: Versuche es mit einem einfacheren Alarm
                self.scheduleFallbackAlarm(for: targetDate)
            } else {
                print("System alarm scheduled for \(targetDate)")
            }
        }
        
        // Zusätzlich: Stelle einen echten iOS Alarm (wenn möglich)
        scheduleIOSAlarmIfPossible(for: targetDate)
    }
    
    private func scheduleFallbackAlarm(for time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "⏰ Wake Up!"
        content.body = "Time to wake up!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, time.timeIntervalSince(Date())), repeats: false)
        let request = UNNotificationRequest(identifier: "fallbackAlarm", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleIOSAlarmIfPossible(for time: Date) {
        // Diese Methode könnte mit externen Alarm-APIs integriert werden
        // Für jetzt verwenden wir nur Local Notifications
        
        // Optional: Integration mit HealthKit für Schlafanalyse
        scheduleHealthKitSleepAnalysis(startTime: data.sleepData.sleepStartTime ?? Date(), endTime: time)
    }
    
    private func scheduleHealthKitSleepAnalysis(startTime: Date, endTime: Date) {
        // HealthKit Integration für bessere Schlafanalyse
        // Dies würde HealthKit-Berechtigungen benötigen
    }
    
    private func cancelSystemAlarm() {
        let center = UNUserNotificationCenter.current()
        
        // Entferne den spezifischen Sleep-Alarm
        if let alarmId = data.sleepData.systemAlarmId {
            center.removePendingNotificationRequests(withIdentifiers: [alarmId])
        }
        
        // Entferne auch alle anderen ausstehenden Sleep-Alarme
        center.getPendingNotificationRequests { requests in
            let sleepAlarms = requests.filter { $0.identifier.contains("sleepAlarm") }
            let alarmIds = sleepAlarms.map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: alarmIds)
        }
        
        center.removePendingNotificationRequests(withIdentifiers: ["fallbackAlarm"])
        data.sleepData.systemAlarmId = nil
    }
    
    // MARK: - Enhanced Sleep Statistics
    
    func getEnhancedSleepStatistics() -> SleepStatistics {
        guard !data.sleepData.sleepSessions.isEmpty else {
            return SleepStatistics(
                avgDuration: 0,
                avgBedtime: 0,
                avgWakeTime: 0,
                bedtimeVariation: 0,
                wakeVariation: 0,
                consistencyScore: 0
            )
        }
        
        let sessions = data.sleepData.sleepSessions
        let calendar = Calendar.current
        
        var durations: [Double] = []
        var bedtimes: [Double] = []
        var wakeTimes: [Double] = []
        
        for session in sessions {
            let duration = session.endTime.timeIntervalSince(session.startTime) / 3600
            durations.append(duration)
            
            // Verwende die tatsächliche Systemzeit
            let bedHour = Double(calendar.component(.hour, from: session.startTime))
            let bedMinute = Double(calendar.component(.minute, from: session.startTime))
            bedtimes.append(bedHour + bedMinute / 60.0)
            
            let wakeHour = Double(calendar.component(.hour, from: session.endTime))
            let wakeMinute = Double(calendar.component(.minute, from: session.endTime))
            wakeTimes.append(wakeHour + wakeMinute / 60.0)
        }
        
        let avgDuration = durations.reduce(0, +) / Double(durations.count)
        let avgBedtime = bedtimes.reduce(0, +) / Double(bedtimes.count)
        let avgWakeTime = wakeTimes.reduce(0, +) / Double(wakeTimes.count)
        
        let bedtimeVariance = bedtimes.map { pow($0 - avgBedtime, 2) }.reduce(0, +) / Double(bedtimes.count)
        let bedtimeStdDev = sqrt(bedtimeVariance)
        
        let wakeVariance = wakeTimes.map { pow($0 - avgWakeTime, 2) }.reduce(0, +) / Double(wakeTimes.count)
        let wakeStdDev = sqrt(wakeVariance)
        
        // Konsistenz-Score berechnen (0-100)
        let consistencyScore = calculateConsistencyScore(
            durations: durations,
            bedtimes: bedtimes,
            wakeTimes: wakeTimes
        )
        
        return SleepStatistics(
            avgDuration: avgDuration,
            avgBedtime: avgBedtime,
            avgWakeTime: avgWakeTime,
            bedtimeVariation: bedtimeStdDev * 60, // in Minuten
            wakeVariation: wakeStdDev * 60, // in Minuten
            consistencyScore: consistencyScore
        )
    }
    
    private func calculateConsistencyScore(durations: [Double], bedtimes: [Double], wakeTimes: [Double]) -> Double {
        guard durations.count >= 3 else { return 50.0 } // Baseline für wenige Daten
        
        // Berechne Variationen
        let durationStdDev = calculateStandardDeviation(durations)
        let bedtimeStdDev = calculateStandardDeviation(bedtimes)
        let wakeStdDev = calculateStandardDeviation(wakeTimes)
        
        // Normalisiere die Werte (niedrigere StdDev = besser)
        let maxDurationStdDev = 3.0 // Stunden
        let maxTimeStdDev = 4.0 // Stunden
        
        let durationScore = max(0, 100 - (durationStdDev / maxDurationStdDev) * 50)
        let bedtimeScore = max(0, 100 - (bedtimeStdDev / maxTimeStdDev) * 25)
        let wakeScore = max(0, 100 - (wakeStdDev / maxTimeStdDev) * 25)
        
        return (durationScore + bedtimeScore + wakeScore) / 3
    }
    
    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
    
    // MARK: - System Time Integration
    
    func getCurrentSystemTime() -> Date {
        return Date() // Gibt die aktuelle Systemzeit zurück
    }
    
    func formatSystemTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
    
    func isSystemTimeWithinSleepHours() -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())
        return hour >= 22 || hour < 6 // 10 PM - 6 AM als Schlafenszeit
    }
    
    // MARK: - Wind-Down Phase Management

    func scheduleWindDown(time: Date, duration: Int) {
        data.sleepData.windDownEnabled = true
        data.sleepData.windDownDuration = duration
        data.sleepData.windDownScheduledTime = time
        
        scheduleWindDownNotification(for: time)
        saveData()
    }

    func cancelWindDown() {
        data.sleepData.windDownEnabled = false
        data.sleepData.windDownScheduledTime = nil
        
        if let notificationId = data.sleepData.windDownNotificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
            data.sleepData.windDownNotificationId = nil
        }
        
        saveData()
    }

    private func scheduleWindDownNotification(for time: Date) {
        // Cancel existing notification
        if let existingId = data.sleepData.windDownNotificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [existingId])
        }
        
        let notificationId = "windDown_\(UUID().uuidString)"
        data.sleepData.windDownNotificationId = notificationId
        
        let content = UNMutableNotificationContent()
        content.title = "🌙 Wind-Down Time"
        content.body = "Time to start winding down for better sleep. Consider dimming lights and avoiding screens."
        content.sound = .default
        content.categoryIdentifier = "WIND_DOWN"
        
        var targetDate = time
        let calendar = Calendar.current
        let now = Date()
        
        // If time is in the past, schedule for tomorrow
        if time <= now {
            targetDate = calendar.date(byAdding: .day, value: 1, to: time)!
        }
        
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: targetDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling wind-down notification: \(error.localizedDescription)")
            } else {
                print("Wind-down notification scheduled for \(targetDate)")
            }
        }
    }

    func getWindDownRemainingTime() -> Int? {
        guard data.sleepData.windDownEnabled,
              let scheduledTime = data.sleepData.windDownScheduledTime else {
            return nil
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Get today's wind-down time
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        guard var todayWindDown = calendar.date(from: components) else { return nil }
        
        // If time has passed, calculate for tomorrow
        if todayWindDown < now {
            todayWindDown = calendar.date(byAdding: .day, value: 1, to: todayWindDown)!
        }
        
        return Int(todayWindDown.timeIntervalSince(now) / 60) // Minutes
    }
    
    // MARK: - Contact Management

    func addContact(name: String, phoneNumber: String?, contactClass: ContactClass) -> ContactProfile {
        let contact = ContactProfile(
            name: name,
            phoneNumber: phoneNumber,
            contactClass: contactClass
        )
        data.contacts.append(contact)
        saveData()
        return contact
    }

    func updateContact(_ contact: ContactProfile) {
        if let index = data.contacts.firstIndex(where: { $0.id == contact.id }) {
            data.contacts[index] = contact
            saveData()
        }
    }

    func deleteContact(id: String) {
        // Cancel all scheduled calls for this contact
        if let contact = data.contacts.first(where: { $0.id == id }) {
            for call in contact.scheduledCalls {
                if let notificationId = call.notificationId {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
                }
            }
        }
        
        data.contacts.removeAll { $0.id == id }
        saveData()
    }

    func scheduleCall(contactId: String, time: Date, note: String) {
        guard let contactIndex = data.contacts.firstIndex(where: { $0.id == contactId }) else { return }
        
        let notificationId = "call_\(contactId)_\(UUID().uuidString)"
        
        var scheduledCall = ScheduledCall(
            contactId: contactId,
            scheduledTime: time,
            note: note,
            notificationId: notificationId
        )
        
        data.contacts[contactIndex].scheduledCalls.append(scheduledCall)
        
        // Schedule notification
        scheduleCallNotification(for: scheduledCall, contactName: data.contacts[contactIndex].name)
        
        saveData()
    }

    private func scheduleCallNotification(for call: ScheduledCall, contactName: String) {
        guard let notificationId = call.notificationId else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "📞 Call Reminder"
        content.body = "Time to call \(contactName)"
        if !call.note.isEmpty {
            content.body += " – \(call.note)"
        }
        content.sound = .default
        content.categoryIdentifier = "CALL_REMINDER"
        content.userInfo = ["contactId": call.contactId, "callId": call.id]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: call.scheduledTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling call notification: \(error.localizedDescription)")
            }
        }
    }

    func completeCall(contactId: String, callId: String) {
        guard let contactIndex = data.contacts.firstIndex(where: { $0.id == contactId }),
              let callIndex = data.contacts[contactIndex].scheduledCalls.firstIndex(where: { $0.id == callId }) else {
            return
        }
        
        data.contacts[contactIndex].scheduledCalls[callIndex].completed = true
        data.contacts[contactIndex].lastContact = Date()
        
        // Remove notification
        if let notificationId = data.contacts[contactIndex].scheduledCalls[callIndex].notificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
        }
        
        saveData()
    }

    func deleteScheduledCall(contactId: String, callId: String) {
        guard let contactIndex = data.contacts.firstIndex(where: { $0.id == contactId }),
              let callIndex = data.contacts[contactIndex].scheduledCalls.firstIndex(where: { $0.id == callId }) else {
            return
        }
        
        // Remove notification
        if let notificationId = data.contacts[contactIndex].scheduledCalls[callIndex].notificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
        }
        
        data.contacts[contactIndex].scheduledCalls.remove(at: callIndex)
        saveData()
    }

    func getUpcomingCalls() -> [(contact: ContactProfile, call: ScheduledCall)] {
        var upcomingCalls: [(contact: ContactProfile, call: ScheduledCall)] = []
        
        for contact in data.contacts {
            let futureCalls = contact.scheduledCalls.filter { !$0.completed && $0.scheduledTime > Date() }
            for call in futureCalls {
                upcomingCalls.append((contact, call))
            }
        }
        
        return upcomingCalls.sorted { $0.call.scheduledTime < $1.call.scheduledTime }
    }
    
    // MARK: - Habit Management

    func addHabit(name: String, description: String, type: HabitType) -> Habit {
        let habit = Habit(
            name: name,
            description: description,
            type: type
        )
        data.habits.append(habit)
        saveData()
        return habit
    }

    func updateHabit(_ habit: Habit) {
        if let index = data.habits.firstIndex(where: { $0.id == habit.id }) {
            data.habits[index] = habit
            saveData()
        }
    }

    func deleteHabit(id: String) {
        // Cancel notification if enabled
        if let habit = data.habits.first(where: { $0.id == id }),
           let notificationId = habit.notificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
        }
        
        data.habits.removeAll { $0.id == id }
        saveData()
    }

    func toggleHabitEntry(habitId: String, date: Date) {
        guard let habitIndex = data.habits.firstIndex(where: { $0.id == habitId }) else { return }
        
        let calendar = Calendar.current
        let dateStart = calendar.startOfDay(for: date)
        
        // Check if entry exists for this date
        if let entryIndex = data.habits[habitIndex].entries.firstIndex(where: {
            calendar.isDate($0.date, inSameDayAs: dateStart)
        }) {
            // Toggle existing entry
            data.habits[habitIndex].entries[entryIndex].completed.toggle()
        } else {
            // Create new entry
            let entry = HabitEntry(habitId: habitId, date: dateStart, completed: true)
            data.habits[habitIndex].entries.append(entry)
        }
        
        saveData()
    }

    func getHabitEntry(habitId: String, date: Date) -> HabitEntry? {
        guard let habit = data.habits.first(where: { $0.id == habitId }) else { return nil }
        
        let calendar = Calendar.current
        return habit.entries.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func scheduleHabitReminder(habitId: String, time: Date) {
        guard let habitIndex = data.habits.firstIndex(where: { $0.id == habitId }) else { return }
        
        // Cancel existing notification
        if let existingId = data.habits[habitIndex].notificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [existingId])
        }
        
        let notificationId = "habit_\(habitId)_\(UUID().uuidString)"
        data.habits[habitIndex].notificationId = notificationId
        data.habits[habitIndex].reminderEnabled = true
        data.habits[habitIndex].reminderTime = time
        
        let content = UNMutableNotificationContent()
        content.title = "🎯 Habit Reminder"
        content.body = "Don't forget: \(data.habits[habitIndex].name)"
        content.sound = .default
        content.categoryIdentifier = "HABIT_REMINDER"
        content.userInfo = ["habitId": habitId]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling habit reminder: \(error.localizedDescription)")
            }
        }
        
        saveData()
    }

    func cancelHabitReminder(habitId: String) {
        guard let habitIndex = data.habits.firstIndex(where: { $0.id == habitId }) else { return }
        
        if let notificationId = data.habits[habitIndex].notificationId {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationId])
        }
        
        data.habits[habitIndex].reminderEnabled = false
        data.habits[habitIndex].reminderTime = nil
        data.habits[habitIndex].notificationId = nil
        
        saveData()
    }

    func scheduleDailyHabitReviewNotification() {
        // Cancel existing notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_habit_review"])
        
        let content = UNMutableNotificationContent()
        content.title = "✅ Daily Habit Check"
        content.body = "Take a moment to review your habits from yesterday"
        content.sound = .default
        content.categoryIdentifier = "HABIT_REVIEW"
        
        var components = DateComponents()
        components.hour = 8 // 8 AM
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_habit_review", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily habit review: \(error.localizedDescription)")
            }
        }
    }
}

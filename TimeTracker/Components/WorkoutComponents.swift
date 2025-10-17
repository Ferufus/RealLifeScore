//
//  WorkoutComponents.swift
//  TimeTracker
//
//  Created by Thomas Bürger on 17.10.25.
//

import SwiftUI

// MARK: - Workout Card
struct WorkoutCard: View {
    let workout: Workout
    @ObservedObject var manager: TimeTrackerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(workout.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text("\(workout.sets.count) exercises")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            Text("Sessions: \(workout.sessions.count)")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(white: 0.22))
        .cornerRadius(12)
    }
}

// MARK: - Enhanced Workout Card
struct EnhancedWorkoutCard: View {
    let workout: Workout
    @ObservedObject var manager: TimeTrackerManager
    
    var averageDuration: Int {
        manager.getAverageDuration(workoutId: workout.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(workout.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Label("\(workout.sets.count) ex", systemImage: "list.bullet")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Label("\(workout.sessions.count) sessions", systemImage: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    if !workout.sessions.isEmpty {
                        Text("Avg: \(formatDuration(averageDuration))")
                            .font(.system(size: 11))
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(white: 0.22))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return "\(mins)m \(secs)s"
    }
}

// MARK: - Workout Statistics View
struct WorkoutStatsView: View {
    let workout: Workout
    @ObservedObject var manager: TimeTrackerManager
    
    var averageDuration: Int {
        manager.getAverageDuration(workoutId: workout.id)
    }
    
    var totalWorkoutTime: Int {
        workout.sessions.reduce(0) { $0 + $1.duration }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Workout Statistics")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 15) {
                StatCard(title: "Total Sessions", value: "\(workout.sessions.count)" , color: .purple)
                StatCard(title: "Avg Duration", value: formatDuration(averageDuration), color: .purple)
                StatCard(title: "Total Exercises", value: "\(workout.sets.count)", color: .purple)
            }
            
            if !workout.sessions.isEmpty {
                HStack(spacing: 15) {
                    StatCard(title: "Total Time", value: formatDuration(totalWorkoutTime), color: .purple)
                    StatCard(title: "Last Session", value: formatLastSessionDate(), color: .purple)
                }
            }
        }
        .padding()
        .background(Color(white: 0.22))
        .cornerRadius(12)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        if mins > 0 {
            return "\(mins)m \(secs)s"
        } else {
            return "\(secs)s"
        }
    }
    
    private func formatLastSessionDate() -> String {
        guard let lastSession = workout.sessions.sorted(by: { $0.date > $1.date }).first else {
            return "Never"
        }
        
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(lastSession.date) {
            formatter.dateFormat = "HH:mm"
            return "Today \(formatter.string(from: lastSession.date))"
        } else if Calendar.current.isDateInYesterday(lastSession.date) {
            formatter.dateFormat = "HH:mm"
            return "Yesterday \(formatter.string(from: lastSession.date))"
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: lastSession.date)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(white: 0.18))
        .cornerRadius(8)
    }
}

// MARK: - Exercise Config Sheet
struct ExerciseConfigSheet: View {
    @ObservedObject var manager: TimeTrackerManager
    let workoutId: String
    @Binding var exerciseId: String
    @Binding var sets: Int
    @Binding var reps: Int
    @Binding var weight: Double
    @Binding var isPresented: Bool
    
    var exerciseName: String {
        manager.data.exercises.first { $0.id == exerciseId }?.name ?? "Exercise"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(exerciseName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Sets").font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                    HStack {
                        Button(action: { if sets > 1 { sets -= 1 } }) {
                            Image(systemName: "minus.circle.fill").font(.system(size: 24)).foregroundColor(.blue)
                        }
                        Spacer()
                        Text("\(sets)").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                        Spacer()
                        Button(action: { sets += 1 }) {
                            Image(systemName: "plus.circle.fill").font(.system(size: 24)).foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(white: 0.22))
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Reps").font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                    HStack {
                        Button(action: { if reps > 1 { reps -= 1 } }) {
                            Image(systemName: "minus.circle.fill").font(.system(size: 24)).foregroundColor(.blue)
                        }
                        Spacer()
                        TextField("Reps", value: $reps, format: .number)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                        Spacer()
                        Button(action: { reps += 1 }) {
                            Image(systemName: "plus.circle.fill").font(.system(size: 24)).foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(white: 0.22))
                .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Weight (kg)").font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
                    HStack {
                        Button(action: { weight = max(0, weight - 2.5) }) {
                            Image(systemName: "minus.circle.fill").font(.system(size: 24)).foregroundColor(.blue)
                        }
                        Spacer()
                        TextField("Weight", value: $weight, format: .number)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                        Spacer()
                        Button(action: { weight += 2.5 }) {
                            Image(systemName: "plus.circle.fill").font(.system(size: 24)).foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color(white: 0.22))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .background(Color(red: 0.17, green: 0.17, blue: 0.17).ignoresSafeArea())
            .navigationTitle("Configure Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        manager.addExerciseToWorkout(workoutId: workoutId, exerciseId: exerciseId, sets: sets, reps: reps, weight: weight)
                        isPresented = false
                    }
                    .disabled(exerciseId.isEmpty)
                }
            }
        }
    }
}

import SwiftUI

struct WorkoutDetailView: View {
    @ObservedObject var manager: TimeTrackerManager
    @State var workout: Workout
    @State private var showingAddExercise = false
    @State private var selectedMuscleGroup: String = "Chest"
    @State private var selectedExerciseId: String = ""
    @State private var selectedSets: Int = 3
    @State private var selectedReps: Int = 8
    @State private var selectedWeight: Double = 0
    @State private var selectedExerciseType: ExerciseType = .gym
    
    let muscleGroups = ["Chest", "Back", "Shoulders", "Legs", "Arms", "Core"]
    
    var currentExercises: [Exercise] {
        manager.data.exercises.filter {
            $0.muscleGroup == selectedMuscleGroup &&
            $0.exerciseType == selectedExerciseType
        }
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.17, green: 0.17, blue: 0.17)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text(workout.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                // NEU: Exercise Type Picker
                Picker("Exercise Type", selection: $selectedExerciseType) {
                    Text("Gym").tag(ExerciseType.gym)
                    Text("Calisthenics").tag(ExerciseType.calisthenics)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                
                // Bestehender Muscle Group Picker
                Picker("Muscle Group", selection: $selectedMuscleGroup) {
                    ForEach(muscleGroups, id: \.self) { group in
                        Text(group).tag(group)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(currentExercises) { exercise in
                            Button(action: {
                                selectedExerciseId = exercise.id
                                selectedReps = exercise.lastReps
                                selectedWeight = exercise.lastWeight
                                showingAddExercise = true
                            }) {
                                HStack {
                                    Text(exercise.name)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.green)
                                }
                                .padding()
                                .background(Color(white: 0.22))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddExercise) {
            ExerciseConfigSheet(
                manager: manager,
                workoutId: workout.id,
                exerciseId: $selectedExerciseId,
                sets: $selectedSets,
                reps: $selectedReps,
                weight: $selectedWeight,
                isPresented: $showingAddExercise
            )
        }
    }
}

struct WorkoutDetailViewWithStats: View {
    @ObservedObject var manager: TimeTrackerManager
    var workout: Workout
    @State private var showingAddExercise = false
    @State private var selectedMuscleGroup: String = "Chest"
    @State private var selectedExerciseId: String = ""
    @State private var selectedSets: Int = 3
    @State private var selectedReps: Int = 8
    @State private var selectedWeight: Double = 0
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) var dismiss
    
    let muscleGroups = ["Chest", "Back", "Shoulders", "Legs", "Arms", "Core"]
    
    var currentExercises: [Exercise] {
        manager.data.exercises.filter { $0.muscleGroup == selectedMuscleGroup }
    }
    
    var completedSessionsCount: Int {
        workout.completedSessions.count
    }
    
    var totalWorkoutTime: Int {
        workout.completedSessions.reduce(0) { $0 + $1.duration }
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.17, green: 0.17, blue: 0.17)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text(workout.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Workout Statistics
                    VStack(spacing: 15) {
                        Text("Workout Statistics")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 15) {
                            StatCard(title: "Total Sessions", value: "\(workout.sessions.count)", color: .purple)
                            StatCard(title: "Completed", value: "\(completedSessionsCount)", color: .purple)
                            StatCard(title: "Total Exercises", value: "\(workout.sets.count)", color: .purple)
                        }
                        
                        if completedSessionsCount > 0 {
                            HStack(spacing: 15) {
                                StatCard(title: "Total Time", value: formatDuration(totalWorkoutTime), color: .purple)
                                StatCard(title: "Avg Time", value: formatDuration(totalWorkoutTime / completedSessionsCount), color: .purple)
                            }
                        }
                    }
                    .padding()
                    .background(Color(white: 0.22))
                    .cornerRadius(12)
                    
                    // Workout History (ersetzt den Kalender)
                    VStack(alignment: .leading, spacing: 15) {
                        Text("📊 Workout History")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        if workout.completedSessions.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "chart.bar.doc.horizontal")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.3))
                                
                                Text("No completed workouts yet")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Text("Start this workout to see your progress")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        } else {
                            VStack(spacing: 10) {
                                ForEach(workout.completedSessions.sorted(by: { $0.date > $1.date }).prefix(5)) { session in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(formatSessionDate(session.date))
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                            
                                            Text("\(session.completedExercises.count) exercises • \(formatDuration(session.duration))")
                                                .font(.system(size: 12))
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                        
                                        Spacer()
                                        
                                        Text("\(session.completedExercises.filter { $0.completed }.count)/\(session.completedExercises.count) sets")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.green)
                                    }
                                    .padding(.horizontal, 8)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(white: 0.22))
                    .cornerRadius(12)
                    
                    Picker("Muscle Group", selection: $selectedMuscleGroup) {
                        ForEach(muscleGroups, id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    Text("Add Exercises")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ForEach(currentExercises) { exercise in
                            Button(action: {
                                selectedExerciseId = exercise.id
                                selectedReps = exercise.lastReps
                                selectedWeight = exercise.lastWeight
                                showingAddExercise = true
                            }) {
                                HStack {
                                    Text(exercise.name)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.green)
                                }
                                .padding()
                                .background(Color(white: 0.22))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Button(action: { showingDeleteAlert = true }) {
                        Text("Delete Workout")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    .padding()
                    
                    Spacer()
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddExercise) {
            ExerciseConfigSheet(
                manager: manager,
                workoutId: workout.id,
                exerciseId: $selectedExerciseId,
                sets: $selectedSets,
                reps: $selectedReps,
                weight: $selectedWeight,
                isPresented: $showingAddExercise
            )
        }
        .alert("Delete Workout", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                manager.deleteWorkout(workoutId: workout.id)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this workout? All sessions and data will be permanently lost.")
        }
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
    
    private func formatSessionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return "Today at \(formatter.string(from: date))"
        } else if Calendar.current.isDateInYesterday(date) {
            formatter.dateFormat = "HH:mm"
            return "Yesterday at \(formatter.string(from: date))"
        } else {
            formatter.dateFormat = "MMM d, HH:mm"
            return formatter.string(from: date)
        }
    }
}

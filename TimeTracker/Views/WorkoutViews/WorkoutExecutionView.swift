import SwiftUI

struct WorkoutExecutionView: View {
    @ObservedObject var manager: TimeTrackerManager
    let workout: Workout
    @Binding var isPresented: Bool
    @State private var startTime = Date()
    @State private var completedExercises: [CompletedExerciseSet] = []
    @State private var currentExerciseIndex = 0
    @State private var currentSetIndex = 0
    @State private var workoutCompleted = false
    @State private var currentSessionId: String = ""
    @State private var showingAddExercise = false
    @State private var showingFinishAlert = false
    @State private var workoutSets: [WorkoutSet] = []
    
    // Aktuelle Übung und Set
    var currentExercise: Exercise? {
        guard currentExerciseIndex < workoutSets.count else { return nil }
        let exerciseId = workoutSets[currentExerciseIndex].exerciseId
        return manager.data.exercises.first { $0.id == exerciseId }
    }
    
    var currentWorkoutSet: WorkoutSet? {
        guard currentExerciseIndex < workoutSets.count else { return nil }
        return workoutSets[currentExerciseIndex]
    }
    
    // Sets für aktuelle Übung
    var setsForCurrentExercise: [CompletedExerciseSet] {
        completedExercises.filter { $0.exerciseId == currentWorkoutSet?.exerciseId }
    }
    
    var currentSet: CompletedExerciseSet? {
        guard currentSetIndex < setsForCurrentExercise.count else { return nil }
        return setsForCurrentExercise[currentSetIndex]
    }
    
    // Fortschritt
    var progress: Double {
        let totalSets = completedExercises.count
        let completedSets = completedExercises.filter { $0.completed }.count
        guard totalSets > 0 else { return 0 }
        return Double(completedSets) / Double(totalSets)
    }
    
    var isLastSet: Bool {
        currentExerciseIndex == workoutSets.count - 1 &&
        currentSetIndex == setsForCurrentExercise.count - 1
    }
    
    var upcomingExercises: [Exercise] {
        guard currentExerciseIndex + 1 < workoutSets.count else { return [] }
        let upcomingSets = Array(workoutSets[(currentExerciseIndex + 1)...])
        return upcomingSets.compactMap { set in
            manager.data.exercises.first { $0.id == set.exerciseId }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                // Hintergrund mit Gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.12),
                        Color(red: 0.08, green: 0.08, blue: 0.08)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Elegante Header Bar
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(workout.name)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.green)
                                        Text(elapsedTime)
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.green)
                                    }
                                    
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 4, height: 4)
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.blue)
                                        Text("\(completedExercises.filter { $0.completed }.count)/\(completedExercises.count)")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            Spacer()
                        }
                        
                        // Progress Bar mit Schatten
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .frame(height: 8)
                                    .foregroundColor(Color.white.opacity(0.1))
                                
                                Capsule()
                                    .frame(width: CGFloat(progress) * geometry.size.width, height: 8)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.18, green: 0.18, blue: 0.18), Color(red: 0.15, green: 0.15, blue: 0.15)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .overlay(
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.05), .clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                    )
                    
                    // Hauptinhalt - Aktuelles Set
                    if workoutCompleted {
                        // Erfolgs-Screen
                        VStack(spacing: 28) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.green.opacity(0.2), .mint.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 140, height: 140)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            
                            VStack(spacing: 12) {
                                Text("Workout Completed!")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Great job! You crushed your workout.")
                                    .font(.system(size: 18, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                
                                HStack(spacing: 16) {
                                    StatPill(icon: "clock", value: elapsedTime, color: .green)
                                    StatPill(icon: "dumbbell", value: "\(completedExercises.filter { $0.completed }.count) sets", color: .blue)
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                    } else if let exercise = currentExercise, let set = currentSet {
                        ScrollView {
                            VStack(spacing: 24) {
                                // Aktuelle Übung Card
                                VStack(spacing: 16) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("CURRENT EXERCISE")
                                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white.opacity(0.6))
                                                .tracking(1.2)
                                            
                                            Text(exercise.name)
                                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                            
                                            HStack(spacing: 12) {
                                                PillTag(text: exercise.muscleGroup, color: .blue)
                                                PillTag(text: "Set \(currentSetIndex + 1)/\(setsForCurrentExercise.count)", color: .orange)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        // Remove Current Exercise Button
                                        Button(action: { removeCurrentExercise() }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundColor(.red.opacity(0.8))
                                                .background(Circle().fill(Color.white.opacity(0.1)))
                                        }
                                    }
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(red: 0.22, green: 0.22, blue: 0.22), Color(red: 0.18, green: 0.18, blue: 0.18)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                )
                                .padding(.horizontal, 20)
                                
                                // Aktuelles Set Controls
                                VStack(spacing: 0) {
                                    // Reps Control
                                    ControlCard(title: "REPS", value: "\(set.reps)", color: .blue) {
                                        HStack(spacing: 30) {
                                            ControlButton(systemName: "minus", action: { updateReps(-1) })
                                            Text("\(set.reps)")
                                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                                .frame(minWidth: 80)
                                            ControlButton(systemName: "plus", action: { updateReps(1) })
                                        }
                                    }
                                    
                                    Divider()
                                        .background(Color.white.opacity(0.1))
                                    
                                    // Weight Control
                                    ControlCard(title: "WEIGHT", value: "\(String(format: "%.1f", set.weight)) kg", color: .orange) {
                                        HStack(spacing: 30) {
                                            ControlButton(systemName: "minus", action: { updateWeight(-2.5) })
                                            Text(String(format: "%.1f", set.weight))
                                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                                .frame(minWidth: 100)
                                            ControlButton(systemName: "plus", action: { updateWeight(2.5) })
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                                        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
                                )
                                .padding(.horizontal, 20)
                                
                                // Action Buttons
                                HStack(spacing: 12) {
                                    // Complete Set Toggle
                                    Button(action: completeCurrentSet) {
                                        HStack(spacing: 10) {
                                            Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(set.completed ? .white : .white.opacity(0.6))
                                            
                                            Text(set.completed ? "Completed" : "Mark Complete")
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(set.completed ?
                                                    LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing) :
                                                    LinearGradient(colors: [Color(red: 0.25, green: 0.25, blue: 0.25), Color(red: 0.2, green: 0.2, blue: 0.2)], startPoint: .top, endPoint: .bottom)
                                                )
                                        )
                                        .shadow(color: set.completed ? .green.opacity(0.3) : .black.opacity(0.3), radius: 6, x: 0, y: 3)
                                    }
                                    
                                    // Set Management Buttons
                                    HStack(spacing: 8) {
                                        Button(action: removeCurrentSet) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(setsForCurrentExercise.count <= 1 ? .gray : .red)
                                        }
                                        .disabled(setsForCurrentExercise.count <= 1)
                                        
                                        Button(action: addSetToCurrentExercise) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding(10)
                                    .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                                    .cornerRadius(10)
                                }
                                .padding(.horizontal, 20)
                                
                                // Upcoming Exercises
                                if !upcomingExercises.isEmpty {
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            Text("UPCOMING EXERCISES")
                                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                .foregroundColor(.white.opacity(0.6))
                                                .tracking(1.2)
                                            
                                            Spacer()
                                            
                                            Text("\(upcomingExercises.count)")
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                                .foregroundColor(.white.opacity(0.5))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Capsule().fill(Color.white.opacity(0.1)))
                                        }
                                        
                                        LazyVStack(spacing: 8) {
                                            ForEach(Array(upcomingExercises.enumerated()), id: \.element.id) { index, exercise in
                                                UpcomingExerciseRow(
                                                    exercise: exercise,
                                                    onRemove: { removeUpcomingExercise(at: index) },
                                                    index: index
                                                )
                                            }
                                        }
                                    }
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color(red: 0.18, green: 0.18, blue: 0.18))
                                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.vertical, 20)
                        }
                    }
                    
                    Spacer()
                    
                    // Finish Workout Button (nur wenn letztes Set)
                    if isLastSet && currentSet?.completed == true {
                        VStack(spacing: 12) {
                            Text("🎉 Workout Complete!")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            
                            Button(action: finishWorkout) {
                                HStack(spacing: 10) {
                                    Image(systemName: "flag.checkered")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Finish Workout")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 20)
                    }
                }
                
                // Elegant Floating Add Button
                Button(action: { showingAddExercise = true }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingFinishAlert = true
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.red)
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseDuringWorkoutView(
                    manager: manager,
                    workout: workout,
                    onExerciseAdded: { exerciseId, reps, weight in
                        addExerciseDuringWorkout(exerciseId: exerciseId, reps: reps, weight: weight)
                    },
                    isPresented: $showingAddExercise
                )
            }
            .alert("Finish Workout?", isPresented: $showingFinishAlert) {
                Button("Continue Workout", role: .cancel) { }
                Button("Finish Workout", role: .destructive) {
                    finishWorkout()
                    isPresented = false
                }
            } message: {
                Text("Do you want to finish your workout? All completed sets will be saved.")
            }
            .onAppear {
                startTime = Date()
                let session = manager.startWorkoutSession(workoutId: workout.id)
                currentSessionId = session.id
                workoutSets = workout.sets
                initializeExercises()
            }
        }
    }
    
    // MARK: - Helper Methods
    private var elapsedTime: String {
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let mins = elapsed / 60
        let secs = elapsed % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    private func initializeExercises() {
        completedExercises.removeAll()
        for workoutSet in workoutSets {
            for _ in 0..<workoutSet.sets {
                completedExercises.append(CompletedExerciseSet(
                    exerciseId: workoutSet.exerciseId,
                    reps: workoutSet.reps,
                    weight: workoutSet.weight
                ))
            }
        }
    }
    
    private func updateReps(_ change: Int) {
        guard let currentSet = currentSet,
              let index = completedExercises.firstIndex(where: { $0.id == currentSet.id }) else { return }
        completedExercises[index].reps = max(1, currentSet.reps + change)
    }
    
    private func updateWeight(_ change: Double) {
        guard let currentSet = currentSet,
              let index = completedExercises.firstIndex(where: { $0.id == currentSet.id }) else { return }
        completedExercises[index].weight = max(0, currentSet.weight + change)
    }
    
    private func completeCurrentSet() {
        guard let currentSet = currentSet,
              let index = completedExercises.firstIndex(where: { $0.id == currentSet.id }) else { return }
        
        completedExercises[index].completed.toggle()
        
        if completedExercises[index].completed && !isLastSet {
            if currentSetIndex < setsForCurrentExercise.count - 1 {
                currentSetIndex += 1
            } else if currentExerciseIndex < workoutSets.count - 1 {
                currentExerciseIndex += 1
                currentSetIndex = 0
            }
        }
    }
    
    private func addSetToCurrentExercise() {
        guard let currentWorkoutSet = currentWorkoutSet else { return }
        let newSet = CompletedExerciseSet(
            exerciseId: currentWorkoutSet.exerciseId,
            reps: currentWorkoutSet.reps,
            weight: currentWorkoutSet.weight
        )
        
        if let lastIndex = completedExercises.lastIndex(where: { $0.exerciseId == currentWorkoutSet.exerciseId }) {
            completedExercises.insert(newSet, at: lastIndex + 1)
        } else {
            completedExercises.append(newSet)
        }
    }
    
    private func removeCurrentSet() {
        guard let currentSet = currentSet,
              let index = completedExercises.firstIndex(where: { $0.id == currentSet.id }),
              setsForCurrentExercise.count > 1 else { return }
        
        completedExercises.remove(at: index)
        if currentSetIndex >= setsForCurrentExercise.count {
            currentSetIndex = max(0, setsForCurrentExercise.count - 1)
        }
    }
    
    private func removeCurrentExercise() {
        guard currentExerciseIndex < workoutSets.count else { return }
        if let currentWorkoutSet = currentWorkoutSet {
            completedExercises.removeAll { $0.exerciseId == currentWorkoutSet.exerciseId }
        }
        workoutSets.remove(at: currentExerciseIndex)
        if currentExerciseIndex >= workoutSets.count {
            currentExerciseIndex = max(0, workoutSets.count - 1)
        }
        currentSetIndex = 0
    }
    
    private func removeUpcomingExercise(at index: Int) {
        let actualIndex = currentExerciseIndex + 1 + index
        guard actualIndex < workoutSets.count else { return }
        let exerciseId = workoutSets[actualIndex].exerciseId
        completedExercises.removeAll { $0.exerciseId == exerciseId }
        workoutSets.remove(at: actualIndex)
    }
    
    private func addExerciseDuringWorkout(exerciseId: String, reps: Int, weight: Double) {
        let newWorkoutSet = WorkoutSet(
            exerciseId: exerciseId,
            reps: reps,
            weight: weight,
            sets: 1
        )
        workoutSets.insert(newWorkoutSet, at: currentExerciseIndex + 1)
        let newCompletedSet = CompletedExerciseSet(
            exerciseId: exerciseId,
            reps: reps,
            weight: weight
        )
        completedExercises.append(newCompletedSet)
        manager.saveData()
    }
    
    private func finishWorkout() {
        let duration = Int(Date().timeIntervalSince(startTime))
        let completedSets = completedExercises.filter { $0.completed }
        
        manager.updateCompletedWorkoutSession(
            workoutId: workout.id,
            sessionId: currentSessionId,
            exercises: completedSets,
            duration: duration
        )
        workoutCompleted = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isPresented = false
        }
    }
}

// MARK: - Elegante Komponenten

struct StatPill: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(color.opacity(0.15)))
    }
}

struct PillTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(color.opacity(0.15)))
    }
}

struct ControlCard<Content: View>: View {
    let title: String
    let value: String
    let color: Color
    let content: Content
    
    init(title: String, value: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.value = value
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            
            content
        }
        .padding(20)
    }
}

struct ControlButton: View {
    let systemName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Circle().fill(Color.white.opacity(0.1)))
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct UpcomingExerciseRow: View {
    let exercise: Exercise
    let onRemove: () -> Void
    let index: Int
    
    var body: some View {
        HStack {
            Image(systemName: "circle.fill")
                .font(.system(size: 6))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                
                Text(exercise.muscleGroup)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.red.opacity(0.7))
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.22, green: 0.22, blue: 0.22))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - AddExerciseDuringWorkoutView

struct AddExerciseDuringWorkoutView: View {
    @ObservedObject var manager: TimeTrackerManager
    let workout: Workout
    let onExerciseAdded: (String, Int, Double) -> Void
    @Binding var isPresented: Bool
    
    @State private var selectedMuscleGroup: String = "Chest"
    @State private var selectedExerciseId: String = ""
    @State private var reps: Int = 8
    @State private var weight: Double = 0
    
    let muscleGroups = ["Chest", "Back", "Shoulders", "Legs", "Arms", "Core"]
    
    var currentExercises: [Exercise] {
        manager.data.exercises.filter { $0.muscleGroup == selectedMuscleGroup }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.12),
                        Color(red: 0.08, green: 0.08, blue: 0.08)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Picker("Muscle Group", selection: $selectedMuscleGroup) {
                        ForEach(muscleGroups, id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(currentExercises) { exercise in
                                Button(action: {
                                    selectedExerciseId = exercise.id
                                    reps = exercise.lastReps
                                    weight = exercise.lastWeight
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(exercise.name)
                                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                                .foregroundColor(.white)
                                            
                                            Text(exercise.muscleGroup)
                                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedExerciseId == exercise.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedExerciseId == exercise.id ?
                                                Color.blue.opacity(0.2) : Color(red: 0.22, green: 0.22, blue: 0.22))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedExerciseId == exercise.id ? Color.blue : Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    if !selectedExerciseId.isEmpty {
                        VStack(spacing: 20) {
                            Text("Configure Exercise")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 40) {
                                VStack(spacing: 12) {
                                    Text("REPS")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    HStack(spacing: 20) {
                                        Button(action: { reps = max(1, reps - 1) }) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Text("\(reps)")
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .frame(width: 40)
                                        
                                        Button(action: { reps += 1 }) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                
                                VStack(spacing: 12) {
                                    Text("WEIGHT")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    HStack(spacing: 20) {
                                        Button(action: { weight = max(0, weight - 2.5) }) {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Text(String(format: "%.1f", weight))
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                            .frame(width: 50)
                                        
                                        Button(action: { weight += 2.5 }) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.18, green: 0.18, blue: 0.18))
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    Button("Add Exercise") {
                        onExerciseAdded(selectedExerciseId, reps, weight)
                        isPresented = false
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: selectedExerciseId.isEmpty ?
                                [Color.gray, Color.gray] :
                                [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: selectedExerciseId.isEmpty ? .clear : .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .disabled(selectedExerciseId.isEmpty)
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.red)
                }
            }
        }
    }
}

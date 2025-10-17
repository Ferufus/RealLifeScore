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
                Color(red: 0.17, green: 0.17, blue: 0.17)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header mit Fortschritt
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(workout.name)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(elapsedTime)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                        }
                        
                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .frame(height: 6)
                                    .foregroundColor(Color(white: 0.3))
                                
                                Rectangle()
                                    .frame(width: CGFloat(progress) * geometry.size.width, height: 6)
                                    .foregroundColor(.green)
                            }
                            .cornerRadius(3)
                        }
                        .frame(height: 6)
                        
                        HStack {
                            Text("\(Int(progress * 100))% Complete")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            Text("\(completedExercises.filter { $0.completed }.count)/\(completedExercises.count) sets")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding()
                    .background(Color(white: 0.22))
                    
                    // Hauptinhalt - Aktuelles Set
                    if workoutCompleted {
                        VStack(spacing: 25) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.green)
                            
                            Text("Workout Completed!")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Great job! You finished your workout.")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                            
                            Text("Duration: \(elapsedTime)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding()
                    } else if let exercise = currentExercise, let set = currentSet {
                        ScrollView {
                            VStack(spacing: 20) {
                                // Aktuelle Übung
                                VStack(spacing: 15) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(exercise.name)
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundColor(.white)
                                            
                                            Text("Muscle: \(exercise.muscleGroup)")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        
                                        Spacer()
                                        
                                        // Remove Current Exercise Button
                                        Button(action: { removeCurrentExercise() }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(.red)
                                        }
                                    }
                                    
                                    Text("Set \(currentSetIndex + 1) of \(setsForCurrentExercise.count)")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding()
                                .background(Color(white: 0.22))
                                .cornerRadius(12)
                                .padding(.horizontal)
                                
                                // Aktuelles Set Controls
                                VStack(spacing: 20) {
                                    // Reps Control
                                    VStack(spacing: 15) {
                                        Text("REPS")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.6))
                                        
                                        HStack(spacing: 30) {
                                            Button(action: { updateReps(-1) }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.system(size: 44))
                                                    .foregroundColor(.blue)
                                            }
                                            
                                            Text("\(set.reps)")
                                                .font(.system(size: 48, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(minWidth: 80)
                                            
                                            Button(action: { updateReps(1) }) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.system(size: 44))
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    
                                    // Weight Control
                                    VStack(spacing: 15) {
                                        Text("WEIGHT (KG)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.6))
                                        
                                        HStack(spacing: 30) {
                                            Button(action: { updateWeight(-2.5) }) {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.system(size: 44))
                                                    .foregroundColor(.blue)
                                            }
                                            
                                            Text(String(format: "%.1f", set.weight))
                                                .font(.system(size: 48, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(minWidth: 100)
                                            
                                            Button(action: { updateWeight(2.5) }) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.system(size: 44))
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                    
                                    // Complete Set Checkbox
                                    HStack {
                                        Spacer()
                                        
                                        Button(action: completeCurrentSet) {
                                            HStack(spacing: 8) {
                                                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(set.completed ? .green : .white.opacity(0.6))
                                                
                                                Text("Complete Set")
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(set.completed ? Color.green.opacity(0.2) : Color(white: 0.22))
                                            .cornerRadius(8)
                                        }
                                    }
                                    
                                    // Add/Remove Set Buttons
                                    HStack(spacing: 20) {
                                        Button(action: removeCurrentSet) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "minus.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.red)
                                                Text("Remove Set")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.red)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color(white: 0.22))
                                            .cornerRadius(8)
                                        }
                                        .disabled(setsForCurrentExercise.count <= 1)
                                        
                                        Button(action: addSetToCurrentExercise) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.green)
                                                Text("Add Set")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.green)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color(white: 0.22))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(white: 0.18))
                                .cornerRadius(16)
                                .padding(.horizontal)
                                
                                // Upcoming Exercises
                                if !upcomingExercises.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Upcoming Exercises")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal)
                                        
                                        LazyVStack(spacing: 8) {
                                            ForEach(Array(upcomingExercises.enumerated()), id: \.element.id) { index, exercise in
                                                UpcomingExerciseRow(
                                                    exercise: exercise,
                                                    onRemove: { removeUpcomingExercise(at: index) },
                                                    onMove: { source, destination in
                                                        moveExercise(from: source, to: destination)
                                                    },
                                                    index: index
                                                )
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color(white: 0.22))
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                    
                    Spacer()
                    
                    // Finish Workout Button (nur wenn letztes Set)
                    if isLastSet && currentSet?.completed == true {
                        VStack(spacing: 10) {
                            Text("You finished your workout!")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.green)
                            
                            Button(action: finishWorkout) {
                                Text("Finish Workout")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                }
                
                // Floating Add Exercise Button
                Button(action: { showingAddExercise = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.blue)
                        .background(Circle().fill(Color(red: 0.17, green: 0.17, blue: 0.17)))
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingFinishAlert = true
                    }
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
        
        // Toggle completion status
        completedExercises[index].completed.toggle()
        
        // If completing and it's not the last set, move to next
        if completedExercises[index].completed && !isLastSet {
            if currentSetIndex < setsForCurrentExercise.count - 1 {
                // Next set in same exercise
                currentSetIndex += 1
            } else if currentExerciseIndex < workoutSets.count - 1 {
                // Next exercise
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
        
        // Insert at the end of current exercise's sets
        _ = completedExercises.filter { $0.exerciseId == currentWorkoutSet.exerciseId }
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
        
        // Adjust current set index if needed
        if currentSetIndex >= setsForCurrentExercise.count {
            currentSetIndex = max(0, setsForCurrentExercise.count - 1)
        }
    }
    
    private func removeCurrentExercise() {
        guard currentExerciseIndex < workoutSets.count else { return }
        
        // Remove all sets for this exercise
        if let currentWorkoutSet = currentWorkoutSet {
            completedExercises.removeAll { $0.exerciseId == currentWorkoutSet.exerciseId }
        }
        
        // Remove from workout sets
        workoutSets.remove(at: currentExerciseIndex)
        
        // Update current indices
        if currentExerciseIndex >= workoutSets.count {
            currentExerciseIndex = max(0, workoutSets.count - 1)
        }
        currentSetIndex = 0
    }
    
    private func removeUpcomingExercise(at index: Int) {
        let actualIndex = currentExerciseIndex + 1 + index
        guard actualIndex < workoutSets.count else { return }
        
        // Remove all sets for this exercise
        let exerciseId = workoutSets[actualIndex].exerciseId
        completedExercises.removeAll { $0.exerciseId == exerciseId }
        
        // Remove from workout sets
        workoutSets.remove(at: actualIndex)
    }
    
    private func moveExercise(from source: Int, to destination: Int) {
        let sourceIndex = currentExerciseIndex + 1 + source
        let destinationIndex = currentExerciseIndex + 1 + destination
        
        guard sourceIndex < workoutSets.count && destinationIndex < workoutSets.count else { return }
        
        let exerciseToMove = workoutSets[sourceIndex]
        workoutSets.remove(at: sourceIndex)
        workoutSets.insert(exerciseToMove, at: destinationIndex)
    }
    
    private func addExerciseDuringWorkout(exerciseId: String, reps: Int, weight: Double) {
        let newWorkoutSet = WorkoutSet(
            exerciseId: exerciseId,
            reps: reps,
            weight: weight,
            sets: 1
        )
        
        // Add to workout sets (insert after current exercise)
        workoutSets.insert(newWorkoutSet, at: currentExerciseIndex + 1)
        
        // Add to completed exercises
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
            exercises: completedSets, // Nur abgehaktete Sets speichern
            duration: duration
        )
        workoutCompleted = true
        
        // Automatisch nach 3 Sekunden schließen
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isPresented = false
        }
    }
}

// Upcoming Exercise Row mit Drag & Drop
struct UpcomingExerciseRow: View {
    let exercise: Exercise
    let onRemove: () -> Void
    let onMove: (Int, Int) -> Void
    let index: Int
    
    @State private var isDragging = false
    
    var body: some View {
        HStack {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))
            
            Text(exercise.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(exercise.muscleGroup)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red.opacity(0.7))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(white: 0.18))
        .cornerRadius(8)
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .shadow(color: isDragging ? .blue.opacity(0.3) : .clear, radius: 4)
        .onLongPressGesture {
            // Start drag (in einer echten Implementierung würden wir hier Drag & Drop einleiten)
            isDragging = true
        }
    }
}

// View zum Hinzufügen von Übungen während des Workouts (bleibt gleich wie vorher)
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
                Color(red: 0.17, green: 0.17, blue: 0.17)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Picker("Muscle Group", selection: $selectedMuscleGroup) {
                        ForEach(muscleGroups, id: \.self) { group in
                            Text(group).tag(group)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(currentExercises) { exercise in
                                Button(action: {
                                    selectedExerciseId = exercise.id
                                    reps = exercise.lastReps
                                    weight = exercise.lastWeight
                                }) {
                                    HStack {
                                        Text(exercise.name)
                                            .foregroundColor(.white)
                                        Spacer()
                                        if selectedExerciseId == exercise.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding()
                                    .background(selectedExerciseId == exercise.id ? Color.blue.opacity(0.3) : Color(white: 0.22))
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    if !selectedExerciseId.isEmpty {
                        VStack(spacing: 15) {
                            Text("Configure Exercise")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 30) {
                                VStack(spacing: 8) {
                                    Text("Reps")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    HStack {
                                        Button(action: { reps = max(1, reps - 1) }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Text("\(reps)")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 40)
                                        
                                        Button(action: { reps += 1 }) {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                
                                VStack(spacing: 8) {
                                    Text("Weight (kg)")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    HStack {
                                        Button(action: { weight = max(0, weight - 2.5) }) {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                        
                                        Text(String(format: "%.1f", weight))
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 50)
                                        
                                        Button(action: { weight += 2.5 }) {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(white: 0.22))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    Button("Add Exercise") {
                        onExerciseAdded(selectedExerciseId, reps, weight)
                        isPresented = false
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedExerciseId.isEmpty ? Color.gray : Color.green)
                    .cornerRadius(12)
                    .padding()
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
                }
            }
        }
    }
}

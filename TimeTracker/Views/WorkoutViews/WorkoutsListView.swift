import SwiftUI

struct WorkoutsListView: View {
    @ObservedObject var manager: TimeTrackerManager
    @State private var showingCreateWorkout = false
    @State private var newWorkoutName = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.17, green: 0.17, blue: 0.17)
                    .ignoresSafeArea()
                
                if manager.data.workouts.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("No workouts yet")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Create your first workout to get started")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Button("Create Workout") {
                            showingCreateWorkout = true
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.top, 20)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(manager.data.workouts) { workout in
                                NavigationLink(destination: WorkoutDetailViewWithStats(manager: manager, workout: workout)) {
                                    EnhancedWorkoutCard(workout: workout, manager: manager)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateWorkout = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingCreateWorkout) {
                CreateWorkoutSheet(manager: manager, workoutName: $newWorkoutName, isPresented: $showingCreateWorkout)
            }
        }
    }
}

// CREATE WORKOUT SHEET IN DERSELBEN DATEI DEFINIEREN
struct CreateWorkoutSheet: View {
    @ObservedObject var manager: TimeTrackerManager
    @Binding var workoutName: String
    @Binding var isPresented: Bool
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Workout Name", text: $workoutName)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .focused($isFocused)
                
                Spacer()
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        if !workoutName.isEmpty {
                            let _ = manager.createWorkout(name: workoutName)
                            workoutName = ""
                            isPresented = false
                        }
                    }
                    .disabled(workoutName.isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isFocused = true
                }
            }
        }
    }
}

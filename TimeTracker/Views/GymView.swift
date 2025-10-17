import SwiftUI

struct GymView: View {
    @ObservedObject var manager: TimeTrackerManager
    @State private var showingWorkouts = false
    @State private var showingWorkoutSelection = false
    @State private var selectedDate = Date()
    @State private var showingDateDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.17, green: 0.17, blue: 0.17)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Gym Schedule
                        VStack(spacing: 15) {
                            Text("🏋️ Gym Schedule")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                ForEach(1...7, id: \.self) { day in
                                    VStack(spacing: 8) {
                                        Text(dayName(for: day))
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Button(action: {
                                            manager.toggleGymDay(day)
                                        }) {
                                            Image(systemName: manager.data.gymDays.contains(day) ? "checkmark.square.fill" : "square")
                                                .font(.system(size: 24))
                                                .foregroundColor(manager.data.gymDays.contains(day) ? .green : .gray)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding()
                        .background(Color(white: 0.22))
                        .cornerRadius(12)
                        
                        // Workout Actions
                        VStack(spacing: 12) {
                            Button(action: {
                                showingWorkoutSelection = true
                            }) {
                                Text("Start Workout")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                showingWorkouts = true
                            }) {
                                Text("My Workouts")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 15)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Consistency Calendar
                        VStack(spacing: 15) {
                            HStack {
                                Text("📅 Workout Calendar")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button("Today") {
                                    selectedDate = Date()
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.blue)
                            }
                            
                            GymWorkoutCalendarView(
                                manager: manager,
                                selectedDate: $selectedDate,
                                showingDateDetail: $showingDateDetail
                            )
                        }
                        .padding()
                        .background(Color(white: 0.22))
                        .cornerRadius(12)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Gym Tracker")
            .sheet(isPresented: $showingWorkouts) {
                WorkoutsListView(manager: manager)
            }
            .sheet(isPresented: $showingWorkoutSelection) {
                WorkoutSelectionView(manager: manager, isPresented: $showingWorkoutSelection)
            }
            .sheet(isPresented: $showingDateDetail) {
                DateWorkoutDetailView(manager: manager, date: selectedDate, isPresented: $showingDateDetail)
            }
        }
    }
    
    func dayName(for weekday: Int) -> String {
        let days = ["", "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        return days[weekday]
    }
}

// Umbenannt von WorkoutCalendarView zu GymWorkoutCalendarView
struct GymWorkoutCalendarView: View {
    @ObservedObject var manager: TimeTrackerManager
    @Binding var selectedDate: Date
    @Binding var showingDateDetail: Bool
    
    var completionDates: [Date] {
        manager.getWorkoutCompletionDates()
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Month Header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(monthYearString(from: selectedDate))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                }
            }
            
            // Weekday Headers
            HStack {
                ForEach(weekdaySymbols(), id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(getDaysInMonth(), id: \.self) { date in
                    if date == nil {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 40)
                    } else {
                        let currentDate = date!
                        let hasWorkout = completionDates.contains { Calendar.current.isDate($0, inSameDayAs: currentDate) }
                        let isSelected = Calendar.current.isDate(currentDate, inSameDayAs: selectedDate)
                        let isToday = Calendar.current.isDate(currentDate, inSameDayAs: Date())
                        
                        Button(action: {
                            selectedDate = currentDate
                            showingDateDetail = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.3) : Color.clear))
                                
                                if hasWorkout {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 8, height: 8)
                                        .offset(y: 8)
                                }
                                
                                Text("\(Calendar.current.component(.day, from: currentDate))")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .frame(height: 40)
                        }
                    }
                }
            }
            
            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Workout")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Text("Today")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 8, height: 8)
                    Text("Selected")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func weekdaySymbols() -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols
    }
    
    private func getDaysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: selectedDate)!
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        var days: [Date?] = []
        
        // Add empty days for the first week
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
        // Add all days of the month
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    private func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

// Date Workout Detail View
struct DateWorkoutDetailView: View {
    @ObservedObject var manager: TimeTrackerManager
    let date: Date
    @Binding var isPresented: Bool
    
    var completedSessions: [CompletedWorkoutSession] {
        manager.getCompletedSessionsForDate(date)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.17, green: 0.17, blue: 0.17)
                    .ignoresSafeArea()
                
                if completedSessions.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "dumbbell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("No workouts on this day")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("\(formattedDate)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(completedSessions) { session in
                                if let workout = manager.data.workouts.first(where: { $0.id == session.workoutId }) {
                                    CompletedWorkoutCard(session: session, workout: workout, manager: manager)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

struct CompletedWorkoutCard: View {
    let session: CompletedWorkoutSession
    let workout: Workout
    @ObservedObject var manager: TimeTrackerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(workout.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
            
            Text("Duration: \(formatDuration(session.duration))")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            
            ForEach(session.completedExercises) { exerciseSet in
                if let exercise = manager.data.exercises.first(where: { $0.id == exerciseSet.exerciseId }) {
                    HStack {
                        Text(exercise.name)
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium))
                        
                        Spacer()
                        
                        Text("\(exerciseSet.reps) × \(String(format: "%.1f", exerciseSet.weight)) kg")
                            .foregroundColor(.green)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
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
}

// WORKOUT SELECTION VIEW IN DERSELBEN DATEI DEFINIEREN
struct WorkoutSelectionView: View {
    @ObservedObject var manager: TimeTrackerManager
    @Binding var isPresented: Bool
    @State private var selectedWorkout: Workout?
    @State private var showingExecution = false
    
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
                        
                        Text("No workouts created yet")
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("Create your first workout in 'My Workouts'")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(manager.data.workouts) { workout in
                                Button(action: {
                                    selectedWorkout = workout
                                    showingExecution = true
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(workout.name)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.white)
                                            
                                            HStack(spacing: 15) {
                                                Label("\(workout.sets.count) ex", systemImage: "list.bullet")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.white.opacity(0.6))
                                                
                                                Label("\(workout.sessions.count) sessions", systemImage: "calendar")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.white.opacity(0.6))
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "play.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 28))
                                    }
                                    .padding()
                                    .background(Color(white: 0.22))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Select Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
            }
            .sheet(isPresented: $showingExecution) {
                if let workout = selectedWorkout {
                    WorkoutExecutionView(manager: manager, workout: workout, isPresented: $isPresented)
                }
            }
        }
    }
}

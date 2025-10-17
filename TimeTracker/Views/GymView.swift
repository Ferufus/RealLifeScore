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
                // Dunkler Gradient wie im SleepView
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.10, green: 0.10, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.10)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Gym Schedule
                        VStack(spacing: 20) {
                            Text("🏋️ Gym Schedule")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                ForEach(1...7, id: \.self) { day in
                                    VStack(spacing: 10) {
                                        Text(dayName(for: day))
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        Button(action: {
                                            manager.toggleGymDay(day)
                                        }) {
                                            Image(systemName: manager.data.gymDays.contains(day) ? "checkmark.square.fill" : "square")
                                                .font(.system(size: 28))
                                                .foregroundColor(manager.data.gymDays.contains(day) ? .green : .gray)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.15, green: 0.15, blue: 0.20))
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal, 20)
                        
                        // Workout Actions
                        VStack(spacing: 15) {
                            Button(action: {
                                showingWorkoutSelection = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 22, weight: .semibold))
                                    
                                    Text("Start Workout")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: [.green, .green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                            
                            Button(action: {
                                showingWorkouts = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 22, weight: .semibold))
                                    
                                    Text("My Workouts")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Consistency Calendar
                        VStack(spacing: 20) {
                            HStack {
                                Text("📅 Workout Calendar")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button("Today") {
                                    selectedDate = Date()
                                }
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.blue)
                            }
                            
                            GymWorkoutCalendarView(
                                manager: manager,
                                selectedDate: $selectedDate,
                                showingDateDetail: $showingDateDetail
                            )
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.15, green: 0.15, blue: 0.20))
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Gym Tracker")
            .navigationBarTitleDisplayMode(.large)
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

struct GymWorkoutCalendarView: View {
    @ObservedObject var manager: TimeTrackerManager
    @Binding var selectedDate: Date
    @Binding var showingDateDetail: Bool
    
    var completionDates: [Date] {
        manager.getWorkoutCompletionDates()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Month Header
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Text(monthYearString(from: selectedDate))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // Weekday Headers
            HStack {
                ForEach(weekdaySymbols(), id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
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
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
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
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                    Text("Today")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.blue.opacity(0.5))
                        .frame(width: 8, height: 8)
                    Text("Selected")
                        .font(.system(size: 12, design: .rounded))
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

struct DateWorkoutDetailView: View {
    @ObservedObject var manager: TimeTrackerManager
    let date: Date
    @Binding var isPresented: Bool
    @State private var currentDisplayDate: Date
    
    init(manager: TimeTrackerManager, date: Date, isPresented: Binding<Bool>) {
        self.manager = manager
        self.date = date
        self._isPresented = isPresented
        self._currentDisplayDate = State(initialValue: date)
    }
    
    var completedSessions: [CompletedWorkoutSession] {
        manager.getCompletedSessionsForDate(currentDisplayDate)
    }
    
    var allWorkoutDates: [Date] {
        manager.getWorkoutCompletionDates().sorted()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.15),
                        Color(red: 0.08, green: 0.08, blue: 0.12)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Navigation Header with Swipe
                    HStack {
                        Button(action: navigateToPreviousWorkout) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(canNavigateToPrevious ? .blue : .gray)
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .disabled(!canNavigateToPrevious)
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text(formattedDate)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            if completedSessions.count > 0 {
                                Text("\(completedSessions.count) workout\(completedSessions.count == 1 ? "" : "s")")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: navigateToNextWorkout) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(canNavigateToNext ? .blue : .gray)
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .disabled(!canNavigateToNext)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    if completedSessions.isEmpty {
                        VStack(spacing: 20) {
                            Spacer()
                            
                            Image(systemName: "dumbbell.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.3))
                            
                            VStack(spacing: 8) {
                                Text("No workouts on this day")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Swipe to navigate to days with workouts")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(.white.opacity(0.5))
                                    .multilineTextAlignment(.center)
                            }
                            
                            Spacer()
                        }
                        .padding()
                    } else {
                        ScrollView {
                            VStack(spacing: 16) {
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.blue)
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        if abs(horizontalAmount) > 50 {
                            if horizontalAmount > 0 {
                                navigateToPreviousWorkout()
                            } else {
                                navigateToNextWorkout()
                            }
                        }
                    }
            )
        }
    }
    
    private var canNavigateToPrevious: Bool {
        guard let currentIndex = allWorkoutDates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: currentDisplayDate) }) else {
            return false
        }
        return currentIndex > 0
    }
    
    private var canNavigateToNext: Bool {
        guard let currentIndex = allWorkoutDates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: currentDisplayDate) }) else {
            return false
        }
        return currentIndex < allWorkoutDates.count - 1
    }
    
    private func navigateToPreviousWorkout() {
        guard let currentIndex = allWorkoutDates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: currentDisplayDate) }),
              currentIndex > 0 else { return }
        
        currentDisplayDate = allWorkoutDates[currentIndex - 1]
    }
    
    private func navigateToNextWorkout() {
        guard let currentIndex = allWorkoutDates.firstIndex(where: { Calendar.current.isDate($0, inSameDayAs: currentDisplayDate) }),
              currentIndex < allWorkoutDates.count - 1 else { return }
        
        currentDisplayDate = allWorkoutDates[currentIndex + 1]
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(currentDisplayDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(currentDisplayDate) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: currentDisplayDate)
        }
    }
}

struct CompletedWorkoutCard: View {
    let session: CompletedWorkoutSession
    let workout: Workout
    @ObservedObject var manager: TimeTrackerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(workout.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Duration: \(formatDuration(session.duration))")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            ForEach(session.completedExercises) { exerciseSet in
                if let exercise = manager.data.exercises.first(where: { $0.id == exerciseSet.exerciseId }) {
                    HStack {
                        Text(exercise.name)
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                        
                        Spacer()
                        
                        Text("\(exerciseSet.reps) × \(String(format: "%.1f", exerciseSet.weight)) kg")
                            .foregroundColor(.green)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.20))
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
        )
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

struct WorkoutSelectionView: View {
    @ObservedObject var manager: TimeTrackerManager
    @Binding var isPresented: Bool
    @State private var selectedWorkout: Workout?
    @State private var showingExecution = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.12, green: 0.12, blue: 0.15),
                        Color(red: 0.08, green: 0.08, blue: 0.12)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if manager.data.workouts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                        
                        Text("No workouts created yet")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("Create your first workout in 'My Workouts'")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(manager.data.workouts) { workout in
                                Button(action: {
                                    selectedWorkout = workout
                                    showingExecution = true
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(workout.name)
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                            
                                            HStack(spacing: 15) {
                                                Label("\(workout.sets.count) ex", systemImage: "list.bullet")
                                                    .font(.system(size: 14, design: .rounded))
                                                    .foregroundColor(.white.opacity(0.6))
                                                
                                                Label("\(workout.sessions.count) sessions", systemImage: "calendar")
                                                    .font(.system(size: 14, design: .rounded))
                                                    .foregroundColor(.white.opacity(0.6))
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "play.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 32))
                                    }
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(red: 0.15, green: 0.15, blue: 0.20))
                                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                                    )
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
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.red)
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

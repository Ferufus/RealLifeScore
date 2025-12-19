//
//  HabitsView.swift
//  TimeTracker
//
//  Created by Thomas Bürger on 18.12.25.
//

import SwiftUI

struct HabitsView: View {
    @ObservedObject var manager: TimeTrackerManager
    @State private var showingAddHabit = false
    @State private var selectedHabit: Habit?
    @State private var selectedDate = Date()
    
    var goodHabits: [Habit] {
        manager.data.habits.filter { $0.type == .good }
    }
    
    var badHabits: [Habit] {
        manager.data.habits.filter { $0.type == .bad }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
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
                    VStack(spacing: 20) {
                        // Stats Header
                        habitStatsSection
                        
                        // Good Habits
                        if !goodHabits.isEmpty {
                            habitSection(title: "✅ Good Habits", habits: goodHabits, color: .green)
                        }
                        
                        // Bad Habits
                        if !badHabits.isEmpty {
                            habitSection(title: "❌ Bad Habits", habits: badHabits, color: .red)
                        }
                        
                        // Empty State
                        if manager.data.habits.isEmpty {
                            emptyStateView
                        }
                        
                        // Calendar View (if habit selected)
                        if let habit = selectedHabit {
                            habitCalendarSection(habit: habit)
                        }
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.vertical, 20)
                }
                
                // Floating Add Button
                floatingAddButton
            }
            .navigationTitle("Habits")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(manager: manager, isPresented: $showingAddHabit)
            }
        }
    }
    
    // MARK: - View Components
    
    private var habitStatsSection: some View {
        HStack(spacing: 12) {
            StatBubble(
                title: "Total",
                value: "\(manager.data.habits.count)",
                icon: "list.bullet",
                color: .blue
            )
            
            StatBubble(
                title: "Active Streak",
                value: "\(totalActiveStreak)",
                icon: "flame.fill",
                color: .orange
            )
            
            StatBubble(
                title: "Avg Rate",
                value: "\(Int(averageCompletionRate))%",
                icon: "chart.line.uptrend.xyaxis",
                color: .purple
            )
        }
        .padding(.horizontal, 20)
    }
    
    private func habitSection(title: String, habits: [Habit], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(habits.count)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.1)))
            }
            
            LazyVStack(spacing: 12) {
                ForEach(habits) { habit in
                    HabitRowView(
                        habit: habit,
                        manager: manager,
                        isSelected: selectedHabit?.id == habit.id
                    ) {
                        if selectedHabit?.id == habit.id {
                            selectedHabit = nil
                        } else {
                            selectedHabit = habit
                        }
                    }
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
    }
    
    private func habitCalendarSection(habit: Habit) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("📅 \(habit.name) - Calendar")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { selectedHabit = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            HabitCalendarView(habit: habit, manager: manager, selectedDate: $selectedDate)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.20))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No Habits Yet")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Start tracking your habits to build a better you")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
    
    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button(action: { showingAddHabit = true }) {
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
                .padding(20)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalActiveStreak: Int {
        manager.data.habits.reduce(0) { $0 + $1.currentStreak }
    }
    
    private var averageCompletionRate: Double {
        guard !manager.data.habits.isEmpty else { return 0 }
        let total = manager.data.habits.reduce(0.0) { $0 + $1.completionRate }
        return total / Double(manager.data.habits.count)
    }
}

// MARK: - Supporting Views

struct HabitRowView: View {
    let habit: Habit
    @ObservedObject var manager: TimeTrackerManager
    let isSelected: Bool
    let action: () -> Void
    
    @State private var showingDetail = false
    
    var todayEntry: HabitEntry? {
        manager.getHabitEntry(habitId: habit.id, date: Date())
    }
    
    var habitColor: Color {
        habit.type == .good ? .green : .red
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    // Checkbox for today
                    Button(action: {
                        manager.toggleHabitEntry(habitId: habit.id, date: Date())
                    }) {
                        Image(systemName: todayEntry?.completed == true ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 28))
                            .foregroundColor(todayEntry?.completed == true ? habitColor : .white.opacity(0.3))
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(habit.name)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 12))
                                Text("\(habit.currentStreak) day\(habit.currentStreak == 1 ? "" : "s")")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                            }
                            .foregroundColor(.orange)
                            if habit.completionRate > 0 {
                                Circle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 3, height: 3)
                                
                                Text("\(Int(habit.completionRate))% complete")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // More Button
                    Button(action: { showingDetail = true }) {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.3))
                        .rotationEffect(.degrees(isSelected ? 90 : 0))
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .frame(height: 4)
                            .foregroundColor(Color.white.opacity(0.1))
                        
                        Capsule()
                            .frame(width: CGFloat(habit.completionRate / 100) * geometry.size.width, height: 4)
                            .foregroundColor(habitColor)
                    }
                }
                .frame(height: 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? habitColor.opacity(0.1) : Color(red: 0.18, green: 0.18, blue: 0.22))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? habitColor : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
        .sheet(isPresented: $showingDetail) {
            HabitDetailView(manager: manager, habit: habit, isPresented: $showingDetail)
        }
    }
}
    
// MARK: - Habit Calendar View

struct HabitCalendarView: View {
    let habit: Habit
    @ObservedObject var manager: TimeTrackerManager
    @Binding var selectedDate: Date
    
    var body: some View {
        VStack(spacing: 20) {
            // Month Navigation
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
                
                Text(monthYearString)
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
                ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(getDaysInMonth(), id: \.self) { date in
                    if let currentDate = date {
                        let entry = manager.getHabitEntry(habitId: habit.id, date: currentDate)
                        let isCompleted = entry?.completed == true
                        let isToday = Calendar.current.isDateInToday(currentDate)
                        
                        Button(action: {
                            manager.toggleHabitEntry(habitId: habit.id, date: currentDate)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(isCompleted ?
                                          (habit.type == .good ? Color.green : Color.red) :
                                            Color.white.opacity(0.1))
                                
                                if isToday {
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 2)
                                }
                                
                                Text("\(Calendar.current.component(.day, from: currentDate))")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(isCompleted ? .white : .white.opacity(0.7))
                            }
                            .frame(height: 40)
                        }
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 40)
                    }
                }
            }
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private func getDaysInMonth() -> [Date?] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: selectedDate)!
        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedDate))!
        
        var firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        firstWeekday = (firstWeekday == 1) ? 7 : firstWeekday - 1 // Adjust for Monday start
        
        var days: [Date?] = []
        
        for _ in 1..<firstWeekday {
            days.append(nil)
        }
        
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

// MARK: - Add Habit View

struct AddHabitView: View {
    @ObservedObject var manager: TimeTrackerManager
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedType: HabitType = .good
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, description
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
                
                VStack(spacing: 30) {
                    VStack(spacing: 16) {
                        Image(systemName: "target")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("New Habit")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Habit Name")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextField("e.g., Morning Exercise", text: $name)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(red: 0.18, green: 0.18, blue: 0.22))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .font(.system(size: 16, design: .rounded))
                                .focused($focusedField, equals: .name)
                        }
                        
                        // Description Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (Optional)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextField("What does this habit involve?", text: $description)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(red: 0.18, green: 0.18, blue: 0.22))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .font(.system(size: 16, design: .rounded))
                                .focused($focusedField, equals: .description)
                        }
                        
                        // Type Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Habit Type")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            
                            HStack(spacing: 12) {
                                HabitTypeButton(
                                    type: .good,
                                    isSelected: selectedType == .good
                                ) {
                                    selectedType = .good
                                }
                                
                                HabitTypeButton(
                                    type: .bad,
                                    isSelected: selectedType == .bad
                                ) {
                                    selectedType = .bad
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    Button(action: addHabit) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text("Create Habit")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: name.isEmpty ? [.gray, .gray] : [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: name.isEmpty ? .clear : .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .disabled(name.isEmpty)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    focusedField = .name
                }
            }
        }
    }
    
    private func addHabit() {
        _ = manager.addHabit(name: name, description: description, type: selectedType)
        isPresented = false
    }
}

struct HabitTypeButton: View {
    let type: HabitType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                
                Text(type == .good ? "Good Habit" : "Bad Habit")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                
                Text(type == .good ? "Build it" : "Break it")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ?
                        LinearGradient(
                            colors: type == .good ? [.green, .mint] : [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color(red: 0.18, green: 0.18, blue: 0.22), Color(red: 0.18, green: 0.18, blue: 0.22)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? (type == .good ? Color.green : Color.red) : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? (type == .good ? .green.opacity(0.3) : .red.opacity(0.3)) : .clear, radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Habit Detail View

struct HabitDetailView: View {
    @ObservedObject var manager: TimeTrackerManager
    @State var habit: Habit
    @Binding var isPresented: Bool
    @Environment(\.dismiss) var dismiss
    
    @State private var showingDeleteAlert = false
    @State private var showingReminderConfig = false
    
    var body: some View {
        NavigationView {
            ZStack {
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
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill((habit.type == .good ? Color.green : Color.red).opacity(0.2))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: habit.type.icon)
                                    .font(.system(size: 40))
                                    .foregroundColor(habit.type == .good ? .green : .red)
                            }
                            
                            Text(habit.name)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            if !habit.description.isEmpty {
                                Text(habit.description)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                            }
                        }
                        
                        // Stats
                        HStack(spacing: 12) {
                            StatBubble(
                                title: "Current Streak",
                                value: "\(habit.currentStreak)",
                                icon: "flame.fill",
                                color: .orange
                            )
                            
                            StatBubble(
                                title: "Longest Streak",
                                value: "\(habit.longestStreak)",
                                icon: "trophy.fill",
                                color: .yellow
                            )
                            
                            StatBubble(
                                title: "Completion",
                                value: "\(Int(habit.completionRate))%",
                                icon: "chart.pie.fill",
                                color: .purple
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Reminder Toggle
                        VStack(spacing: 16) {
                            Toggle(isOn: Binding(
                                get: { habit.reminderEnabled },
                                set: { enabled in
                                    if enabled {
                                        showingReminderConfig = true
                                    } else {
                                        manager.cancelHabitReminder(habitId: habit.id)
                                        habit = manager.data.habits.first(where: { $0.id == habit.id }) ?? habit
                                    }
                                }
                            )) {
                                HStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.blue)
                                    Text("Daily Reminder")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            .tint(.blue)
                            
                            if let reminderTime = habit.reminderTime {
                                Text("Reminder at \(reminderTime, style: .time)")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.15, green: 0.15, blue: 0.20))
                        )
                        .padding(.horizontal, 20)
                        
                        // Delete Button
                        Button(action: { showingDeleteAlert = true }) {
                            Text("Delete Habit")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
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
            .alert("Delete Habit", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    manager.deleteHabit(id: habit.id)
                    isPresented = false
                }
            } message: {
                Text("Are you sure you want to delete this habit? All progress will be lost.")
            }
            .sheet(isPresented: $showingReminderConfig) {
                HabitReminderConfigView(
                    manager: manager,
                    habit: $habit,
                    isPresented: $showingReminderConfig
                )
            }
        }
    }
}

struct HabitReminderConfigView: View {
    @ObservedObject var manager: TimeTrackerManager
    @Binding var habit: Habit
    @Binding var isPresented: Bool
    
    @State private var reminderTime = Date()
    
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
                
                VStack(spacing: 30) {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Set Reminder")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Get a daily reminder for \(habit.name)")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .padding()
                        .background(Color(red: 0.18, green: 0.18, blue: 0.22))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    Button(action: setReminder) {
                        Text("Set Reminder")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.red)
                }
            }
            .onAppear {
                if let existing = habit.reminderTime {
                    reminderTime = existing
                }
            }
        }
    }
    
    private func setReminder() {
        manager.scheduleHabitReminder(habitId: habit.id, time: reminderTime)
        habit = manager.data.habits.first(where: { $0.id == habit.id }) ?? habit
        isPresented = false
    }
}
                            

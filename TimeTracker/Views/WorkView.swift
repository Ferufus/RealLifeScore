import SwiftUI
import Charts

struct WorkView: View {
    @ObservedObject var manager: TimeTrackerManager
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var expandedCategories: Set<String> = []
    
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
                    VStack(spacing: 20) {
                        // Work Statistics Header
                        statisticsSection
                        
                        // Work Categories
                        categoriesSection
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.vertical, 20)
                }
                
                // Floating Add Button
                floatingAddButton
            }
            .navigationTitle("Work Tracker")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddCategory) {
                WorkAddCategorySheet(
                    categoryName: $newCategoryName,
                    onSave: {
                        if !newCategoryName.isEmpty {
                            manager.addCategory(name: newCategoryName, type: "work")
                            newCategoryName = ""
                            showingAddCategory = false
                        }
                    },
                    onCancel: {
                        newCategoryName = ""
                        showingAddCategory = false
                    }
                )
            }
        }
    }
    
    // MARK: - View Components
    
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("💼 Work Statistics")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Statistics Cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                WorkStatCard(
                    title: "Total Hours",
                    value: String(format: "%.1fh", totalWorkHours),
                    color: .green
                )
                
                WorkStatCard(
                    title: "Daily Average",
                    value: String(format: "%.1fh", averageDailyHours),
                    color: .blue
                )
                
                WorkStatCard(
                    title: "Work Days",
                    value: "\(workDaysCount)",
                    color: .orange
                )
                
                WorkStatCard(
                    title: "Categories",
                    value: "\(manager.data.workCategories.count)",
                    color: .purple
                )
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
    
    private var categoriesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("📁 Work Categories")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(manager.data.workCategories.count)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.1)))
            }
            
            if manager.data.workCategories.isEmpty {
                emptyCategoriesPlaceholder
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(manager.data.workCategories) { category in
                        WorkCategoryCard(
                            category: category,
                            isExpanded: expandedCategories.contains(category.id),
                            manager: manager,
                            onToggleExpand: {
                                if expandedCategories.contains(category.id) {
                                    expandedCategories.remove(category.id)
                                } else {
                                    expandedCategories.insert(category.id)
                                }
                            },
                            onDelete: {
                                manager.deleteCategory(id: category.id, type: "work")
                                expandedCategories.remove(category.id)
                            }
                        )
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
    
    private var emptyCategoriesPlaceholder: some View {
        VStack(spacing: 15) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No Work Categories")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Add your first work category to start tracking")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 30)
    }
    
    private var floatingAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showingAddCategory = true }) {
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
    
    private var weeklyWorkData: [WeeklyWorkData] {
        getWeeklyWorkData()
    }
    
    private var totalWorkHours: Double {
        weeklyWorkData.reduce(0) { $0 + $1.totalHours }
    }
    
    private var averageDailyHours: Double {
        let daysWithData = weeklyWorkData.filter { $0.totalHours > 0 }.count
        guard daysWithData > 0 else { return 0 }
        return totalWorkHours / Double(daysWithData)
    }
    
    private var workDaysCount: Int {
        weeklyWorkData.filter { $0.totalHours > 0 }.count
    }
    
    // MARK: - Helper Methods
    
    private func getWeeklyWorkData() -> [WeeklyWorkData] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [WeeklyWorkData] = []
        
        // Erstelle Daten für die letzten 7 Tage
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: date) - 1]
            
            // Sammle alle Work-Sessions für diesen Tag über alle Kategorien
            var totalHours: Double = 0
            var categoryHours: [String: Double] = [:]
            
            for category in manager.data.workCategories {
                let dateString = manager.dateString(from: date)
                let dayMinutes = category.dailyTimes[dateString] ?? 0
                let dayHours = Double(dayMinutes) / 60.0
                
                if dayHours > 0 {
                    categoryHours[category.id] = dayHours
                    totalHours += dayHours
                }
            }
            
            weeklyData.append(WeeklyWorkData(
                weekday: weekday,
                totalHours: totalHours,
                categoryHours: categoryHours
            ))
        }
        
        return weeklyData.reversed() // Ältester zuerst
    }
    
    private func parseDateString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: dateString)
    }
}

// MARK: - Supporting Structures

struct WeeklyWorkData: Identifiable {
    let id = UUID()
    let weekday: String
    let totalHours: Double
    let categoryHours: [String: Double] // categoryId -> hours
}

struct WorkStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.18, green: 0.18, blue: 0.22))
        )
    }
}

// MARK: - Verbesserte WorkCategoryCard mit integriertem Weekly Overview

struct WorkCategoryCard: View {
    let category: CategoryItem
    let isExpanded: Bool
    @ObservedObject var manager: TimeTrackerManager
    let onToggleExpand: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false //
    
    // Berechne Stunden für diese Kategorie in der letzten Woche
    private var hoursThisWeek: Double {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let recentTimes = category.dailyTimes.filter { dateString, hours in
            guard let date = parseDateString(dateString) else { return false }
            return date > oneWeekAgo
        }
        
        return recentTimes.values.reduce(0, +) / 60.0 // Convert minutes to hours
    }
    
    // Weekly Data für diese spezifische Kategorie
    private var weeklyCategoryData: [WeeklyCategoryData] {
        getWeeklyCategoryData()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Header mit Delete Button in der Ecke
            categoryHeader
            
            // Expanded Content
            if isExpanded {
                expandedContent
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.22, green: 0.22, blue: 0.25))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    private var categoryHeader: some View {
            ZStack(alignment: .topTrailing) {
                Button(action: onToggleExpand) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(category.name)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                    Text("\(String(format: "%.1f", hoursThisWeek))h this week")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue)
                                    Text("\(category.dailyTimes.count) days")
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if category.isRunning {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                                .padding(4)
                        }
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .padding(16)
                }
                
                // 🆕 Delete button now shows a confirmation dialog instead of deleting immediately
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red.opacity(0.8))
                        .background(Circle().fill(Color.white.opacity(0.9)))
                }
                .padding(8)
                .confirmationDialog(
                    "Delete Category?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button("Delete", role: .destructive) {
                        onDelete() // ⚠️ Only delete after confirmation
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Are you sure you want to delete this category? 🗑️\nAll data related to it will be permanently lost.")
                }
            }
        }
    
    private var expandedContent: some View {
        VStack(spacing: 16) {
            // Start/Stop Button als Hauptaktion
            mainActionButton
            
            // Weekly Overview Chart für diese Kategorie
            weeklyOverviewSection
            
            // Current Timer Display
            if category.isRunning {
                timerDisplay
            }
        }
        .padding(16)
        .background(Color(red: 0.18, green: 0.18, blue: 0.22))
    }
    
    private var mainActionButton: some View {
        Button(action: {
            manager.toggleTimer(id: category.id, type: "work")
        }) {
            HStack(spacing: 12) {
                Image(systemName: category.isRunning ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(category.isRunning ? "Stop Tracking" : "Start Tracking")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: category.isRunning ? [.red, .red.opacity(0.8)] : [.green, .green.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: category.isRunning ? .red.opacity(0.4) : .green.opacity(0.4), radius: 8, x: 0, y: 4)
        }
    }
    
    private var weeklyOverviewSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("📊 Weekly Overview")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if weeklyCategoryData.allSatisfy({ $0.hours == 0 }) {
                emptyWeeklyPlaceholder
            } else {
                CategoryWeeklyChartView(weeklyData: weeklyCategoryData)
                    .frame(height: 120)
            }
        }
    }
    
    private var emptyWeeklyPlaceholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 30))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No data this week")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(height: 120)
    }
    
    private var timerDisplay: some View {
        let (today, week, total) = manager.getCurrentTime(id: category.id, type: "work")
        return VStack(spacing: 8) {
            Text("Currently Tracking")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.green)
            
            HStack(spacing: 16) {
                timerStatItem(title: "Today", value: "\(String(format: "%.1f", today))m")
                timerStatItem(title: "This Week", value: "\(String(format: "%.1f", week))m")
                timerStatItem(title: "Total", value: "\(String(format: "%.1f", total))m")
            }
        }
        .padding(12)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func timerStatItem(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
            Text(value)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getWeeklyCategoryData() -> [WeeklyCategoryData] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [WeeklyCategoryData] = []
        
        // Erstelle Daten für die letzten 7 Tage
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: date) - 1]
            
            let dateString = manager.dateString(from: date)
            let dayMinutes = category.dailyTimes[dateString] ?? 0
            let dayHours = Double(dayMinutes) / 60.0
            
            weeklyData.append(WeeklyCategoryData(
                weekday: weekday,
                hours: dayHours
            ))
        }
        
        return weeklyData.reversed() // Ältester zuerst
    }
    
    private func parseDateString(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: dateString)
    }
}

struct WeeklyCategoryData: Identifiable {
    let id = UUID()
    let weekday: String
    let hours: Double
}

struct CategoryWeeklyChartView: View {
    let weeklyData: [WeeklyCategoryData]
    
    var body: some View {
        Chart(weeklyData) { data in
            BarMark(
                x: .value("Day", String(data.weekday.prefix(3))),
                y: .value("Hours", data.hours)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .cornerRadius(4)
        }
        .chartYScale(domain: 0...max(8, weeklyData.map { $0.hours }.max() ?? 0))
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                    .foregroundStyle(Color.white.opacity(0.2))
                AxisValueLabel {
                    if let hours = value.as(Double.self) {
                        Text("\(Int(hours))h")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let day = value.as(String.self) {
                        Text(day)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
    }
}

// MARK: - WorkAddCategorySheet (unverändert)

struct WorkAddCategorySheet: View {
    @Binding var categoryName: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
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
                
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("New Work Category")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Create a new category to organize your work sessions")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    
                    TextField("Category Name", text: $categoryName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Button("Create Category") {
                            onSave()
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: categoryName.isEmpty ? [Color.gray, Color.gray] : [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: categoryName.isEmpty ? .clear : .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 20)
                        .disabled(categoryName.isEmpty)
                        
                        Button("Cancel") {
                            onCancel()
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}

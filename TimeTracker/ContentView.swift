import SwiftUI
import UserNotifications
import Combine

// MARK: - Models
struct CategoryItem: Codable, Identifiable {
    var id: String
    var name: String
    var total: Double = 0
    var today: Double = 0
    var week: Double = 0
    var lastDate: String = ""
    var lastWeek: String = ""
    var isRunning: Bool = false
    var startTime: Date?
    var dailyTimes: [String: Double] = [:]
    
    enum CodingKeys: String, CodingKey {
        case id, name, total, today, week, lastDate, lastWeek, dailyTimes
    }
}

struct SleepSession: Codable, Identifiable {
    var id: String = UUID().uuidString
    var startTime: Date
    var endTime: Date
}

struct SleepData: Codable {
    var isSleeping: Bool = false
    var sleepStartTime: Date?
    var alarmTime: Date?
    var totalSleepToday: Double = 0
    var lastDate: String = ""
    var sleepSessions: [SleepSession] = []
}

struct TrackerData: Codable {
    var workCategories: [CategoryItem] = []
    var sportsCategories: [CategoryItem] = []
    var sleepData: SleepData = SleepData()
    var gymDays: [Int] = []
    var lastWorkNotification: Date?
}

// MARK: - Data Manager
class TimeTrackerManager: ObservableObject {
    @Published var data: TrackerData
    @Published var showingPositiveMessage = false
    @Published var positiveMessage = ""
    @Published var activeCategory: String? = nil
    
    private var timer: Timer?
    private var workNotificationTimer: Timer?
    private let userDefaults = UserDefaults.standard
    private let dataKey = "timeTrackerDataV3"
    
    init() {
        self.data = TimeTrackerManager.loadData()
        checkDateReset()
        startTimer()
        startWorkNotificationTimer()
        requestNotificationPermission()
    }
    
    static func loadData() -> TrackerData {
        guard let data = UserDefaults.standard.data(forKey: "timeTrackerDataV3"),
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
    
    func checkDateReset() {
        let today = dateString(from: Date())
        let currentWeek = weekString(from: Date())
        
        for i in 0..<data.workCategories.count {
            if data.workCategories[i].lastDate != today {
                data.workCategories[i].today = 0
                data.workCategories[i].lastDate = today
            }
            if data.workCategories[i].lastWeek != currentWeek {
                data.workCategories[i].week = 0
                data.workCategories[i].lastWeek = currentWeek
            }
        }
        
        for i in 0..<data.sportsCategories.count {
            if data.sportsCategories[i].lastDate != today {
                data.sportsCategories[i].today = 0
                data.sportsCategories[i].lastDate = today
            }
            if data.sportsCategories[i].lastWeek != currentWeek {
                data.sportsCategories[i].week = 0
                data.sportsCategories[i].lastWeek = currentWeek
            }
        }
        
        if data.sleepData.lastDate != today {
            data.sleepData.totalSleepToday = 0
            data.sleepData.lastDate = today
        }
        
        saveData()
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
    
    func toggleTimer(id: String, type: String) {
        if type == "work" {
            if let index = data.workCategories.firstIndex(where: { $0.id == id }) {
                if data.workCategories[index].isRunning {
                    stopTimer(index: index, type: "work")
                    activeCategory = nil
                } else {
                    startTimer(index: index, type: "work")
                    activeCategory = id
                }
            }
        } else {
            if let index = data.sportsCategories.firstIndex(where: { $0.id == id }) {
                if data.sportsCategories[index].isRunning {
                    stopTimer(index: index, type: "sports")
                } else {
                    startTimer(index: index, type: "sports")
                }
            }
        }
    }
    
    func stopAllTimers() {
        for i in 0..<data.workCategories.count {
            if data.workCategories[i].isRunning {
                stopTimer(index: i, type: "work")
            }
        }
        for i in 0..<data.sportsCategories.count {
            if data.sportsCategories[i].isRunning {
                stopTimer(index: i, type: "sports")
            }
        }
        activeCategory = nil
    }
    
    private func startTimer(index: Int, type: String) {
        if type == "work" {
            data.workCategories[index].isRunning = true
            data.workCategories[index].startTime = Date()
        } else {
            data.sportsCategories[index].isRunning = true
            data.sportsCategories[index].startTime = Date()
        }
        saveData()
    }
    
    private func stopTimer(index: Int, type: String) {
        if type == "work" {
            if let startTime = data.workCategories[index].startTime {
                let elapsed = Date().timeIntervalSince(startTime) / 60
                data.workCategories[index].today += elapsed
                data.workCategories[index].week += elapsed
                data.workCategories[index].total += elapsed
                
                let dayKey = dateString(from: Date())
                data.workCategories[index].dailyTimes[dayKey, default: 0] += elapsed
                
                data.workCategories[index].isRunning = false
                data.workCategories[index].startTime = nil
            }
        } else {
            if let startTime = data.sportsCategories[index].startTime {
                let elapsed = Date().timeIntervalSince(startTime) / 60
                data.sportsCategories[index].today += elapsed
                data.sportsCategories[index].week += elapsed
                data.sportsCategories[index].total += elapsed
                
                let dayKey = dateString(from: Date())
                data.sportsCategories[index].dailyTimes[dayKey, default: 0] += elapsed
                
                data.sportsCategories[index].isRunning = false
                data.sportsCategories[index].startTime = nil
            }
        }
        saveData()
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
    
    func getWeeklyStats(id: String, type: String) -> [Double] {
        let category = type == "work"
            ? data.workCategories.first(where: { $0.id == id })
            : data.sportsCategories.first(where: { $0.id == id })
        
        guard let cat = category else { return Array(repeating: 0, count: 7) }
        
        var stats: [Double] = []
        let calendar = Calendar.current
        let today = Date()
        
        for i in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let dayKey = dateString(from: date)
            stats.append(cat.dailyTimes[dayKey] ?? 0)
        }
        
        return stats
    }
    
    // MARK: - Sleep Functions
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
        
        if hour < 22 {
            positiveMessage = "🌙 Great choice! Going to bed early is excellent for your health!"
            showingPositiveMessage = true
        }
        
        if let alarm = alarmTime {
            scheduleAlarm(for: alarm)
        }
        
        saveData()
    }
    
    private func wakeUp() {
        guard let sleepStart = data.sleepData.sleepStartTime else { return }
        
        let now = Date()
        let sleepDuration = now.timeIntervalSince(sleepStart) / 3600
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        
        let session = SleepSession(startTime: sleepStart, endTime: now)
        data.sleepData.sleepSessions.append(session)
        
        if data.sleepData.sleepSessions.count > 14 {
            data.sleepData.sleepSessions.removeFirst()
        }
        
        data.sleepData.totalSleepToday += sleepDuration * 60
        
        if hour < 7 && sleepDuration >= 8 {
            positiveMessage = "☀️ Wonderful! You woke up early after a full night's sleep. You're crushing it!"
            showingPositiveMessage = true
        }
        
        data.sleepData.isSleeping = false
        data.sleepData.sleepStartTime = nil
        data.sleepData.alarmTime = nil
        
        cancelAlarm()
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
        scheduleGymNotification(hour: 8, minute: 0, day: day, title: "🏋️ Gym Time!")
        scheduleGymNotification(hour: 18, minute: 0, day: day, title: "💪 Evening Gym Session")
    }
    
    private func scheduleGymNotification(hour: Int, minute: Int, day: Int, title: String) {
        var components = DateComponents()
        components.weekday = day
        components.hour = hour
        components.minute = minute
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "Time to hit the gym!"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "gym_\(day)_\(hour)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling gym notification: \(error)")
            }
        }
    }
    
    private func cancelGymNotifications(for day: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["gym_\(day)_8", "gym_\(day)_18"])
    }
    
    private func startWorkNotificationTimer() {
        workNotificationTimer = Timer.scheduledTimer(withTimeInterval: 7200, repeats: true) { [weak self] _ in
            self?.checkAndSendWorkNotification()
        }
    }
    
    private func checkAndSendWorkNotification() {
        let hasActiveWork = data.workCategories.contains { $0.isRunning }
        
        if !hasActiveWork {
            let content = UNMutableNotificationContent()
            content.title = "💪 Push-up Time!"
            content.body = "You haven't worked in 2 hours. Time to get productive!"
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: "work_reminder", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling work notification: \(error)")
                }
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }
    
    private func scheduleAlarm(for time: Date) {
        cancelAlarm()
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ Wake Up!"
        content.body = "Time to start your day!"
        content.sound = .defaultCritical
        content.categoryIdentifier = "ALARM"
        
        var targetDate = time
        let calendar = Calendar.current
        let now = Date()
        
        if time <= now {
            targetDate = calendar.date(byAdding: .day, value: 1, to: time)!
        }
        
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: targetDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: "sleepAlarm", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling alarm: \(error)")
            }
        }
    }
    
    private func cancelAlarm() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["sleepAlarm"])
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
    
    func cleanup() {
        for i in 0..<data.workCategories.count {
            if data.workCategories[i].isRunning {
                stopTimer(index: i, type: "work")
            }
        }
        for i in 0..<data.sportsCategories.count {
            if data.sportsCategories[i].isRunning {
                stopTimer(index: i, type: "sports")
            }
        }
        timer?.invalidate()
        workNotificationTimer?.invalidate()
    }
    
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func weekString(from date: Date) -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let week = calendar.component(.weekOfYear, from: date)
        return "\(year)-W\(String(format: "%02d", week))"
    }
}

// MARK: - Main View
struct ContentView: View {
    @StateObject private var manager = TimeTrackerManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WorkView(manager: manager)
                .tabItem {
                    Label("Work", systemImage: "briefcase.fill")
                }
                .tag(0)
                .onDisappear {
                    if manager.activeCategory != nil {
                        manager.stopAllTimers()
                    }
                }
            
            SportsView(manager: manager)
                .tabItem {
                    Label("Sports", systemImage: "figure.run")
                }
                .tag(1)
                .onDisappear {
                    manager.stopAllTimers()
                }
            
            GymView(manager: manager)
                .tabItem {
                    Label("Gym", systemImage: "dumbbell.fill")
                }
                .tag(2)
            
            SleepView(manager: manager)
                .tabItem {
                    Label("Sleep", systemImage: "bed.double.fill")
                }
                .tag(3)
                .onDisappear {
                    if manager.data.sleepData.isSleeping {
                        manager.toggleSleepMode(alarmTime: nil)
                    }
                }
        }
        .onChange(of: selectedTab) {
            if selectedTab != 3 {
                if manager.data.sleepData.isSleeping {
                    manager.toggleSleepMode(alarmTime: nil)
                }
            }
        }
        .accentColor(.blue)
        .alert("Positive Message", isPresented: $manager.showingPositiveMessage) {
            Button("Thanks!") { }
        } message: {
            Text(manager.positiveMessage)
        }
        .onDisappear {
            manager.cleanup()
            if manager.data.sleepData.isSleeping {
                manager.toggleSleepMode(alarmTime: nil)
            }
        }
    }
}

// MARK: - Work View
struct WorkView: View {
    @ObservedObject var manager: TimeTrackerManager
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var expandedCategories: Set<String> = []
    
    var body: some View {
        ZStack {
            Color(red: 0.17, green: 0.17, blue: 0.17)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 15) {
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
                            }
                        )
                    }
                }
                .padding()
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingAddCategory = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(30)
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategorySheet(
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

// MARK: - Work Category Card
struct WorkCategoryCard: View {
    let category: CategoryItem
    let isExpanded: Bool
    @ObservedObject var manager: TimeTrackerManager
    let onToggleExpand: () -> Void
    @State private var showingDeleteAlert = false
    
    var times: (today: Double, week: Double, total: Double) {
        manager.getCurrentTime(id: category.id, type: "work")
    }
    
    var weeklyStats: [Double] {
        manager.getWeeklyStats(id: category.id, type: "work")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggleExpand) {
                HStack {
                    Text(category.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(Color(white: 0.25))
            }
            
            if isExpanded {
                VStack(spacing: 20) {
                    Button(action: {
                        manager.toggleTimer(id: category.id, type: "work")
                    }) {
                        Text(category.isRunning ? "STOP" : "START")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 180, height: 70)
                            .background(category.isRunning ? Color.red : Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 10) {
                        TimeRow(label: "Today:", time: times.today)
                        TimeRow(label: "This Week:", time: times.week)
                        TimeRow(label: "Total:", time: times.total)
                    }
                    
                    WeeklyChart(weeklyStats: weeklyStats)
                        .frame(height: 200)
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Text("Delete Category")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    .padding(.bottom, 15)
                    .alert("Delete Category", isPresented: $showingDeleteAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Delete", role: .destructive) {
                            manager.deleteCategory(id: category.id, type: "work")
                        }
                    } message: {
                        Text("Are you sure you want to delete this category? All your data will be permanently lost.")
                    }
                }
                .background(Color(white: 0.22))
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(white: 0.3), lineWidth: 1)
        )
    }
}

// MARK: - Weekly Chart
struct WeeklyChart: View {
    let weeklyStats: [Double]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Weekly Overview")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 4) {
                        let maxValue = weeklyStats.max() ?? 1
                        let normalizedHeight = (weeklyStats[index] / max(maxValue, 1)) * 100
                        
                        Rectangle()
                            .fill(Color.blue.opacity(0.7))
                            .frame(height: CGFloat(normalizedHeight))
                            .cornerRadius(4)
                        
                        Text(dayInitial(index))
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
        }
        .padding()
        .background(Color(white: 0.22))
        .cornerRadius(8)
    }
    
    func dayInitial(_ index: Int) -> String {
        let days = ["M", "T", "W", "T", "F", "S", "S"]
        return days[index]
    }
}

// MARK: - Sports View
struct SportsView: View {
    @ObservedObject var manager: TimeTrackerManager
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var expandedCategories: Set<String> = []
    
    var body: some View {
        ZStack {
            Color(red: 0.17, green: 0.17, blue: 0.17)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(manager.data.sportsCategories) { category in
                        CategoryCard(
                            category: category,
                            isExpanded: expandedCategories.contains(category.id),
                            manager: manager,
                            type: "sports",
                            onToggleExpand: {
                                if expandedCategories.contains(category.id) {
                                    expandedCategories.remove(category.id)
                                } else {
                                    expandedCategories.insert(category.id)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingAddCategory = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.green)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(30)
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategorySheet(
                categoryName: $newCategoryName,
                onSave: {
                    if !newCategoryName.isEmpty {
                        manager.addCategory(name: newCategoryName, type: "sports")
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

// MARK: - Gym View
struct GymView: View {
    @ObservedObject var manager: TimeTrackerManager
    
    var body: some View {
        ZStack {
            Color(red: 0.17, green: 0.17, blue: 0.17)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("🏋️ Gym Schedule")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                VStack(spacing: 12) {
                    ForEach(1...7, id: \.self) { day in
                        GymDayToggle(
                            day: day,
                            isSelected: manager.data.gymDays.contains(day),
                            onToggle: {
                                manager.toggleGymDay(day)
                            }
                        )
                    }
                }
                .padding()
                
                Spacer()
            }
        }
    }
}

// MARK: - Gym Day Toggle
struct GymDayToggle: View {
    let day: Int
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .gray)
                    .font(.system(size: 24))
                
                Text(dayName(for: day))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(Color(white: 0.22))
            .cornerRadius(12)
        }
    }
    
    func dayName(for weekday: Int) -> String {
        let days = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return days[weekday]
    }
}

// MARK: - Sleep View
struct SleepView: View {
    @ObservedObject var manager: TimeTrackerManager
    @State private var showingTimePicker = false
    @State private var selectedAlarmTime = Date()
    
    var statistics: (avgDuration: Double, avgBedtime: Double, avgWakeTime: Double, bedtimeVariation: Double, wakeVariation: Double) {
        manager.getSleepStatistics()
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.17, green: 0.17, blue: 0.17)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    Text("💤 Sleep Tracker")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    if manager.data.sleepData.isSleeping {
                        VStack(spacing: 20) {
                            Text("Sleep Mode Active")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.7))
                            
                            if let alarmTime = manager.data.sleepData.alarmTime {
                                Text("Alarm: \(alarmTime, style: .time)")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            
                            if let sleepStart = manager.data.sleepData.sleepStartTime {
                                let duration = Date().timeIntervalSince(sleepStart) / 3600
                                Text(String(format: "%.1fh sleeping", duration))
                                    .font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    
                    Button(action: {
                        if manager.data.sleepData.isSleeping {
                            manager.toggleSleepMode(alarmTime: nil)
                        } else {
                            showingTimePicker = true
                        }
                    }) {
                        Text(manager.data.sleepData.isSleeping ? "TURN OFF SLEEP MODE" : "ACTIVATE SLEEP MODE")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 20)
                            .background(manager.data.sleepData.isSleeping ? Color.red : Color.purple)
                            .cornerRadius(15)
                    }
                    
                    VStack(spacing: 15) {
                        Text("Sleep Statistics")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        StatRow(label: "Average Sleep Duration", value: String(format: "%.1fh", statistics.avgDuration))
                        StatRow(label: "Average Bedtime", value: formatTime(statistics.avgBedtime))
                        StatRow(label: "Average Wake Time", value: formatTime(statistics.avgWakeTime))
                        StatRow(label: "Bedtime Variation", value: String(format: "±%.0f min", statistics.bedtimeVariation))
                        StatRow(label: "Wake Time Variation", value: String(format: "±%.0f min", statistics.wakeVariation))
                    }
                    .padding()
                    .background(Color(white: 0.22))
                    .cornerRadius(12)
                    
                    if !manager.data.sleepData.sleepSessions.isEmpty {
                        SleepChart(sessions: manager.data.sleepData.sleepSessions)
                            .frame(height: 300)
                            .padding()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingTimePicker) {
            VStack(spacing: 30) {
                Text("Set Alarm Time")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 40)
                
                DatePicker("Alarm Time", selection: $selectedAlarmTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .padding()
                
                Button("Set Alarm & Sleep") {
                    manager.toggleSleepMode(alarmTime: selectedAlarmTime)
                    showingTimePicker = false
                }
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 15)
                .background(Color.purple)
                .cornerRadius(12)
                
                Button("Cancel") {
                    showingTimePicker = false
                }
                .foregroundColor(.gray)
                .padding(.bottom, 40)
            }
            .presentationDetents([.medium])
        }
    }
    
    func formatTime(_ time: Double) -> String {
        let hour = Int(time)
        let minute = Int((time - Double(hour)) * 60)
        return String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - Sleep Chart
struct SleepChart: View {
    let sessions: [SleepSession]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                Color(white: 0.2)
                
                VStack(spacing: 0) {
                    ForEach(0..<25) { hour in
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: height / 24)
                            .overlay(
                                Rectangle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 1),
                                alignment: .bottom
                            )
                    }
                }
                
                HStack(spacing: 0) {
                    ForEach(1...7, id: \.self) { day in
                        VStack {
                            Spacer()
                            if let matchedSession = sessions.last(where: { s in
                                let calendar = Calendar.current
                                let sessionWeekday = calendar.component(.weekday, from: s.startTime)
                                return sessionWeekday == day
                            }) {
                                SleepBar(session: matchedSession, height: height)
                            }
                            Text(dayInitial(for: day))
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 5)
                        }
                        .frame(width: width / 7)
                    }
                }
                
                VStack {
                    ForEach([0, 6, 12, 18, 24], id: \.self) { hour in
                        HStack {
                            Text("\(hour):00")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.5))
                            Spacer()
                        }
                        .frame(height: height / 5)
                    }
                }
                .padding(.leading, 5)
            }
            .cornerRadius(12)
        }
    }
    
    func dayInitial(for weekday: Int) -> String {
        let days = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[weekday]
    }
}

struct SleepBar: View {
    let session: SleepSession
    let height: CGFloat
    
    var body: some View {
        let calendar = Calendar.current
        let startHour = Double(calendar.component(.hour, from: session.startTime))
        let startMinute = Double(calendar.component(.minute, from: session.startTime))
        let endHour = Double(calendar.component(.hour, from: session.endTime))
        let endMinute = Double(calendar.component(.minute, from: session.endTime))
        
        let startTime = startHour + startMinute / 60.0
        let endTime = endHour + endMinute / 60.0
        
        let barHeight = abs(endTime - startTime) / 24.0 * height
        let offset = (startTime / 24.0 * height) - (height / 2) + (barHeight / 2)
        
        Rectangle()
            .fill(Color.blue.opacity(0.7))
            .frame(width: 30, height: barHeight)
            .cornerRadius(4)
            .offset(y: offset)
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal)
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: CategoryItem
    let isExpanded: Bool
    @ObservedObject var manager: TimeTrackerManager
    let type: String
    let onToggleExpand: () -> Void
    @State private var showingDeleteAlert = false
    
    var times: (today: Double, week: Double, total: Double) {
        manager.getCurrentTime(id: category.id, type: type)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggleExpand) {
                HStack {
                    Text(category.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(Color(white: 0.25))
            }
            
            if isExpanded {
                VStack(spacing: 20) {
                    Button(action: {
                        manager.toggleTimer(id: category.id, type: type)
                    }) {
                        Text(category.isRunning ? "STOP" : "START")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 180, height: 70)
                            .background(category.isRunning ? Color.red : Color.green)
                            .cornerRadius(12)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 10) {
                        TimeRow(label: "Today:", time: times.today)
                        TimeRow(label: "This Week:", time: times.week)
                        TimeRow(label: "Total:", time: times.total)
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Text("Delete Category")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    .padding(.bottom, 15)
                    .alert("Delete Category", isPresented: $showingDeleteAlert) {
                        Button("Cancel", role: .cancel) { }
                        Button("Delete", role: .destructive) {
                            manager.deleteCategory(id: category.id, type: type)
                        }
                    } message: {
                        Text("Are you sure you want to delete this category? All your data will be permanently lost.")
                    }
                }
                .background(Color(white: 0.22))
            }
        }
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(white: 0.3), lineWidth: 1)
        )
    }
}

// MARK: - Add Category Sheet
struct AddCategorySheet: View {
    @Binding var categoryName: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Category Name", text: $categoryName)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .focused($isTextFieldFocused)
                
                Spacer()
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: onSave)
                        .disabled(categoryName.isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    isTextFieldFocused = true
                }
            }
        }
    }
}

// MARK: - Time Row
struct TimeRow: View {
    let label: String
    let time: Double
    
    var formattedTime: String {
        let hours = Int(time / 60)
        let minutes = Int(time.truncatingRemainder(dividingBy: 60))
        return "\(hours)h \(minutes)min"
    }
    
    var body: some View {
        HStack(spacing: 20) {
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(Color(white: 0.67))
                .frame(width: 100, alignment: .trailing)
            
            Text(formattedTime)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 100, alignment: .leading)
        }
    }
}

// MARK: - Previews
#Preview {
    ContentView()
}

// MARK: - App Entry Point
@main
struct TimeTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

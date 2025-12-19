import SwiftUI
import Charts
import UserNotifications

struct SleepView: View {
    @ObservedObject var manager: TimeTrackerManager
    @State private var showingTimePicker = false
    @State private var selectedAlarmTime = Date()
    @State private var showingStatistics = false
    @State private var showingWindDownConfig = false
    
    var body: some View {
        ZStack {
            // Dunklerer Gradient für bessere Nacht-Atmosphäre
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.10, green: 0.10, blue: 0.15),
                    Color(red: 0.05, green: 0.05, blue: 0.10)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header mit aktueller Systemzeit
                VStack(spacing: 8) {
                    Text("💤 Sleep Tracker")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("System Time: \(manager.formatSystemTime(manager.getCurrentSystemTime()))")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    
                    if manager.isSystemTimeWithinSleepHours() {
                        Text("🌙 Good night time")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.blue.opacity(0.2)))
                    }
                }
                .padding(.top, 40)
                
                // Sleep Status
                if manager.data.sleepData.isSleeping {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "moon.zzz.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.purple)
                                
                                Text("Sleeping")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        if let sleepStart = manager.data.sleepData.sleepStartTime {
                            let duration = Date().timeIntervalSince(sleepStart) / 3600
                            Text(String(format: "%.1f hours asleep", duration))
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        if let alarmTime = manager.data.sleepData.alarmTime {
                            VStack(spacing: 4) {
                                Text("Alarm Set For")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                                
                                Text("\(alarmTime, style: .time)")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                // Sleep Statistics Chart (immer sichtbar)
                VStack(spacing: 16) {
                    HStack {
                        Text("Weekly Sleep Overview")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Details") {
                            showingStatistics = true
                        }
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 20)
                    
                    // Wind-Down Configuration Button
                    Button(action: { showingWindDownConfig = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: manager.data.sleepData.windDownEnabled ? "moon.stars.fill" : "moon.stars")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(manager.data.sleepData.windDownEnabled ? .purple : .white.opacity(0.6))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Wind-Down Phase")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                if manager.data.sleepData.windDownEnabled,
                                   let remainingMinutes = manager.getWindDownRemainingTime() {
                                    Text("Starts in \(remainingMinutes) min")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.purple)
                                } else {
                                    Text("Not configured")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.3))
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.15, green: 0.15, blue: 0.20))
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    WeeklySleepChartView(manager: manager)
                        .frame(height: 200)
                        .padding(.horizontal, 16)
                }
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.20))
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                )
                .padding(.horizontal, 20)
                
                // Action Button
                Button(action: {
                    if manager.data.sleepData.isSleeping {
                        manager.toggleSleepMode(alarmTime: nil)
                    } else {
                        // Setze Standard-Alarm auf 7:00 morgens
                        let calendar = Calendar.current
                        var components = calendar.dateComponents([.year, .month, .day], from: Date())
                        components.hour = 7
                        components.minute = 0
                        selectedAlarmTime = calendar.date(from: components) ?? Date().addingTimeInterval(8 * 3600)
                        showingTimePicker = true
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: manager.data.sleepData.isSleeping ? "powersleep" : "moon.fill")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text(manager.data.sleepData.isSleeping ? "WAKE UP" : "START SLEEPING")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: manager.data.sleepData.isSleeping ?
                                [.orange, .red] :
                                [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: manager.data.sleepData.isSleeping ? .red.opacity(0.4) : .blue.opacity(0.4),
                           radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingTimePicker) {
            AlarmTimePickerView(
                alarmTime: $selectedAlarmTime,
                onSetAlarm: {
                    manager.toggleSleepMode(alarmTime: selectedAlarmTime)
                    showingTimePicker = false
                },
                onCancel: {
                    showingTimePicker = false
                }
            )
        }
        .sheet(isPresented: $showingStatistics) {
            SleepStatisticsView(manager: manager)
        }
        .sheet(isPresented: $showingWindDownConfig) {
            WindDownConfigView(manager: manager)
        }
    }
}

// Weekly Sleep Chart View mit Wochentagen auf X-Achse und Uhrzeit auf Y-Achse
struct WeeklySleepChartView: View {
    @ObservedObject var manager: TimeTrackerManager
    
    var weeklySleepData: [WeeklySleepData] {
        getWeeklySleepData()
    }
    
    var body: some View {
        ZStack {
            if weeklySleepData.isEmpty {
                // Platzhalter für leere Daten
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No sleep data yet")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Start tracking your sleep to see insights")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
            } else {
                Chart(weeklySleepData) { data in
                    if let sleepStart = data.sleepStart, let sleepEnd = data.sleepEnd {
                        // Zeige Schlafzeit als Bereich zwischen Start und Ende
                        RectangleMark(
                            x: .value("Day", data.weekday),
                            yStart: .value("Start Time", hoursFromMidnight(sleepStart)),
                            yEnd: .value("End Time", hoursFromMidnight(sleepEnd)),
                            width: .fixed(20)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(4)
                        
                        // Optional: Punkte für Start und Ende
                        PointMark(
                            x: .value("Day", data.weekday),
                            y: .value("Start Time", hoursFromMidnight(sleepStart))
                        )
                        .foregroundStyle(.green)
                        .symbolSize(40)
                        
                        PointMark(
                            x: .value("Day", data.weekday),
                            y: .value("End Time", hoursFromMidnight(sleepEnd))
                        )
                        .foregroundStyle(.orange)
                        .symbolSize(40)
                    }
                }
                .chartYScale(domain: 0...24) // 24 Stunden
                .chartYAxis {
                    AxisMarks(values: .stride(by: 3)) { value in
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.2))
                        AxisTick()
                            .foregroundStyle(Color.white.opacity(0.5))
                        AxisValueLabel {
                            if let hour = value.as(Int.self) {
                                Text(formatHour(hour))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine()
                            .foregroundStyle(Color.white.opacity(0.2))
                        AxisTick()
                            .foregroundStyle(Color.white.opacity(0.5))
                        AxisValueLabel {
                            if let weekday = value.as(String.self) {
                                Text(weekday.prefix(3))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func getWeeklySleepData() -> [WeeklySleepData] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [WeeklySleepData] = []
        
        // Erstelle Daten für die letzten 7 Tage
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            let weekday = calendar.weekdaySymbols[calendar.component(.weekday, from: date) - 1]
            
            // Finde Schlaf-Sessions für diesen Tag
            let daySessions = manager.data.sleepData.sleepSessions.filter { session in
                calendar.isDate(session.startTime, inSameDayAs: date)
            }
            
            if let firstSession = daySessions.first {
                weeklyData.append(WeeklySleepData(
                    weekday: weekday,
                    sleepStart: firstSession.startTime,
                    sleepEnd: firstSession.endTime
                ))
            } else {
                // Keine Daten für diesen Tag
                weeklyData.append(WeeklySleepData(weekday: weekday, sleepStart: nil, sleepEnd: nil))
            }
        }
        
        return weeklyData.reversed() // Ältester zuerst
    }
    
    private func hoursFromMidnight(_ date: Date) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60.0
    }
    
    private func formatHour(_ hour: Int) -> String {
        switch hour {
        case 0: return "12AM"
        case 12: return "12PM"
        case 13...23: return "\(hour-12)PM"
        default: return "\(hour)AM"
        }
    }
}

struct WeeklySleepData: Identifiable {
    let id = UUID()
    let weekday: String
    let sleepStart: Date?
    let sleepEnd: Date?
}

// Alarm Time Picker View mit System-Alarm-Integration
struct AlarmTimePickerView: View {
    @Binding var alarmTime: Date
    let onSetAlarm: () -> Void
    let onCancel: () -> Void
    @State private var notificationPermissionGranted = false
    
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
                        Image(systemName: "alarm.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Set Wake Up Alarm")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("The alarm will ring at the selected time using iOS notifications")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    
                    DatePicker("Alarm Time", selection: $alarmTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .padding()
                        .background(Color(red: 0.18, green: 0.18, blue: 0.22))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    
                    if !notificationPermissionGranted {
                        VStack(spacing: 8) {
                            Text("🔔 Notifications Required")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.orange)
                            
                            Text("Enable notifications to receive alarm alerts")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    VStack(spacing: 12) {
                        Button("Set System Alarm & Start Sleeping") {
                            requestNotificationPermission { granted in
                                if granted {
                                    scheduleAlarmNotification()
                                    onSetAlarm()
                                }
                            }
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                        
                        Button("Cancel") {
                            onCancel()
                        }
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
                .padding(.top, 40)
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
            .onAppear {
                checkNotificationPermission()
            }
        }
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                notificationPermissionGranted = granted
                completion(granted)
            }
        }
    }
    
    private func scheduleAlarmNotification() {
        let content = UNMutableNotificationContent()
        content.title = "⏰ Wake Up!"
        content.body = "Your sleep tracking alarm is ringing"
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "ALARM"
        
        let triggerDate = Calendar.current.dateComponents([.hour, .minute], from: alarmTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "sleepAlarm-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling alarm: \(error.localizedDescription)")
            } else {
                print("Alarm scheduled for \(alarmTime)")
            }
        }
    }
}

// Sleep Statistics Detail View (bleibt unverändert)
struct SleepStatisticsView: View {
    @ObservedObject var manager: TimeTrackerManager
    @Environment(\.dismiss) var dismiss
    
    var statistics: SleepStatistics {
        manager.getEnhancedSleepStatistics()
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Consistency Score
                        VStack(spacing: 16) {
                            Text("Sleep Consistency")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 10)
                                    .frame(width: 120, height: 120)
                                
                                Circle()
                                    .trim(from: 0, to: CGFloat(statistics.consistencyScore / 100))
                                    .stroke(
                                        LinearGradient(
                                            colors: [.green, .blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                    )
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(-90))
                                
                                VStack(spacing: 4) {
                                    Text("\(Int(statistics.consistencyScore))")
                                        .font(.system(size: 24, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    
                                    Text("Score")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding()
                        .background(Color(red: 0.15, green: 0.15, blue: 0.20))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                        
                        // Detailed Statistics
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            SleepStatCard(title: "Avg Duration", value: String(format: "%.1fh", statistics.avgDuration), color: .purple)
                            SleepStatCard(title: "Avg Bedtime", value: formatTime(hours: statistics.avgBedtime), color: .purple)
                            SleepStatCard(title: "Avg Wake Time", value: formatTime(hours: statistics.avgWakeTime), color: .green)
                            SleepStatCard(title: "Consistency", value: "\(Int(statistics.consistencyScore))%", color: .orange)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Sleep Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatTime(hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        let hour = totalMinutes / 60
        let minute = totalMinutes % 60
        return String(format: "%02d:%02d", hour, minute)
    }
}

struct SleepStatCard: View {
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
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(red: 0.15, green: 0.15, blue: 0.20))
        .cornerRadius(12)
    }
}

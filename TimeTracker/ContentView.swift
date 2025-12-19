import SwiftUI

struct ContentView: View {
    @StateObject private var manager = TimeTrackerManager()
    @State private var selectedTab = 0
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WorkView(manager: manager)
                .tabItem {
                    Label("Work", systemImage: "briefcase.fill")
                }
                .tag(0)
            
            GymView(manager: manager)
                .tabItem {
                    Label("Gym", systemImage: "dumbbell.fill")
                }
                .tag(1)
            
            SleepView(manager: manager)
                .tabItem {
                    Label("Sleep", systemImage: "bed.double.fill")
                }
                .tag(2)
            
            SocialView(manager: manager)
                .tabItem {
                    Label("Social", systemImage: "person.2.fill")
                }
                .tag(3)
            
            HabitsView(manager: manager)
                .tabItem {
                    Label("Habits", systemImage: "checkmark.circle.fill")
                }
                .tag(4)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue != 2 && manager.data.sleepData.isSleeping {
                manager.toggleSleepMode(alarmTime: nil)
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            manager.updateScenePhase(newPhase)
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

//
//  SleepView.swift
//  TimeTracker
//
//  Created by Thomas Bürger on 17.10.25.
//

import SwiftUI

struct SleepView: View {
    @ObservedObject var manager: TimeTrackerManager
    @State private var showingTimePicker = false
    @State private var selectedAlarmTime = Date()
    
    var body: some View {
        ZStack {
            Color(red: 0.17, green: 0.17, blue: 0.17)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Text("💤 Sleep Tracker")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 60)
                
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
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 20)
                        .background(manager.data.sleepData.isSleeping ? Color.red : Color.purple)
                        .cornerRadius(15)
                }
                
                Spacer()
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
}

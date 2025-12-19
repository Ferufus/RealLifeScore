//
//  WindDownConfigView.swift
//  TimeTracker
//
//  Created by Thomas Bürger on 18.12.25.
//

import SwiftUI

struct WindDownConfigView: View {
    @ObservedObject var manager: TimeTrackerManager
    @Environment(\.dismiss) var dismiss
    
    @State private var windDownTime = Date()
    @State private var windDownDuration: Int = 30
    
    let durationOptions = [15, 30, 45, 60, 90, 120]
    
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
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple.opacity(0.3), .blue.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "moon.stars.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            Text("Wind-Down Phase")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Prepare your body and mind for quality sleep with a consistent evening routine")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 20)
                        
                        // Benefits Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Why Wind-Down?")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            BenefitRow(
                                icon: "brain.head.profile",
                                text: "Signals your brain it's time to sleep",
                                color: .purple
                            )
                            
                            BenefitRow(
                                icon: "clock.arrow.circlepath",
                                text: "Improves sleep onset by 15-20 minutes",
                                color: .blue
                            )
                            
                            BenefitRow(
                                icon: "heart.fill",
                                text: "Reduces stress and anxiety",
                                color: .pink
                            )
                            
                            BenefitRow(
                                icon: "moon.zzz.fill",
                                text: "Enhances overall sleep quality",
                                color: .indigo
                            )
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.15, green: 0.15, blue: 0.20))
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal, 20)
                        
                        // Configuration
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Schedule Your Wind-Down")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            // Time Picker
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Start Time")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                DatePicker("", selection: $windDownTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(.wheel)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .padding()
                                    .background(Color(red: 0.18, green: 0.18, blue: 0.22))
                                    .cornerRadius(12)
                            }
                            
                            // Duration Picker
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Duration")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(durationOptions, id: \.self) { duration in
                                            DurationChip(
                                                duration: duration,
                                                isSelected: windDownDuration == duration
                                            ) {
                                                windDownDuration = duration
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Calculated Bedtime
                            VStack(spacing: 8) {
                                Text("Suggested Bedtime")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text(calculateBedtime())
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.18, green: 0.18, blue: 0.22))
                            .cornerRadius(12)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(red: 0.15, green: 0.15, blue: 0.20))
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal, 20)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            if manager.data.sleepData.windDownEnabled {
                                Button(action: {
                                    manager.cancelWindDown()
                                    dismiss()
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                        Text("Disable Wind-Down")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [.red, .red.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: .red.opacity(0.4), radius: 8, x: 0, y: 4)
                                }
                            }
                            
                            Button(action: {
                                manager.scheduleWindDown(time: windDownTime, duration: windDownDuration)
                                dismiss()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                    Text(manager.data.sleepData.windDownEnabled ? "Update Wind-Down" : "Enable Wind-Down")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                }
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
                                .cornerRadius(16)
                                .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .onAppear {
                if let scheduledTime = manager.data.sleepData.windDownScheduledTime {
                    windDownTime = scheduledTime
                }
                windDownDuration = manager.data.sleepData.windDownDuration
            }
        }
    }
    
    private func calculateBedtime() -> String {
        let calendar = Calendar.current
        let bedtime = calendar.date(byAdding: .minute, value: windDownDuration, to: windDownTime)!
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: bedtime)
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
}

struct DurationChip: View {
    let duration: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(duration)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                
                Text("min")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .white.opacity(0.4))
            }
            .frame(width: 70, height: 70)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ?
                        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [Color(red: 0.2, green: 0.2, blue: 0.2), Color(red: 0.2, green: 0.2, blue: 0.2)], startPoint: .top, endPoint: .bottom)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
        }
    }
}

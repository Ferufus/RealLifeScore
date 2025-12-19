//
//  ScheduleCallView.swift
//  TimeTracker
//
//  Created by Thomas Bürger on 18.12.25.
//

import SwiftUI

struct ScheduleCallView: View {
    @ObservedObject var manager: TimeTrackerManager
    let contact: ContactProfile
    @Binding var isPresented: Bool
    
    @State private var callTime = Date()
    @State private var note = ""
    @FocusState private var isFocused: Bool
    
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
                        Image(systemName: "phone.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        
                        Text("Schedule Call")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("with \(contact.name)")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        // Date & Time Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Date & Time")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            
                            DatePicker("", selection: $callTime, in: Date()...)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .colorScheme(.dark)
                                .padding()
                                .background(Color(red: 0.18, green: 0.18, blue: 0.22))
                                .cornerRadius(12)
                        }
                        
                        // Note Field
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Note (Optional)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextEditor(text: $note)
                                .frame(height: 100)
                                .padding(12)
                                .background(Color(red: 0.18, green: 0.18, blue: 0.22))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .font(.system(size: 15, design: .rounded))
                                .scrollContentBackground(.hidden)
                                .focused($isFocused)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Schedule Button
                    Button(action: scheduleCall) {
                        HStack(spacing: 10) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 18))
                            Text("Schedule Call")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
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
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isFocused = false
                        }
                    }
                }
            }
        }
    }
    
    private func scheduleCall() {
        manager.scheduleCall(contactId: contact.id, time: callTime, note: note)
        isPresented = false
    }
}

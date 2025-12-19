//
//  ContactDetailView.swift
//  TimeTracker
//
//  Created by Thomas Bürger on 18.12.25.
//

import SwiftUI

struct ContactDetailView: View {
    @ObservedObject var manager: TimeTrackerManager
    @State var contact: ContactProfile
    @Environment(\.dismiss) var dismiss
    
    @State private var isEditing = false
    @State private var showingScheduleCall = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
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
                    contactHeader
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Profile Information
                    profileSection
                    
                    // Scheduled Calls
                    scheduledCallsSection
                    
                    // Delete Button
                    deleteButton
                    
                    Spacer(minLength: 40)
                }
                .padding(.vertical, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        manager.updateContact(contact)
                    }
                    isEditing.toggle()
                }
                .foregroundColor(.blue)
            }
        }
        .sheet(isPresented: $showingScheduleCall) {
            ScheduleCallView(
                manager: manager,
                contact: contact,
                isPresented: $showingScheduleCall
            )
        }
        .alert("Delete Contact", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                manager.deleteContact(id: contact.id)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete \(contact.name)? This will also cancel all scheduled calls.")
        }
    }
    
    // MARK: - View Components
    
    private var contactHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [getClassColor(contact.contactClass).opacity(0.3), getClassColor(contact.contactClass).opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: contact.contactClass.icon)
                    .font(.system(size: 40))
                    .foregroundColor(getClassColor(contact.contactClass))
            }
            
            Text(contact.name)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Contact Class Picker
            if isEditing {
                Picker("Class", selection: $contact.contactClass) {
                    ForEach(ContactClass.allCases, id: \.self) { contactClass in
                        Text(contactClass.rawValue).tag(contactClass)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.2))
                )
            } else {
                HStack(spacing: 8) {
                    Image(systemName: contact.contactClass.icon)
                        .font(.system(size: 14))
                    Text(contact.contactClass.rawValue)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundColor(getClassColor(contact.contactClass))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(getClassColor(contact.contactClass).opacity(0.2))
                )
            }
            
            if let phoneNumber = contact.phoneNumber {
                Text(phoneNumber)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            if let lastContact = contact.lastContact {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text("Last contact: \(formatDate(lastContact))")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            if let phoneNumber = contact.phoneNumber {
                QuickActionButton(
                    icon: "phone.fill",
                    title: "Call",
                    color: .green
                ) {
                    if let url = URL(string: "tel://\(phoneNumber.filter { $0.isNumber })") {
                        UIApplication.shared.open(url)
                    }
                }
            }
            
            QuickActionButton(
                icon: "calendar.badge.plus",
                title: "Schedule",
                color: .blue
            ) {
                showingScheduleCall = true
            }
            
            QuickActionButton(
                icon: "checkmark.circle",
                title: "Contacted",
                color: .purple
            ) {
                contact.lastContact = Date()
                manager.updateContact(contact)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var profileSection: some View {
        VStack(spacing: 16) {
            ProfileField(
                title: "Current News",
                icon: "newspaper.fill",
                text: $contact.currentNews,
                placeholder: "What's new in their life?",
                isEditing: isEditing
            )
            
            ProfileField(
                title: "Preferences",
                icon: "heart.fill",
                text: $contact.preferences,
                placeholder: "Favorite food, drinks, activities...",
                isEditing: isEditing
            )
            
            ProfileField(
                title: "Interests & Hobbies",
                icon: "star.fill",
                text: $contact.interests,
                placeholder: "Sports, pets, hobbies...",
                isEditing: isEditing
            )
            
            ProfileField(
                title: "Additional Notes",
                icon: "note.text",
                text: $contact.notes,
                placeholder: "Any other important details...",
                isEditing: isEditing
            )
        }
        .padding(.horizontal, 20)
    }
    
    private var scheduledCallsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("📅 Scheduled Calls")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Spacer()
                
                if !contact.scheduledCalls.isEmpty {
                    Text("\(contact.scheduledCalls.filter { !$0.completed }.count)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                }
            }
            
            if contact.scheduledCalls.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No scheduled calls")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Button("Schedule a call") {
                        showingScheduleCall = true
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 12) {
                    ForEach(contact.scheduledCalls.sorted(by: { $0.scheduledTime < $1.scheduledTime })) { call in
                        ScheduledCallRow(
                            call: call,
                            contact: contact,
                            manager: manager
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
    
    private var deleteButton: some View {
        Button(action: { showingDeleteAlert = true }) {
            HStack {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16))
                Text("Delete Contact")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
            }
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
    
    // MARK: - Helper Functions
    
    private func getClassColor(_ contactClass: ContactClass) -> Color {
        switch contactClass {
        case .friends: return .blue
        case .closeFriends: return .pink
        case .family: return .green
        case .closeFamily: return .purple
        case .colleagues: return .orange
        case .other: return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "today"
        } else if calendar.isDateInYesterday(date) {
            return "yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
            if days < 7 {
                return "\(days) days ago"
            } else if days < 30 {
                return "\(days / 7) weeks ago"
            } else {
                return "\(days / 30) months ago"
            }
        }
    }
}

// MARK: - Supporting Views

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.20))
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
            )
        }
    }
}

struct ProfileField: View {
    let title: String
    let icon: String
    @Binding var text: String
    let placeholder: String
    let isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            if isEditing {
                TextEditor(text: $text)
                    .frame(minHeight: 80)
                    .padding(12)
                    .background(Color(red: 0.18, green: 0.18, blue: 0.22))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .font(.system(size: 15, design: .rounded))
                    .scrollContentBackground(.hidden)
            } else {
                Text(text.isEmpty ? placeholder : text)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(text.isEmpty ? .white.opacity(0.4) : .white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(red: 0.18, green: 0.18, blue: 0.22))
                    .cornerRadius(12)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.20))
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
        )
    }
}

struct ScheduledCallRow: View {
    let call: ScheduledCall
    let contact: ContactProfile
    @ObservedObject var manager: TimeTrackerManager
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: call.completed ? "checkmark.circle.fill" : "calendar")
                        .font(.system(size: 14))
                        .foregroundColor(call.completed ? .green : .blue)
                    
                    Text(formatCallTime())
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                if !call.note.isEmpty {
                    Text(call.note)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            if !call.completed {
                Menu {
                    Button(action: {
                        manager.completeCall(contactId: contact.id, callId: call.id)
                    }) {
                        Label("Mark Complete", systemImage: "checkmark.circle")
                    }
                    
                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(call.completed ? Color.green.opacity(0.1) : Color(red: 0.18, green: 0.18, blue: 0.22))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(call.completed ? Color.green.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
        )
        .alert("Delete Call", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                manager.deleteScheduledCall(contactId: contact.id, callId: call.id)
            }
        } message: {
            Text("Are you sure you want to delete this scheduled call?")
        }
    }
    
    private func formatCallTime() -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(call.scheduledTime) {
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: call.scheduledTime))"
        } else if calendar.isDateInTomorrow(call.scheduledTime) {
            formatter.timeStyle = .short
            return "Tomorrow at \(formatter.string(from: call.scheduledTime))"
        } else {
            formatter.dateFormat = "MMM d 'at' h:mm a"
            return formatter.string(from: call.scheduledTime)
        }
    }
}

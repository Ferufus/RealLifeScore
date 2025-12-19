//
//  SocialView.swift
//  TimeTracker
//
//  Created by Thomas Bürger on 18.12.25.
//

import SwiftUI
import Contacts

struct SocialView: View {
    @ObservedObject var manager: TimeTrackerManager
    @State private var selectedFilter: ContactClass? = nil
    @State private var showingAddContact = false
    @State private var showingContactImport = false
    @State private var searchText = ""
    
    var filteredContacts: [ContactProfile] {
        let filtered = selectedFilter == nil ?
        manager.data.contacts :
        manager.data.contacts.filter { $0.contactClass == selectedFilter }
        
        if searchText.isEmpty {
            return filtered.sorted { $0.name < $1.name }
        } else {
            return filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
                .sorted { $0.name < $1.name }
        }
    }
    
    var upcomingCalls: [(contact: ContactProfile, call: ScheduledCall)] {
        manager.getUpcomingCalls()
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
                        statsSection
                        
                        // Upcoming Calls
                        if !upcomingCalls.isEmpty {
                            upcomingCallsSection
                        }
                        
                        // Class Filter
                        classFilterSection
                        
                        // Contacts List
                        contactsListSection
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.vertical, 20)
                }
                
                // Floating Add Button
                floatingButtons
            }
            .navigationTitle("Social")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search contacts")
            .sheet(isPresented: $showingAddContact) {
                AddContactView(manager: manager, isPresented: $showingAddContact)
            }
            .sheet(isPresented: $showingContactImport) {
                ContactImportView(manager: manager, isPresented: $showingContactImport)
            }
        }
    }
    
    // MARK: - View Components
    
    private var statsSection: some View {
        HStack(spacing: 12) {
            StatBubble(
                title: "Total",
                value: "\(manager.data.contacts.count)",
                icon: "person.3.fill",
                color: .blue
            )
            
            StatBubble(
                title: "This Week",
                value: "\(contactsThisWeek)",
                icon: "calendar",
                color: .purple
            )
        }
        .padding(.horizontal, 20)
    }
    
    private var upcomingCallsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📞 Upcoming Calls")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(upcomingCalls.prefix(5)), id: \.call.id) { contact, call in
                        UpcomingCallCard(contact: contact, call: call, manager: manager)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var classFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All",
                    count: manager.data.contacts.count,
                    isSelected: selectedFilter == nil
                ) {
                    selectedFilter = nil
                }
                
                ForEach(ContactClass.allCases, id: \.self) { contactClass in
                    let count = manager.data.contacts.filter { $0.contactClass == contactClass }.count
                    if count > 0 {
                        FilterChip(
                            title: contactClass.rawValue,
                            count: count,
                            isSelected: selectedFilter == contactClass,
                            icon: contactClass.icon
                        ) {
                            selectedFilter = contactClass
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var contactsListSection: some View {
        VStack(spacing: 12) {
            if filteredContacts.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredContacts) { contact in
                    NavigationLink(destination: ContactDetailView(manager: manager, contact: contact)) {
                        ContactRowView(contact: contact)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text(searchText.isEmpty ? "No Contacts" : "No Results")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(searchText.isEmpty ?
                 "Add contacts to track your relationships" :
                    "Try a different search term"
            )
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.white.opacity(0.6))
            .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
    }
    
    private var floatingButtons: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // Import Button
                    Button(action: { showingContactImport = true }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Add Button
                    Button(action: { showingAddContact = true }) {
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
                }
                .padding(20)
            }
        }
    }
    
    private var contactsThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return manager.data.contacts.filter { contact in
            if let lastContact = contact.lastContact {
                return lastContact > weekAgo
            }
            return false
        }.count
    }
}
    
    
// MARK: - Supporting Views
struct StatBubble: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
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
struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    var icon: String? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                }
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                
                Text("\(count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .white.opacity(0.5))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.white.opacity(isSelected ? 0.2 : 0.1)))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ?
                          LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color(red: 0.2, green: 0.2, blue: 0.2), Color(red: 0.2, green: 0.2, blue: 0.2)], startPoint: .top, endPoint: .bottom)
                         )
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.blue : Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
        }
    }
}
struct ContactRowView: View {
    let contact: ContactProfile
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(getClassColor(contact.contactClass).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: contact.contactClass.icon)
                    .font(.system(size: 20))
                    .foregroundColor(getClassColor(contact.contactClass))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(contact.contactClass.rawValue)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(getClassColor(contact.contactClass))
                    
                    if let lastContact = contact.lastContact {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 3, height: 3)
                        
                        Text(timeAgo(from: lastContact))
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }
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
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let days = Int(interval / 86400)
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days)d ago"
        } else if days < 30 {
            return "\(days / 7)w ago"
        } else {
            return "\(days / 30)mo ago"
        }
    }
}
struct UpcomingCallCard: View {
    let contact: ContactProfile
    let call: ScheduledCall
    @ObservedObject var manager: TimeTrackerManager
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(formatCallTime())
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
            
            if !call.note.isEmpty {
                Text(call.note)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
            
            Button(action: {
                manager.completeCall(contactId: contact.id, callId: call.id)
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                    Text("Mark Complete")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
            }
        }
        .padding(16)
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.20))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
    }
    
    private func formatCallTime() -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(call.scheduledTime) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: call.scheduledTime))"
        } else if calendar.isDateInTomorrow(call.scheduledTime) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "Tomorrow at \(formatter.string(from: call.scheduledTime))"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, h:mm a"
            return formatter.string(from: call.scheduledTime)
        }
    }
}

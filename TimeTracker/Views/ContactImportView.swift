//
//  ContactImportView.swift
//  TimeTracker
//
//  Created by Thomas Bürger on 18.12.25.
//

import SwiftUI
import Contacts

struct ContactImportView: View {
    @ObservedObject var manager: TimeTrackerManager
    @Binding var isPresented: Bool
    
    @State private var phoneContacts: [CNContact] = []
    @State private var selectedContacts: Set<String> = []
    @State private var isLoading = true
    @State private var showingPermissionAlert = false
    @State private var searchText = ""
    @State private var defaultClass: ContactClass = .friends
    
    var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return phoneContacts
        } else {
            return phoneContacts.filter {
                let fullName = "\($0.givenName) \($0.familyName)"
                return fullName.localizedCaseInsensitiveContains(searchText)
            }
        }
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
                
                VStack(spacing: 0) {
                    if isLoading {
                        loadingView
                    } else if phoneContacts.isEmpty {
                        emptyStateView
                    } else {
                        contentView
                    }
                }
            }
            .navigationTitle("Import Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search contacts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Import (\(selectedContacts.count))") {
                        importSelectedContacts()
                    }
                    .disabled(selectedContacts.isEmpty)
                    .foregroundColor(selectedContacts.isEmpty ? .gray : .blue)
                }
            }
            .alert("Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings", action: openSettings)
                Button("Cancel", role: .cancel) {
                    isPresented = false
                }
            } message: {
                Text("Please allow access to your contacts in Settings to import them.")
            }
            .onAppear {
                requestContactsAccess()
            }
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            
            Text("Loading contacts...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No Contacts Found")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Make sure you have contacts saved on your device")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            // Category Selection
            VStack(spacing: 16) {
                HStack {
                    Text("Import as:")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                }
                
                Picker("Default Category", selection: $defaultClass) {
                    ForEach(ContactClass.allCases, id: \.self) { contactClass in
                        HStack {
                            Image(systemName: contactClass.icon)
                            Text(contactClass.rawValue)
                        }
                        .tag(contactClass)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(20)
            .background(Color(red: 0.15, green: 0.15, blue: 0.20))
            
            // Select All / Deselect All
            HStack {
                Button(action: selectAll) {
                    Text("Select All")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: deselectAll) {
                    Text("Deselect All")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(red: 0.12, green: 0.12, blue: 0.15))
            
            // Contacts List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredContacts, id: \.identifier) { contact in
                        ContactImportRow(
                            contact: contact,
                            isSelected: selectedContacts.contains(contact.identifier)
                        ) {
                            toggleSelection(contact.identifier)
                        }
                    }
                }
                .padding(20)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func requestContactsAccess() {
        let store = CNContactStore()
        
        store.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    loadContacts()
                } else {
                    showingPermissionAlert = true
                    isLoading = false
                }
            }
        }
    }
    
    private func loadContacts() {
        let store = CNContactStore()
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        
        var contacts: [CNContact] = []
        
        do {
            try store.enumerateContacts(with: request) { contact, _ in
                // Only include contacts with names
                if !contact.givenName.isEmpty || !contact.familyName.isEmpty {
                    contacts.append(contact)
                }
            }
            
            DispatchQueue.main.async {
                self.phoneContacts = contacts.sorted {
                    let name1 = "\($0.givenName) \($0.familyName)"
                    let name2 = "\($1.givenName) \($1.familyName)"
                    return name1 < name2
                }
                self.isLoading = false
            }
        } catch {
            print("Failed to fetch contacts: \(error)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    private func toggleSelection(_ identifier: String) {
        if selectedContacts.contains(identifier) {
            selectedContacts.remove(identifier)
        } else {
            selectedContacts.insert(identifier)
        }
    }
    
    private func selectAll() {
        selectedContacts = Set(filteredContacts.map { $0.identifier })
    }
    
    private func deselectAll() {
        selectedContacts.removeAll()
    }
    
    private func importSelectedContacts() {
        for contact in phoneContacts where selectedContacts.contains(contact.identifier) {
            let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            let phoneNumber = contact.phoneNumbers.first?.value.stringValue
            
            // Check if contact already exists
            let exists = manager.data.contacts.contains { $0.name == fullName }
            if !exists {
                _ = manager.addContact(
                    name: fullName,
                    phoneNumber: phoneNumber,
                    contactClass: defaultClass
                )
            }
        }
        
        isPresented = false
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct ContactImportRow: View {
    let contact: CNContact
    let isSelected: Bool
    let action: () -> Void
    
    var fullName: String {
        "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
    }
    
    var phoneNumber: String? {
        contact.phoneNumbers.first?.value.stringValue
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .green : .white.opacity(0.3))
                
                // Contact Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(fullName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if let phone = phoneNumber {
                        Text(phone)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green.opacity(0.1) : Color(red: 0.15, green: 0.15, blue: 0.20))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

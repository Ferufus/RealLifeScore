//
//  AddContactView.swift
//  TimeTracker
//
//  Created by Thomas Bürger on 18.12.25.
//

import SwiftUI

struct AddContactView: View {
    @ObservedObject var manager: TimeTrackerManager
    @Binding var isPresented: Bool
    
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var selectedClass: ContactClass = .other
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, phone
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
                
                VStack(spacing: 30) {
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Add New Contact")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextField("Enter name", text: $name)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color(red: 0.18, green: 0.18, blue: 0.22))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .font(.system(size: 16, design: .rounded))
                                .focused($focusedField, equals: .name)
                        }
                        
                        // Phone Number Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number (Optional)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextField("Enter phone number", text: $phoneNumber)
                                .textFieldStyle(.plain)
                                .keyboardType(.phonePad)
                                .padding()
                                .background(Color(red: 0.18, green: 0.18, blue: 0.22))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .font(.system(size: 16, design: .rounded))
                                .focused($focusedField, equals: .phone)
                        }
                        
                        // Contact Class Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Picker("Category", selection: $selectedClass) {
                                ForEach(ContactClass.allCases, id: \.self) { contactClass in
                                    HStack {
                                        Image(systemName: contactClass.icon)
                                        Text(contactClass.rawValue)
                                    }
                                    .tag(contactClass)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .background(Color(red: 0.18, green: 0.18, blue: 0.22))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Add Button
                    Button(action: addContact) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text("Add Contact")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: name.isEmpty ? [.gray, .gray] : [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: name.isEmpty ? .clear : .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .disabled(name.isEmpty)
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
                            focusedField = nil
                        }
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    focusedField = .name
                }
            }
        }
    }
    
    private func addContact() {
        let phoneToSave = phoneNumber.isEmpty ? nil : phoneNumber
        _ = manager.addContact(
            name: name,
            phoneNumber: phoneToSave,
            contactClass: selectedClass
        )
        isPresented = false
    }
}

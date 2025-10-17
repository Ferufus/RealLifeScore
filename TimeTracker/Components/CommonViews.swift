//
//  CommonViews.swift
//  TimeTracker
//
//  Created by Thomas Bürger on 17.10.25.
//

import SwiftUI

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

// MARK: - Add Category Sheet
struct AddCategorySheet: View {
    @Binding var categoryName: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Category Name", text: $categoryName)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
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
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: CategoryItem
    let isExpanded: Bool
    @ObservedObject var manager: TimeTrackerManager
    let type: String
    let onToggleExpand: () -> Void
    let onDelete: () -> Void
    
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
                            .background(category.isRunning ? Color.red : (type == "work" ? Color.blue : Color.green))
                            .cornerRadius(12)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 10) {
                        TimeRow(label: "Today:", time: times.today)
                        TimeRow(label: "This Week:", time: times.week)
                        TimeRow(label: "Total:", time: times.total)
                    }
                    
                    Button(action: onDelete) {
                        Text("Delete Category")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                    .padding(.bottom, 15)
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

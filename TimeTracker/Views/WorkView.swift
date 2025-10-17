//
//  WorkView.swift
//  TimeTracker
//
//  Created by Thomas Bürger on 17.10.25.
//

import SwiftUI

struct WorkView: View {
    @ObservedObject var manager: TimeTrackerManager
    @State private var showingAddCategory = false
    @State private var newCategoryName = ""
    @State private var expandedCategories: Set<String> = []
    
    var body: some View {
        ZStack {
            Color(red: 0.17, green: 0.17, blue: 0.17)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(manager.data.workCategories) { category in
                        CategoryCard(
                            category: category,
                            isExpanded: expandedCategories.contains(category.id),
                            manager: manager,
                            type: "work",
                            onToggleExpand: {
                                if expandedCategories.contains(category.id) {
                                    expandedCategories.remove(category.id)
                                } else {
                                    expandedCategories.insert(category.id)
                                }
                            },
                            onDelete: {
                                manager.deleteCategory(id: category.id, type: "work")
                                expandedCategories.remove(category.id)
                            }
                        )
                    }
                }
                .padding()
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingAddCategory = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(30)
                }
            }
        }
        .sheet(isPresented: $showingAddCategory) {
            AddCategorySheet(
                categoryName: $newCategoryName,
                onSave: {
                    if !newCategoryName.isEmpty {
                        manager.addCategory(name: newCategoryName, type: "work")
                        newCategoryName = ""
                        showingAddCategory = false
                    }
                },
                onCancel: {
                    newCategoryName = ""
                    showingAddCategory = false
                }
            )
        }
    }
}

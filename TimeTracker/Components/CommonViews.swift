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

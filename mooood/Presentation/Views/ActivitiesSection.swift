//
//  ActivitiesSection.swift
//  mooood
//
//  Created by Boris Eder on 04.10.25.
//


import SwiftUI

struct ActivitiesSection: View {
    @Binding var selectedActivities: [String]
    let onSave: () -> Void
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Activities", systemImage: "list.bullet.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("What did you do today?")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Activity.allCases) { activity in
                    ActivityButton(
                        activity: activity,
                        isSelected: selectedActivities.contains(activity.rawValue),
                        onToggle: {
                            toggleActivity(activity)
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.cyan.opacity(0.6), Color.teal.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.cyan.opacity(0.3), radius: 12, y: 6)
    }
    
    private func toggleActivity(_ activity: Activity) {
        if selectedActivities.contains(activity.rawValue) {
            selectedActivities.removeAll { $0 == activity.rawValue }
        } else {
            selectedActivities.append(activity.rawValue)
        }
        onSave()
    }
}

// MARK: - Activity Button

struct ActivityButton: View {
    let activity: Activity
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 6) {
                Image(systemName: activity.icon)
                    .font(.system(size: 20))
                
                Text(activity.rawValue)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}
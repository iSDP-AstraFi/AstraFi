//
//  GoalSharedComponents.swift
//  AstraFiPrototype
//
//  Created by Vipul Kumar Singh on 09/03/26.
//


import SwiftUI

// MARK: - Shared Data Models

struct ProgressDataPoint: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
}

struct AllocationItem: Identifiable {
    let id = UUID()
    let label: String
    let percentage: Int
    let color: Color
}

struct SIPBarPoint: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
}

struct AnnualDeposit: Identifiable {
    let id = UUID()
    let year: String
    let amount: Double
    var isProjected: Bool = false
}

// MARK: - Shared UI Components

struct DetailInfoRow: View {
    let label: String
    let value: String
    var isDate: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            if isDate {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(8)
            } else {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
    }
}

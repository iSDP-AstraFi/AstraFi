import SwiftUI

struct Plan2InteractiveTimelineView: View {
    let yearlyData: [Plan2YearlyDetail]
    let loanAmount: Double
    let totalTenure: Int
    var emiFrequency: EMIFrequency = .monthly
    
    @State private var selectedYearIndex: Int? = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                        .font(.headline)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Repayment Timeline")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Interactive yearly breakdown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Bar Chart Timeline
            if !yearlyData.isEmpty {
                barChartTimeline()
            } else {
                Text("No data available.")
                    .font(.caption).foregroundColor(.secondary)
            }
            
            // Detail Section
            if let index = selectedYearIndex, index < yearlyData.count {
                Divider()
                detailSection(for: yearlyData[index])
            }
        }
        .padding(24)
        .background(AppTheme.cardBackground)
        .cornerRadius(24)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.5), radius: 12, x: 0, y: 6)
        .onAppear {
            if !yearlyData.isEmpty { selectedYearIndex = 0 }
        }
        .onChange(of: yearlyData) { _ in
            if !yearlyData.isEmpty { selectedYearIndex = 0 }
        }
    }
    
    private var maxEmi: Double {
        let m = yearlyData.map { $0.emiPaidYearly }.max() ?? 1.0
        return m > 0 ? m : 1.0
    }
    
    private func barChartTimeline() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 16) {
                // "Plan starts 2026"
                VStack(spacing: 4) {
                    Spacer()
                    Text("Plan")
                    Text("starts")
                    Text("\(Date().formatted(.dateTime.year()))")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
                .frame(width: 50)
                .padding(.bottom, 48) // offset to match X axis height relative to bars
                
                // Axis and Bars
                VStack(spacing: 8) {
                    HStack(alignment: .bottom, spacing: 20) {
                        ForEach(Array(yearlyData.enumerated()), id: \.offset) { index, detail in
                            let isSelected = selectedYearIndex == index
                            let heightRatio = CGFloat(detail.emiPaidYearly / maxEmi)
                            let barHeight = max(20, heightRatio * 140) // Scale to max 140 pts
                            
                            VStack(spacing: 12) {
                                // EMI Text (Above bar)
                                Text(formatL(detail.emiPaidYearly))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                // The Bar (Capsule-like drawing)
                                Capsule()
                                    .fill(isSelected ? Color.blue : Color.blue.opacity(0.25))
                                    .frame(width: 38, height: barHeight)
                                    .animation(.spring(response: 0.4), value: selectedYearIndex)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedYearIndex = index
                            }
                        }
                    }
                    
                    // Central horizontal line
                    Rectangle()
                        .fill(Color(UIColor.separator))
                        .frame(height: 2)
                        .padding(.vertical, 4)
                    
                    HStack(alignment: .top, spacing: 20) {
                        ForEach(Array(yearlyData.enumerated()), id: \.offset) { index, detail in
                            let isSelected = selectedYearIndex == index
                            
                            // Labels below Axis
                            VStack(spacing: 4) {
                                Text("\(detail.date.formatted(.dateTime.year()))")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(isSelected ? .blue : .primary)
                                
                                Text("\(formatL(detail.remainingPrincipal))")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 38) // Align exactly with bar width to center it
                        }
                    }
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 10)
        }
    }
    
    private func detailSection(for detail: Plan2YearlyDetail) -> some View {
        let paymentsCount = Int(emiFrequency.paymentsPerYear)
        // Guard against zero division
        let safePayments = max(1, paymentsCount)
        let emiValue = detail.emiPaidYearly / Double(safePayments)
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Breakdown for \(detail.date.formatted(.dateTime.year()))")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                ForEach(0..<safePayments, id: \.self) { i in
                    HStack(spacing: 16) {
                        Text(paymentLabel(for: i))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 45, alignment: .leading)
                        
                        // Horizontal Line drawing
                        Capsule()
                            .fill(Color.blue.opacity(0.5))
                            .frame(height: 5)
                            .frame(maxWidth: .infinity)
                        
                        Text("₹\(Int(emiValue).formatted())")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .frame(width: 80, alignment: .trailing)
                    }
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(UIColor.separator), lineWidth: 1)
            )
        }
    }
    
    private func paymentLabel(for index: Int) -> String {
        switch emiFrequency {
        case .monthly:
            let formatter = DateFormatter()
            return formatter.shortMonthSymbols[index % 12] // Jan, Feb...
        case .quarterly:
            return "Q\(index + 1)"
        case .halfYearly:
            return "H\(index + 1)"
        case .yearly:
            return "Annual"
        }
    }
    
    private func formatL(_ value: Double) -> String {
        let v = abs(value)
        if v >= 100000 { return String(format: "%.2fL", value / 100000) }
        else if v >= 1000 { return String(format: "%.1fK", value / 1000) }
        return String(format: "%.0f", value)
    }
}

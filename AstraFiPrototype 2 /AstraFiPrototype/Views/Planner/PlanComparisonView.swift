//
//  PlanComparisonView.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 09/02/26.
//

import SwiftUI

struct PlanComparisonView: View {
    @Environment(\.colorScheme) var colorScheme
    var input: InvestmentPlanInputModel
    var results: FullPlanResult
    @State private var animateCharts = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                quickComparisonCard
                timelineComparison
                financialBreakdown
                prosConsSection
                recommendationSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .navigationTitle("Compare Plans")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { }
        }
        .background(AppTheme.appBackground(for: colorScheme))
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animateCharts = true
            }
        }
    }

    // MARK: Header

    private var headerSection: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .purple,
                                .purple.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundColor(.white).font(.title2)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Plan Comparison").font(.headline).fontWeight(.bold)
                Text("Detailed side-by-side analysis").font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 8, x: 0, y: 2)
    }

    // MARK: Quick Comparison Table

    private var quickComparisonCard: some View {
        let p1 = results.plan1
        let p2 = results.plan2
        let score = results.comparisonScore
        
        return VStack(spacing: 0) {
            HStack {
                Text("").frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.blue).font(.body)
                    Text("Plan 1").font(.caption).fontWeight(.bold)
                    if let s = score {
                        Text("\(Int(s.plan1Score)) pts").font(.system(size: 10)).foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                VStack(spacing: 4) {
                    Image(systemName: results.goalCategory == .vehiclePurchase ? "car.fill" : "star.fill")
                        .foregroundColor(.purple).font(.body)
                    Text("Plan 2").font(.caption).fontWeight(.bold)
                    if let s = score {
                        Text("\(Int(s.plan2Score)) pts").font(.system(size: 10)).foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(AppTheme.cardBackground)

            Divider()
            ComparisonRow(label: "Strategy",           value1: "Pure Invest",  value2: p2?.name ?? "N/A", value1Color: .blue, value2Color: .purple)
            Divider()
            ComparisonRow(label: "Duration",            value1: "\(input.timePeriod) Years", value2: p2 != nil ? "\(input.timePeriod) Years" : "N/A", value1Color: .primary, value2Color: .primary)
            Divider()
            
            let p1Total = p1.totalInvested
            let p2Total = (p2?.totalAmountPaid ?? 0) + (Double(input.amount.replacingOccurrences(of: ",", with: "")) ?? 0) * (Double(Int(input.timePeriod) ?? 0) * 12)
            ComparisonRow(label: "Total Outflow",    value1: "₹\(formatL_Comp(p1Total))", value2: p2 != nil ? "₹\(formatL_Comp(p2Total))" : "N/A", value1Color: .primary, value2Color: .red)

            Divider()
            ComparisonRow(label: "Projected Wealth",    value1: "₹\(formatL_Comp(p1.projectedValue))", value2: p2 != nil ? "₹\(formatL_Comp(p2!.sipReturns))" : "N/A", value1Color: .green, value2Color: .green)
            Divider()
            ComparisonRow(label: "Net Wealth Gain",     value1: "₹\(formatL_Comp(p1.projectedValue - p1.totalInvested))", value2: p2 != nil ? "₹\(formatL_Comp(p2!.netWealthGain))" : "N/A", value1Color: .green, value2Color: .green, isHighlight: true)
            Divider()
            ComparisonRow(label: "Monthly Commitment",  value1: "₹\(input.amount)", value2: p2 != nil ? "₹\(formatL_Comp(p2!.totalMonthlyCommitment))" : "N/A", subtitle2: p2 != nil ? "(EMI + SIP)" : "", value1Color: .primary, value2Color: .orange)
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
    }

    // MARK: Timeline

    private var timelineComparison: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.2.circlepath")
                    .foregroundColor(.cyan).font(.title3)
                Text("Wealth Growth Timeline").font(.headline).fontWeight(.bold)
            }
            let p1 = results.plan1
            let p2 = results.plan2
            let maxV = Swift.max(p1.projectedValue, p2?.sipReturns ?? 1.0)
            VStack(spacing: 16) {
                TimelineBar(year: "Current", plan1Value: 0, plan2Value: 0, maxValue: maxV, animate: animateCharts)
                TimelineBar(year: "\(Int(input.timePeriod) ?? 0) Yrs", plan1Value: p1.projectedValue, plan2Value: p2?.sipReturns ?? 0, maxValue: maxV, animate: animateCharts)
            }
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle().fill(.cyan).frame(width: 10, height: 10)
                    Text("Plan 1").font(.caption).foregroundColor(.secondary)
                }
                HStack(spacing: 6) {
                    Circle().fill(.gray).frame(width: 10, height: 10)
                    Text("Plan 2").font(.caption).foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
    }

    // MARK: Financial Breakdown

    private var financialBreakdown: some View {
        let p1 = results.plan1
        let p2 = results.plan2
        
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "star.circle.fill").foregroundColor(.cyan)
                    Text("Plan 1").font(.subheadline).fontWeight(.bold)
                }
                VStack(alignment: .leading, spacing: 8) {
                    BreakdownItem(label: "Monthly SIP",    value: "₹\(input.amount)",      color: .blue)
                    BreakdownItem(label: "Duration",       value: "\(input.timePeriod) years",      color: .secondary)
                    BreakdownItem(label: "Total Invested", value: "₹\(formatL_Comp(p1.totalInvested))", color: .primary)
                    BreakdownItem(label: "Projected Value", value: "₹\(formatL_Comp(p1.projectedValue))",  color: .green)
                    BreakdownItem(label: "Net Gain",        value: "₹\(formatL_Comp(p1.projectedValue - p1.totalInvested))", color: .green)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground)
            .cornerRadius(12)

            if let p2 = p2 {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "car.circle.fill").foregroundColor(.gray)
                        Text("Plan 2").font(.subheadline).fontWeight(.bold)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        BreakdownItem(label: "Monthly SIP",    value: "₹\(input.amount)",      color: .blue)
                        BreakdownItem(label: "Duration",       value: "\(input.timePeriod) years",  color: .secondary)
                        BreakdownItem(label: "Loan Cost",      value: "₹\(formatL_Comp(p2.totalInterestPaid))",     color: .red)
                        BreakdownItem(label: "Projected Value", value: "₹\(formatL_Comp(p2.sipReturns))",   color: .green)
                        BreakdownItem(label: "Net Gain",       value: "₹\(formatL_Comp(p2.netWealthGain))",   color: .green)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
            }
        }
    }

    // MARK: Pros & Cons

    private var prosConsSection: some View {
        VStack(spacing: 20) {
            if let score = results.comparisonScore {
                scoreDimensionsCard(score: score)
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Plan 1").font(.subheadline).fontWeight(.bold)
                    VStack(alignment: .leading, spacing: 8) {
                        ProConItem(icon: "checkmark.circle.fill", text: "No debt/loan",      isPositive: true)
                        ProConItem(icon: "checkmark.circle.fill", text: "Lower risk",        isPositive: true)
                        ProConItem(icon: "xmark.circle.fill",     text: "Delayed Asset",      isPositive: false)
                        ProConItem(icon: "xmark.circle.fill",     text: "Opportunity Cost",   isPositive: false)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(AppTheme.cardBackground)
                .cornerRadius(12)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Plan 2").font(.subheadline).fontWeight(.bold)
                    VStack(alignment: .leading, spacing: 8) {
                        ProConItem(icon: "checkmark.circle.fill", text: "Immediate Asset",  isPositive: true)
                        ProConItem(icon: "checkmark.circle.fill", text: "Higher Net Gains",  isPositive: true)
                        ProConItem(icon: "xmark.circle.fill",     text: "EMI Commitment",    isPositive: false)
                        ProConItem(icon: "xmark.circle.fill",     text: "Interest Paid",     isPositive: false)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
            }
        }
    }

    private func scoreDimensionsCard(score: PlanComparisonScore) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "scalemass.fill").foregroundColor(.cyan)
                Text("AI Scoring Dimensions").font(.subheadline).fontWeight(.bold)
            }
            
            VStack(spacing: 12) {
                let dimensions: [ScoreDimension] = score.dimensions
                ForEach(dimensions) { dim in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(dim.axis).font(.caption).foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(dim.weight * 100))% weight").font(.system(size: 9)).foregroundColor(.secondary)
                        }
                        HStack(spacing: 12) {
                            scoreMiniBar(value: dim.plan1Points, color: .blue)
                            scoreMiniBar(value: dim.plan2Points, color: .purple)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: AppTheme.adaptiveShadow, radius: 4, x: 0, y: 2)
    }

    private func scoreMiniBar(value: Double, color: Color) -> some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.1)).frame(height: 4)
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 80 * (value / 10), height: 4)
        }
    }

    // MARK: Recommendation

    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow).font(.title3)
                Text("Our Recommendation").font(.headline).fontWeight(.bold)
            }
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.gray).font(.title2)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(results.recommendations.primaryRecommendation)
                            .font(.headline).fontWeight(.bold)
                            .foregroundColor(results.comparisonScore?.winner == "Plan 2" ? .purple : .blue)
                        Text(results.recommendations.reason)
                            .font(.caption).foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Highlights:").font(.caption).fontWeight(.semibold)
                    ForEach(results.recommendations.tips) { tip in
                        InsightBullet(text: "\(tip.title): \(tip.description)")
                    }
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
    }

    private func formatL_Comp(_ value: Double) -> String {
        let v = abs(value)
        if v >= 100000 { return String(format: "%.1fL", value / 100000) }
        if v >= 1000 { return String(format: "%.1fK", value / 1000) }
        return String(format: "%.0f", value)
    }
}

// MARK: - Comparison Row

struct ComparisonRow: View {
    let label: String
    let value1: String
    let value2: String
    var subtitle2: String = ""
    var value1Color: Color
    var value2Color: Color
    var isHighlight: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption).foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value1)
                .font(isHighlight ? .subheadline : .caption)
                .fontWeight(isHighlight ? .bold : .semibold)
                .foregroundColor(value1Color)
                .frame(maxWidth: .infinity)
            VStack(spacing: 2) {
                Text(value2)
                    .font(isHighlight ? .subheadline : .caption)
                    .fontWeight(isHighlight ? .bold : .semibold)
                    .foregroundColor(value2Color)
                if !subtitle2.isEmpty {
                    Text(subtitle2).font(.system(size: 9)).foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, isHighlight ? 12 : 10)
        .padding(.horizontal, 16)
        .background(isHighlight ? Color.green.opacity(0.05) : Color.clear)
    }
}

// MARK: - Timeline Bar

struct TimelineBar: View {
    let year: String
    let plan1Value: Double
    let plan2Value: Double
    let maxValue: Double
    var animate: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(year).font(.caption).fontWeight(.semibold)
            HStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.cyan.opacity(0.2)).frame(height: 12)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.cyan)
                            .frame(width: animate ? geo.size.width * CGFloat(plan1Value / Swift.max(1, maxValue)) : 0, height: 12)
                            .animation(.spring(response: 1.0, dampingFraction: 0.7), value: animate)
                    }
                }
                .frame(maxWidth: .infinity)
                Text("₹\(formatL_Bare(plan1Value))")
                    .font(.caption).foregroundColor(.cyan)
                    .frame(width: 60, alignment: .trailing)
            }
            HStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.2)).frame(height: 12)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.gray)
                            .frame(width: animate ? geo.size.width * CGFloat(plan2Value / Swift.max(1, maxValue)) : 0, height: 12)
                            .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.2), value: animate)
                    }
                }
                .frame(maxWidth: .infinity)
                Text("₹\(formatL_Bare(plan2Value))")
                    .font(.caption).foregroundColor(.gray)
                    .frame(width: 60, alignment: .trailing)
            }
        }
    }
    
    private func formatL_Bare(_ value: Double) -> String {
        if value >= 100000 { return String(format: "%.1fL", value / 100000) }
        return String(format: "%.0f", value)
    }
}

// MARK: - Breakdown Item

struct BreakdownItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.caption).fontWeight(.semibold).foregroundColor(color)
        }
    }
}

// MARK: - Pro/Con Item

struct ProConItem: View {
    let icon: String
    let text: String
    let isPositive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption)
                .foregroundColor(isPositive ? .green : .red)
            Text(text).font(.caption).foregroundColor(.primary)
        }
    }
}

// MARK: - Insight Bullet

struct InsightBullet: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Circle()
                .fill(.cyan)
                .frame(width: 4, height: 4)
                .padding(.top, 5)
            Text(text).font(.caption).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}




#Preview {
    let sampleInput = InvestmentPlanInputModel(investmentType: "Monthly", amount: "20,000", liquidity: "High", riskType: "Low", timePeriod: "4", scheduleInvestmentDate: Date(), scheduleSIPDate: Date(), purposeOfInvestment: "Car", targetAmount: "14,80,000", savedAmount: "70,000", hasEmergencyFund: true, preferredLoanTenureYears: 4)
    let sampleResult = InvestmentPlannerEngine.generateFullPlan(input: sampleInput)

    return NavigationStack {
        PlanComparisonView(input: sampleInput, results: sampleResult)
    }
}

import SwiftUI
import Charts

struct Plan3DetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppStateManager
    
    var input: InvestmentPlanInputModel
    var result: Plan3Result

    @State private var currentResult: Plan3Result? = nil
    @State private var loanOverride: Double = 0
    @State private var tenureOverride: Int = 0
    @State private var bankName: String = ""
    @State private var interestRate: Double = 0.0
    @State private var returnRateOverride: Double = 12.0
    
    private var activeResult: Plan3Result { currentResult ?? result }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    interactiveAdjusters
                    strategyCalculativeDashboard
                    arbitrageChartCard
                    flowTableCard
                    finalResultCard
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .onAppear {
                loanOverride = InvestmentPlannerEngine.parseAmount(input.targetAmount)
                tenureOverride = Int(input.timePeriod) ?? 5
                bankName = input.bankName ?? ""
                interestRate = input.interestRate ?? 10.5
                returnRateOverride = activeResult.expectedReturnRate > 0 ? activeResult.expectedReturnRate : 12.0
            }
            .navigationTitle("Arbitrage Strategy")
        }
    }
    
    
    
    private var interactiveAdjusters: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.cyan)
                    Text("Interactive Adjustments")
                        .font(.headline)
                    Spacer()
                }
                Text("Fine-tune your strategy parameters to see their impact instantly.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Loan Amount Slider
            let safeMin = 50000.0
            let safeMax = Swift.max(loanOverride * 1.5, 5000000.0)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Loan Amount").font(.footnote).foregroundColor(.secondary)
                    Spacer()
                    Text("₹\(Int(loanOverride).formatted())").font(.subheadline).bold().foregroundColor(.blue)
                }
                Slider(value: $loanOverride, in: safeMin...safeMax, step: 50000) { _ in
                    recalculate()
                }
                .accentColor(.blue)
            }

            // Expected Return Slider
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Expected Return Rate (p.a)").font(.footnote).foregroundColor(.secondary)
                    Spacer()
                    Text("\(returnRateOverride, specifier: "%.1f")%").font(.subheadline).bold().foregroundColor(.green)
                }
                Slider(value: $returnRateOverride, in: 5...30, step: 0.5) { _ in
                    recalculate()
                }
                .accentColor(.green)
            }

            // Tenure Slider
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Time Period").font(.footnote).foregroundColor(.secondary)
                    Spacer()
                    Text("\(tenureOverride) Years").font(.subheadline).bold().foregroundColor(.blue)
                }
                Slider(value: Binding(get: { Double(tenureOverride) }, set: { tenureOverride = Int($0) }), in: 1...30, step: 1) { _ in
                    recalculate()
                }
                .accentColor(.blue)
            }
            
            // Bank & Rate
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bank Name").font(.footnote).foregroundColor(.secondary)
                    TextField("Bank", text: $bankName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: bankName) { _ in recalculate() }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Interest Rate (%)").font(.footnote).foregroundColor(.secondary)
                    TextField("Rate", value: $interestRate, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .onChange(of: interestRate) { _ in recalculate() }
                }
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.5), radius: 10, x: 0, y: 4)
    }
    
    private func recalculate() {
        let newResult = InvestmentPlannerEngine.recalculatePlan3(
            input: input,
            overridenLoan: loanOverride,
            overridenTenure: tenureOverride,
            overridenBank: bankName.isEmpty ? nil : bankName,
            overridenRate: interestRate > 0 ? interestRate : nil,
            overridenReturn: returnRateOverride
        )
        withAnimation {
            currentResult = newResult
        }
    }
    
    private var strategyCalculativeDashboard: some View {
        let invested = activeResult.investedAmount
        let noOfEMIs = activeResult.tenure * 4
        let perEMI = activeResult.monthlyEMI
        let totalEMI = perEMI * Double(noOfEMIs)
        
        let finalValue = activeResult.netWealthGain
        let isProfit = finalValue >= 0
        
        return VStack(spacing: 24) {
            Text("Investment vs Debt Analysis")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                Chart {
                    SectorMark(
                        angle: .value("Total EMI Paid", totalEMI),
                        innerRadius: .ratio(0.65),
                        angularInset: 1.5
                    )
                    .foregroundStyle(Color.red.opacity(0.8))
                    
                    if finalValue > 0 {
                        SectorMark(
                            angle: .value("Remaining Profit", finalValue),
                            innerRadius: .ratio(0.65),
                            angularInset: 1.5
                        )
                        .foregroundStyle(Color.green)
                    }
                }
                .frame(height: 160)
                
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle().fill(Color.blue.opacity(0.3)).frame(width: 8, height: 8)
                            Text("Loan Invested").font(.caption).foregroundColor(.secondary)
                        }
                        Text("₹\(Int(invested).formatted())").font(.subheadline).bold()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle().fill(Color.orange.opacity(0.6)).frame(width: 8, height: 8)
                            Text("EMI Details").font(.caption).foregroundColor(.secondary)
                        }
                        Text("\(noOfEMIs) EMIs of ₹\(Int(perEMI).formatted())").font(.subheadline).bold()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle().fill(Color.red.opacity(0.8)).frame(width: 8, height: 8)
                            Text("Total EMI Paid").font(.caption).foregroundColor(.secondary)
                        }
                        Text("₹\(Int(totalEMI).formatted())").font(.subheadline).bold()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle().fill(isProfit ? Color.green : Color.red).frame(width: 8, height: 8)
                            Text(isProfit ? "Final Remaining Profit" : "Shortfall").font(.caption).foregroundColor(.secondary)
                        }
                        Text("₹\(Int(abs(finalValue)).formatted())").font(.subheadline).bold()
                            .foregroundColor(isProfit ? .green : .red)
                    }
                }
            }
            Text("You invested the ₹\(Int(invested).formatted()) loan at \(activeResult.expectedReturnRate, specifier: "%.1f")%. Over \(activeResult.tenure) years, you pay \(noOfEMIs) EMIs totaling ₹\(Int(totalEMI).formatted()) out of the fund. Ultimately, you are left with a pure gain of ₹\(Int(finalValue).formatted()) without investing your own money.")
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.5), radius: 10, x: 0, y: 4)
    }
    
    private var arbitrageChartCard: some View {
        let totalEMI = activeResult.monthlyEMI * 4 * Double(activeResult.tenure)
        let endValue = activeResult.yearlyBreakdown.last?.investmentValue ?? 0
        let totalProfit = endValue - activeResult.investedAmount
        let overallGain = activeResult.netWealthGain
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Plan")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Arbitrage Strategy")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("Yearly EMI → ₹\(Int(activeResult.monthlyEMI).formatted()) x 4")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            
            Chart {
                ForEach(activeResult.yearlyBreakdown) { year in
                    // Positive Bar: Investment Value
                    BarMark(
                        x: .value("Year", "Yr \(year.year)"),
                        y: .value("Value", year.investmentValue)
                    )
                    .foregroundStyle(Color.green)
                    .annotation(position: .top, alignment: .center) {
                        Text(formatL(year.investmentValue))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    // Negative Bar: EMI Outflow
                    BarMark(
                        x: .value("Year", "Yr \(year.year)"),
                        y: .value("EMI", -year.emiPaidYearly)
                    )
                    .foregroundStyle(Color.red.opacity(0.8))
                    .annotation(position: .bottom, alignment: .center) {
                        Text(formatL(year.emiPaidYearly))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 250)
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: 6)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel() {
                        if let v = value.as(Double.self) {
                            Text(formatL(abs(v)))
                        }
                    }
                    AxisGridLine()
                }
            }
            
            Divider().padding(.vertical, 8)
            
            // Summary Box (as per sketch)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("In \(activeResult.tenure) year plan total EMI")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("₹\(Int(totalEMI).formatted())")
                        .font(.subheadline).bold()
                }
                
                HStack {
                    Text("Total Profit")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("₹\(Int(totalProfit).formatted())")
                        .font(.subheadline).bold()
                }
                
                Divider()
                
                HStack {
                    Text("Overall gain / loss")
                        .font(.headline)
                    Spacer()
                    Text("₹\(Int(overallGain).formatted())")
                        .font(.headline)
                        .foregroundColor(overallGain >= 0 ? .green : .red)
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 4)
    }
    
    private func formatL(_ value: Double) -> String {
        let v = abs(value)
        if v >= 100000 { return String(format: "%.1fL", value / 100000) }
        if v >= 1000 { return String(format: "%.1fK", value / 1000) }
        return String(format: "%.0f", value)
    }
    
    private func formatLakhs(_ value: Double) -> String {
        return String(format: "%.2f", value / 100000)
    }

    private var flowTableCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📊 \(activeResult.tenure)-Year Table (Accurate Flow)")
                .font(.headline)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Yr").bold().frame(width: 25, alignment: .leading)
                    Text("Start").bold().frame(maxWidth: .infinity, alignment: .trailing)
                    Text("Growth").bold().frame(maxWidth: .infinity, alignment: .trailing)
                    Text("EMI").bold().frame(maxWidth: .infinity, alignment: .trailing)
                    Text("End").bold().frame(maxWidth: .infinity, alignment: .trailing)
                }
                .font(.caption2)
                .padding(.bottom, 8)
                .foregroundColor(.secondary)
                
                Divider()
                
                ForEach(activeResult.yearlyBreakdown) { year in
                    HStack {
                        Text("\(year.year)").frame(width: 25, alignment: .leading)
                        Text(formatLakhs(year.startValue)).frame(maxWidth: .infinity, alignment: .trailing)
                        Text(formatLakhs(year.startValue + (year.investmentValue - year.startValue + year.emiPaidYearly))).frame(maxWidth: .infinity, alignment: .trailing)
                        Text(formatLakhs(year.emiPaidYearly)).frame(maxWidth: .infinity, alignment: .trailing)
                        Text(formatLakhs(year.investmentValue)).frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .font(.caption2)
                    .padding(.vertical, 8)
                    Divider()
                }
            }
            Text("*All values are in ₹Lakhs")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.5), radius: 10, x: 0, y: 4)
    }
    
    private var finalResultCard: some View {
        let noOfEMIs = activeResult.tenure * 4
        let totalEMI = activeResult.monthlyEMI * Double(noOfEMIs)
        let finalValue = activeResult.netWealthGain
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("🎯 Final Result (After \(activeResult.tenure) Years)")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("In \(activeResult.tenure) year plan Total EMI Paid")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("₹\(Int(totalEMI).formatted())")
                        .font(.subheadline).bold()
                }
                
                Divider()
                
                HStack {
                    Text("Overall gain / loss")
                        .font(.headline)
                    Spacer()
                    Text("₹\(Int(finalValue).formatted())")
                        .font(.headline)
                        .foregroundColor(finalValue >= 0 ? .green : .red)
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("🔥 What This Means")
                    .font(.subheadline)
                    .bold()
                
                HStack(alignment: .top) {
                    Text("👉")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You:").fontWeight(.medium)
                        Text("• Paid full loan EMI (₹\(formatLakhs(totalEMI))L total)\n• Still kept almost your full capital")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("*This data will vary according to loan amount or time period changes.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow.opacity(0.5), radius: 10, x: 0, y: 4)
    }
}

struct Plan3YearlyTableSheet: View {
    @Environment(\.dismiss) var dismiss
    let details: [Plan3YearlyDetail]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(details) { year in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Year \(year.year)")
                                .fontWeight(.bold)
                            Spacer()
                            Text(year.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Investment Value").font(.caption2).foregroundColor(.secondary)
                                Text("₹\(Int(year.investmentValue).formatted())").font(.footnote).fontWeight(.semibold)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Net Yearly Profit").font(.caption2).foregroundColor(.secondary)
                                Text("₹\(Int(year.netYearlyProfit).formatted())").font(.footnote).fontWeight(.bold).foregroundColor(year.netYearlyProfit > 0 ? .green : .red)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Yearly Breakdown")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

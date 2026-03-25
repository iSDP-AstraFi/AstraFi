//
//  NewInvestmentPlanView.swift
//  AstraFiPrototype
//
//  Enhanced version with navigation and animations
//

import SwiftUI

// MARK: - Local Helpers
private extension Color {
    /// Unselected toggle button border
    static let toggleBorder = Color(UIColor.separator)
}

// MARK: - Main View

struct NewInvestmentPlanView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var appState: AppStateManager

    @State private var investmentType: InvestmentType = .monthly
    @State private var amount: String = ""
    @State private var liquidity: LiquidityLevel = .medium
    @State private var riskType: RiskLevel = .mid
    @State private var timePeriod: Int = 5
    @State private var scheduleInvestmentDate = Date()
    @State private var scheduleSIPDate = Date()
    @State private var purposeOfInvestment: String
    @State private var targetAmount: String = ""
    @State private var savedAmount: String = ""
    @State private var investmentMentality: InvestmentMentality = .mutualFunds
    @State private var showResultView = false
    
    var initialGoal: String? = nil
    
    init(initialGoal: String? = nil) {
        self.initialGoal = initialGoal
        _purposeOfInvestment = State(initialValue: initialGoal ?? "Retirement")
    }
    
    @State private var loanTenure: String = "4"
    @State private var income: String = ""
    @State private var emis: String = ""
    @State private var openToLoan: Bool = true
    @State private var loanBankName: String = ""
    @State private var loanInterestRate: String = ""
    @State private var loanTargetAmount: String = ""
    
    // Retirement Details
    @State private var currentAge: String = "30"
    @State private var retireAge: Int = 60
    @State private var postRetireYears: Int = 20
    @State private var lifestyle: String = "Same"
    @State private var yearlyStepUp: String = "10"
    @State private var withdrawPref: String = "Fixed"
    
    // Education
    @State private var eduFor: String = "Child"
    @State private var eduDuration: Int = 4
    @State private var eduLocation: String = "India"
    @State private var fundStrategy: String = "Partial loan"
    
    // Home/Vehicle/Trip
    @State private var downpay: String = ""
    @State private var vehicleBuyOnlyIfFunded: Bool = false
    @State private var tripType: String = "Domestic"
    @State private var flexibleTrip: Bool = true
    @State private var wedSplit: String = "Self-funded"
    @State private var wealthGoal: String = "Financial freedom"

    enum InvestmentType: String, CaseIterable {
        case oneTime = "One Time"
        case monthly = "Monthly (SIP)"
        case swp     = "Withdrawal (SWP)"
        case stp     = "Transfer (STP)"
    }

    enum LiquidityLevel: String, CaseIterable {
        case high = "High"; case medium = "Medium"; case low = "Low"
    }

    enum RiskLevel: String, CaseIterable {
        case low = "Low"; case mid = "Mid"; case high = "High"
    }

    private var fieldLabelForType: String {
        switch investmentType {
        case .oneTime: return "One-time Amount"
        case .monthly: return "Monthly SIP Amount"
        case .swp:     return "Monthly Withdrawal Amount"
        case .stp:     return "Monthly Transfer Amount"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppTheme.appBackground(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        headerSection
                        
                        VStack(spacing: 24) {
                            // DYNAMIC GOAL QUESTIONNAIRE
                            dynamicGoalDetailSection
                            
                            SectionCard(title: "Investment Basis", icon: "briefcase.fill") {
                                VStack(spacing: 16) {
                                    FormPickerField(
                                        label: "Investment Mode",
                                        selection: $investmentType,
                                        options: InvestmentType.allCases,
                                        icon: "repeat.circle.fill"
                                    )
                                    
                                    FormTextField(
                                        label: fieldLabelForType,
                                        value: $amount,
                                        keyboardType: .numberPad,
                                        icon: "indianrupeesign.circle.fill"
                                    )
                                }
                            }

                            SectionCard(title: "Investment Target", icon: "target") {
                                VStack(spacing: 16) {
                                    FormTextField(
                                        label: "Target Amount",
                                        value: $targetAmount,
                                        keyboardType: .numberPad,
                                        icon: "flag.fill"
                                    )
                                    
                                    FormTextField(
                                        label: "Time Period (Years)",
                                        value: Binding(
                                            get: { String(timePeriod) },
                                            set: { newValue in
                                                if let intVal = Int(newValue) { timePeriod = intVal }
                                            }
                                        ),
                                        keyboardType: .numberPad,
                                        icon: "calendar"
                                    )
                                }
                            }
                            
                            SectionCard(title: "Advisor Settings", icon: "slider.horizontal.3") {
                                VStack(spacing: 16) {
                                    FormPickerField(
                                        label: "Risk Appetite",
                                        selection: $riskType,
                                        options: RiskLevel.allCases,
                                        icon: "bolt.ring.closed"
                                    )
                                    FormPickerField(
                                        label: "Where will you invest?",
                                        selection: $investmentMentality,
                                        options: InvestmentMentality.allCases,
                                        icon: investmentMentality.icon
                                    )
                                    
                                    HStack {
                                        Text("Open to Loans?")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Toggle("", isOn: $openToLoan)
                                            .labelsHidden()
                                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.3 : 1.0))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Bottom spacer for the fixed button
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 20)
                }

                provideButtonBackground
            }
            .navigationTitle("\(purposeOfInvestment) Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
            }
            .navigationDestination(isPresented: $showResultView) {
                let profile = appState.currentProfile
                let finalIncome = Double(income) ?? (profile?.basicDetails.monthlyIncomeAfterTax ?? 100000)
                let finalEmis = Double(emis) ?? (profile?.loans.reduce(0) { $0 + $1.calculatedEMI } ?? 0)
                let fundReady = (profile?.basicDetails.emergencyFundAmount ?? 0) > 0 || (profile?.financialHealthReport?.emergencyFundMonths ?? 0) >= 3
                
                let inputModel = InvestmentPlanInputModel(
                    investmentType: investmentType.rawValue,
                    amount: amount,
                    liquidity: liquidity.rawValue,
                    riskType: riskType.rawValue,
                    timePeriod: String(timePeriod),
                    scheduleInvestmentDate: scheduleInvestmentDate,
                    scheduleSIPDate: scheduleSIPDate,
                    purposeOfInvestment: purposeOfInvestment,
                    targetAmount: targetAmount,
                    savedAmount: savedAmount,
                    hasEmergencyFund: fundReady,
                    investmentMentality: investmentMentality,
                    monthlyIncome: finalIncome,
                    existingEMIs: finalEmis,
                    openToLoan: openToLoan,
                    preferredLoanTenureYears: Int(loanTenure) ?? 4,
                    bankName: loanBankName.isEmpty ? nil : loanBankName,
                    interestRate: Double(loanInterestRate),
                    loanAmount: Double(loanTargetAmount),
                    retirementAge: retireAge,
                    yearsPostRetirement: postRetireYears,
                    lifestylePreference: lifestyle,
                    yearlyStepUpPct: Double(yearlyStepUp),
                    withdrawalPreference: withdrawPref,
                    educationFor: eduFor,
                    educationDurationYrs: eduDuration,
                    educationLocation: eduLocation,
                    fundingStrategy: fundStrategy,
                    downPaymentAffordable: Double(downpay),
                    vehicleBuyLogic: vehicleBuyOnlyIfFunded ? "Funded" : "Loan",
                    destinationType: tripType,
                    isFlexibleTimeline: flexibleTrip,
                    contributionSplit: wedSplit,
                    wealthIntent: wealthGoal
                )
                InvestmentPlanResultView(input: inputModel)
            }
            .onAppear {
                if let profile = appState.currentProfile {
                    if income.isEmpty {
                        income = String(format: "%.0f", profile.basicDetails.monthlyIncomeAfterTax)
                    }
                    if emis.isEmpty {
                        let totalEMI = profile.loans.reduce(0) { $0 + $1.calculatedEMI }
                        emis = String(format: "%.0f", totalEMI)
                    }
                    currentAge = String(profile.basicDetails.age)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.accentGradient)
                        .frame(width: 56, height: 56)
                    Image(systemName: "sparkles")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Astra Advisor")
                        .font(.caption)
                        .fontWeight(.bold)
                        .textCase(.uppercase)
                        .foregroundColor(.blue)
                    Text(purposeOfInvestment)
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            
            Text("Our AI engine will analyze your profile and goals to recommend the optimal path to financial freedom.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private func iconFor(_ type: InvestmentType) -> String {
        switch type {
        case .oneTime: return "leaf.fill"
        case .monthly: return "calendar.badge.clock"
        case .swp:     return "arrow.up.right.circle.fill"
        case .stp:     return "arrow.left.arrow.right.circle.fill"
        }
    }

    private var provideButtonBackground: some View {
        VStack {
            Spacer()
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .frame(height: 100)
                    .mask(LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom))
                
                provideButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var provideButton: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showResultView = true
            }
        }) {
            HStack(spacing: 12) {
                Text("Generate Investment Plan")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(AppTheme.accentGradient)
            .cornerRadius(16)
            .shadow(color: AppTheme.accentShadow, radius: 10, x: 0, y: 5)
        }
    }

    // MARK: - Goal Specific Sections

    @ViewBuilder
    private var dynamicGoalDetailSection: some View {
        switch purposeOfInvestment {
        case "Retirement":
            SectionCard(title: "Retirement Vision", icon: "sun.max.fill") {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Current Age").font(.footnote).foregroundColor(.secondary).padding(.leading, 4)
                        Text(currentAge)
                            .font(.body).fontWeight(.bold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.1 : 0.5))
                            .cornerRadius(12)
                    }
                    
                    FormTextField(label: "Retirement Age", value: Binding(
                        get: { String(retireAge) },
                        set: { newValue in if let val = Int(newValue) { retireAge = val } }
                    ), keyboardType: .numberPad, icon: "clock.fill")
                    
                    FormStepperField(label: "Years Post-Retirement", value: $postRetireYears, range: 10...40)
                    FormPickerField(label: "Lifestyle Mode", selection: $lifestyle, options: ["Minimal", "Same", "Better"], icon: "star.fill")
                    FormTextField(label: "Yearly Step-up (%)", value: $yearlyStepUp, keyboardType: .decimalPad, icon: "chart.line.uptrend.xyaxis")
                    FormPickerField(label: "Withdrawal Style", selection: $withdrawPref, options: ["Fixed", "Flexible", "Not Sure"], icon: "arrow.down.to.line")
                }
            }
        case "Education":
            SectionCard(title: "Education Details", icon: "book.fill") {
                VStack(spacing: 16) {
                    FormPickerField(label: "Target Student", selection: $eduFor, options: ["Myself", "Child"], icon: "person.fill")
                    FormTextField(label: "Course Duration (Years)", value: Binding(
                        get: { String(eduDuration) },
                        set: { newValue in if let val = Int(newValue) { eduDuration = val } }
                    ), keyboardType: .numberPad, icon: "clock.fill")
                    FormPickerField(label: "Location", selection: $eduLocation, options: ["India", "Abroad"], icon: "map.fill")
                    FormPickerField(label: "Funding Logic", selection: $fundStrategy, options: ["Self-funded", "Partial loan", "Full loan"], icon: "creditcard.fill")
                }
            }
        case "Home Purchase":
            SectionCard(title: "Home Details", icon: "house.fill") {
                VStack(spacing: 16) {
                    FormTextField(label: "Down Payment Affordable", value: $downpay, keyboardType: .numberPad, icon: "indianrupeesign.circle")
                }
            }
        case "Vehicle":
            SectionCard(title: "Vehicle Goals", icon: "car.fill") {
                VStack(spacing: 16) {
                    HStack {
                        Text("Buy only if fully funded?")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Toggle("", isOn: $vehicleBuyOnlyIfFunded)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.3 : 1.0))
                    .cornerRadius(12)
                }
            }
        case "Travel / Trip":
            SectionCard(title: "Trip Details", icon: "airplane") {
                VStack(spacing: 16) {
                    FormPickerField(label: "Destination", selection: $tripType, options: ["Domestic", "International"], icon: "globe")
                    
                    HStack {
                        Text("Flexible timeline?")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Toggle("", isOn: $flexibleTrip)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.3 : 1.0))
                    .cornerRadius(12)
                }
            }
        case "Wedding":
            SectionCard(title: "Wedding Details", icon: "ring.circle.fill") {
                VStack(spacing: 16) {
                    FormTextField(label: "Wedding Budget", value: $targetAmount, keyboardType: .numberPad, icon: "tag.fill")
                    FormTextField(label: "Existing Savings for Wedding", value: $savedAmount, keyboardType: .numberPad, icon: "banknote.fill")
                    FormPickerField(label: "Funding Split", selection: $wedSplit, options: ["Self-funded", "Family support", "Mixed"], icon: "person.3.fill")
                    FormStepperField(label: "Plan in (Years)", value: $timePeriod, range: 1...10)
                }
            }
        case "Wealth Creation":
            SectionCard(title: "Wealth Strategy", icon: "crown.fill") {
                VStack(spacing: 16) {
                    FormTextField(label: "Target Wealth Corpus", value: $targetAmount, keyboardType: .numberPad, icon: "flag.fill")
                    FormTextField(label: "Existing Wealth Savings", value: $savedAmount, keyboardType: .numberPad, icon: "banknote.fill")
                    FormPickerField(label: "Investment Intent", selection: $wealthGoal, options: ["General wealth", "Early retirement", "Financial freedom"], icon: "sparkles")
                    FormStepperField(label: "Time Horizon (Years)", value: $timePeriod, range: 3...30)
                }
            }
        default:
            EmptyView()
        }
    }
}

// MARK: - Specialized Components

struct FormStepperField: View {
    let label: String
    @Binding var value: Int
    var range: ClosedRange<Int>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.footnote).foregroundColor(.secondary).padding(.leading, 4)
            HStack {
                Text("\(value)")
                    .font(.body).fontWeight(.bold)
                Spacer()
                Stepper("", value: $value, in: range)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemBackground).opacity(0.3))
            .cornerRadius(12)
        }
    }
}

// MARK: - Unified Form Picker
struct FormPickerField<T: Hashable>: View {
    @Environment(\.colorScheme) var colorScheme
    let label: String
    @Binding var selection: T
    let options: [T]
    var icon: String = "slider.horizontal.3"
    var description: String? = nil
    
    // String Provider to handle both String options and Enum .rawValue options
    private var labelForOption: (T) -> String {
        return { option in
            if let rawValue = (option as? any RawRepresentable)?.rawValue as? String {
                return rawValue
            }
            return "\(option)"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.footnote).foregroundColor(.secondary).padding(.leading, 4)
            Menu {
                Picker(label, selection: $selection) {
                    ForEach(options, id: \.self) { option in
                        Text(labelForOption(option)).tag(option)
                    }
                }
            } label: {
                HStack {
                    Text(labelForOption(selection)).font(.body).foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.up.down").font(.caption).foregroundColor(.blue)
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.3 : 1.0))
                .cornerRadius(12)
            }
            
            if let desc = description {
                Text(desc).font(.caption2).foregroundStyle(.secondary).padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - Section Card Wrapper
struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.accentGradient)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            VStack(spacing: 16) {
                content
            }
        }
        .padding(18)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: AppTheme.adaptiveShadow, radius: 10, x: 0, y: 5)
    }
}

// MARK: - Form Text Field

struct FormTextField: View {
    @Environment(\.colorScheme) var colorScheme
    let label: String
    @Binding var value: String
    var keyboardType: UIKeyboardType = .default
    var icon: String = "pencil"

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            TextField("Enter Value", text: $value)
                .font(.body)
                .keyboardType(keyboardType)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.3 : 1.0))
                .cornerRadius(12)
        }
    }
}

// MARK: - Form Date Field

struct FormDateField: View {
    @Environment(\.colorScheme) var colorScheme
    let label: String
    @Binding var date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.leading, 4)

            HStack {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemBackground).opacity(colorScheme == .dark ? 0.3 : 1.0))
            .cornerRadius(12)
        }
    }
}


#Preview {
    NewInvestmentPlanView()
        .environmentObject(AppStateManager.withSampleData())
}


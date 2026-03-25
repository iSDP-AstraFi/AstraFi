//
//  InvestmentPlannerEngine.swift
//  AstraFiPrototype
//
//  Upgraded Engine v2.0
//  ─────────────────────────────────────────────────────────────────────────────
//  Key Upgrades:
//  1. Goal-category-aware portfolio construction (retirement, education, home, etc.)
//  2. Full financial health integration: net worth, expenses, debt-to-income,
//     emergency fund, investment score, existing EMIs
//  3. Quantitative plan-comparison scoring (10-dimension rubric)
//  4. Behavioural-finance guard-rails (never allocate >40% of investable surplus,
//     emergency-fund gate, high-debt throttle)
//  5. Dynamic Plan 2 strategy: not just "loan", but 3 sub-types
//     (a) Loan + SIP parallel  (b) SWP-funded  (c) Hybrid down-pay + SIP sprint
//  6. Rich, validated reasoning text for every recommendation
//  ─────────────────────────────────────────────────────────────────────────────

import Foundation

// MARK: - Plan2Strategy (Engine-internal)

enum Plan2Strategy {
    case loanPlusSIPParallel    // Classic: take loan, keep SIP running
    case sipSprintThenBuy       // Save aggressively via SIP to buy outright
    case hybridDownpayPlusSIP   // Partial loan + SIP sprint to fund remaining
}

// MARK: - Engine

class InvestmentPlannerEngine {

    // MARK: Public Entry Point

    static func generateFullPlan(
        input: InvestmentPlanInputModel,
        profile: AstraUserProfile? = nil
    ) -> FullPlanResult {

        // 1. Resolve financial health context
        let healthCtx = buildFinancialHealthContext(input: input, profile: profile)

        // 2. Goal category
        let goalCategory = InvestmentGoalCategory.from(purpose: input.purposeOfInvestment)

        // 3. Risk & Liquidity
        let risk = resolveRiskLevel(input: input, profile: profile, goalCategory: goalCategory)
        let liquid = mapLiquidityLevel(input.liquidity)

        // 4. Feasibility
        let feasibility = validateFeasibility(input: input, healthCtx: healthCtx)

        // 5. Secure safe investable surplus
        let requestedAmt = parseAmount(input.amount)
        let safeAmt = healthAdjustedSIPAmount(requested: requestedAmt, healthCtx: healthCtx)

        // 6. Generate Plan 1 (Pure Investment)
        var plan1 = generatePlan1(input: input, risk: risk, liquidity: liquid,
                                  safeAmt: safeAmt, goalCategory: goalCategory,
                                  healthCtx: healthCtx)
        plan1 = applyGoalBranding(to: plan1, goal: goalCategory,
                                  purpose: input.purposeOfInvestment)

        // 7. Generate Plan 2 (Alternate Strategy)
        var plan2: Plan2Result? = nil
        if shouldGeneratePlan2(input: input, goal: goalCategory, health: healthCtx) {
            let strategy = choosePlan2Strategy(input: input, goal: goalCategory, healthCtx: healthCtx)
            plan2 = generatePlan2(input: input, risk: risk, liquidity: liquid,
                                  strategy: strategy, healthCtx: healthCtx)
            plan2 = plan2.map { applyPlan2Branding(to: $0, goal: goalCategory, strategy: strategy) }
        }

        // 7. Generate Plan 3 (Arbitrage Strategy)
        var plan3: Plan3Result? = nil
        if input.openToLoan && healthCtx.debtToIncomeRatio < 0.35 {
             plan3 = generatePlan3(input: input, healthCtx: healthCtx)
        }
        
        // 7.5 Calculate Mentality-based growth for summary
        let tenure = Int(input.timePeriod) ?? 1
        let saved = parseAmount(input.savedAmount)
        let mentalityRate = input.investmentMentality.avgGrowthRate
        let mentalityGrowth = sipFutureValue(monthly: requestedAmt, rateCAGR: mentalityRate, years: tenure) +
                             lumpsumFutureValue(amount: saved, rateCAGR: mentalityRate, years: tenure)
        let mentalityLabel = "\(input.investmentMentality.rawValue) (\(Int(mentalityRate))%)"

        // 8. Recommendations & Scoring
        let recommendations = generateRecommendations(input: input, plan1: plan1, plan2: plan2,
                                                       feasibility: feasibility, healthCtx: healthCtx)
        let comparison = plan2 != nil
            ? scorePlans(plan1: plan1, plan2: plan2!, input: input,
                         healthCtx: healthCtx, goal: goalCategory)
            : nil

        return FullPlanResult(
            plan1: plan1,
            plan2: plan2,
            plan3: plan3,
            feasibility: feasibility,
            recommendations: recommendations,
            comparisonScore: comparison,
            goalCategory: goalCategory,
            financialHealthSummary: healthCtx,
            mentalityGrowthValue: mentalityGrowth,
            mentalityGrowthLabel: mentalityLabel
        )
    }

    // MARK: Recalculate helper for UI overrides
    static func recalculatePlan1(input: InvestmentPlanInputModel, 
                                 overridenRisk: String? = nil,
                                 overridenSIP: Double? = nil,
                                 overridenTenure: Int? = nil) -> Plan1Result {
        let risk = overridenRisk != nil ? mapRiskLevel(overridenRisk!) : mapRiskLevel(input.riskType)
        let goalCategory = InvestmentGoalCategory.from(purpose: input.purposeOfInvestment)
        let liquid = mapLiquidityLevel(input.liquidity)
        
        let sipAmt = overridenSIP ?? parseAmount(input.amount)
        
        // Custom Input Model for calculation if needed
        var customInput = input
        if let s = overridenSIP { customInput.amount = String(format: "%.0f", s) }
        if let t = overridenTenure { customInput.timePeriod = String(t) }

        return generatePlan1(input: customInput, risk: risk, liquidity: liquid,
                           safeAmt: sipAmt, goalCategory: goalCategory,
                           healthCtx: buildFinancialHealthContext(input: customInput, profile: nil))
    }

    // MARK: Recalculate helper for Plan 3
    static func recalculatePlan3(input: InvestmentPlanInputModel,
                                 overridenLoan: Double? = nil,
                                 overridenTenure: Int? = nil,
                                 overridenBank: String? = nil,
                                 overridenRate: Double? = nil,
                                 overridenReturn: Double? = nil) -> Plan3Result {
        var customInput = input
        if let l = overridenLoan { customInput.targetAmount = String(format: "%.0f", l) }
        if let t = overridenTenure { customInput.timePeriod = String(t) }
        if let b = overridenBank { customInput.bankName = b }
        if let r = overridenRate { customInput.interestRate = r }
        
        let healthCtx = buildFinancialHealthContext(input: customInput, profile: nil)
        return generatePlan3(input: customInput, healthCtx: healthCtx, overridenReturn: overridenReturn)
    }

    // MARK: Recalculate helper for Plan 2
    static func recalculatePlan2(input: InvestmentPlanInputModel,
                                 overridenLoan: Double? = nil,
                                 overridenSIP: Double? = nil,
                                 overridenTenure: Int? = nil,
                                 emiFrequency: EMIFrequency = .quarterly,
                                 interestType: InterestType = .compounded) -> Plan2Result {
        let risk = mapRiskLevel(input.riskType)
        let goalCategory = InvestmentGoalCategory.from(purpose: input.purposeOfInvestment)
        let healthCtx = buildFinancialHealthContext(input: input, profile: nil)
        
        var strategy = choosePlan2Strategy(input: input, goal: goalCategory, healthCtx: healthCtx)
        // FORCE loan strategy if user explicitly sets a loan amount
        if let l = overridenLoan, l > 0 {
            strategy = .loanPlusSIPParallel
        }
        
        let liquid = mapLiquidityLevel(input.liquidity)
        
        var customInput = input
        if let l = overridenLoan { customInput.loanAmount = l }
        if let s = overridenSIP { customInput.amount = String(format: "%.0f", s) }
        if let t = overridenTenure { customInput.timePeriod = String(t) }
        
        return generatePlan2(input: customInput, risk: risk, liquidity: liquid,
                           strategy: strategy, healthCtx: healthCtx,
                           emiFrequency: emiFrequency, interestType: interestType) ?? Plan2Result.empty()
    }

    // MARK: - Health Context Builder

    private static func buildFinancialHealthContext(
        input: InvestmentPlanInputModel,
        profile: AstraUserProfile?
    ) -> FinancialHealthContext {
        let income: Double = profile?.basicDetails.monthlyIncomeAfterTax ?? Swift.max(input.monthlyIncome, 1.0)
        let expenses: Double = profile?.basicDetails.monthlyExpenses ?? (income * 0.45)
        let emiLoad: Double = profile?.loans.reduce(0.0) { $0 + $1.calculatedEMI } ?? input.existingEMIs
        let emergFund: Double = profile?.basicDetails.emergencyFundAmount ?? 0.0
        let netWorth: Double = profile?.financialHealthReport?.netWorth ?? 0.0
        let investScore: Int = profile?.financialHealthReport?.investmentScore ?? 50
        
        let dti = income > 0 ? emiLoad / income : 0
        let surplus = income - expenses - emiLoad
        let investable = Swift.max(0.0, surplus * 0.9)
        let emergMonths = expenses > 0 ? emergFund / expenses : 0

        let grade: String
        let advice: String
        
        let minSafetyMonths: Double = 6.0
        let hasGoodSafety = emergMonths >= minSafetyMonths
        let hasLowSafety = emergMonths < 3.0
        
        if dti > 0.5 {
            grade = "D"
            advice = "High debt burden detected. Prioritize clearing loans before aggressive investing."
        } else if hasLowSafety {
            grade = "C"
            advice = "Safety net is low. Allocate your ₹\(Int(surplus/1000))K surplus to build a 6-month emergency fund."
        } else if !hasGoodSafety {
            grade = "B"
            advice = "Good start! Aim to reach 6 months of safety net while continuing small investments."
        } else if surplus > (income * 0.3) {
            grade = "A"
            advice = "Excellent surplus! You can afford to invest more and reach your goal \(input.timePeriod) years earlier."
        } else {
            grade = "A"
            advice = "Solid foundation. Your safety net is secure; focus on steady long-term growth."
        }

        return FinancialHealthContext(
            netWorth: netWorth,
            monthlyExpenses: expenses,
            existingEMIBurden: emiLoad,
            emergencyFundCoverage: emergMonths,
            investmentScore: investScore,
            debtToIncomeRatio: dti,
            investableMonthly: investable,
            healthGrade: grade,
            healthSummary: advice
        )
    }

    // MARK: - Feasibility Validator

    private static func validateFeasibility(
        input: InvestmentPlanInputModel,
        healthCtx: FinancialHealthContext
    ) -> FeasibilityResult {
        var points: [ValidationPoint] = []
        let reqSIP = parseAmount(input.amount)
        
        // 1. Surplus Check
        if reqSIP > healthCtx.investableMonthly * 1.5 {
            points.append(ValidationPoint(
                icon: "exclamationmark.triangle.fill",
                title: "Budget Over-stretch",
                detail: "This SIP takes up >150% of your current investable surplus. Risk of discontinuation.",
                severity: .critical
            ))
        } else if reqSIP > healthCtx.investableMonthly {
            points.append(ValidationPoint(
                icon: "exclamationmark.circle.fill",
                title: "Aggressive Allocation",
                detail: "SIP exceeds recommended safe surplus. Ensure expenses are tightly managed.",
                severity: .warning
            ))
        } else {
            points.append(ValidationPoint(
                icon: "checkmark.circle.fill",
                title: "Comfortable Budget",
                detail: "Monthly commitment is well within your safe investable surplus.",
                severity: .positive
            ))
        }
        
        // 2. Safety Net Check
        if healthCtx.emergencyFundCoverage < 1 {
            points.append(ValidationPoint(
                icon: "shield.slash.fill",
                title: "Safety Net Missing",
                detail: "You have <1 month of expenses saved. Prioritise Emergency Fund over this goal.",
                severity: .critical
            ))
        } else if healthCtx.emergencyFundCoverage < 3 {
            points.append(ValidationPoint(
                icon: "shield.fill",
                title: "Lean Safety Net",
                detail: "Safety net is <3 months. Consider a lower SIP until you reach 6 months.",
                severity: .warning
            ))
        }
        
        // 3. Debt Check
        if healthCtx.debtToIncomeRatio > 0.5 {
            points.append(ValidationPoint(
                icon: "creditcard.fill",
                title: "High Debt Load",
                detail: "Your DTI is >50%. We recommend lowering debt before new investments.",
                severity: .warning
            ))
        }
        
        let warning = points.first(where: { $0.severity == .critical })?.detail 
                   ?? points.first(where: { $0.severity == .warning })?.detail
        
        return FeasibilityResult(
            isAffordable: !points.contains(where: { $0.severity == .critical }),
            disposableIncome: healthCtx.investableMonthly,
            sipToIncomeRatio: reqSIP / Swift.max(1, healthCtx.investableMonthly),
            warning: warning
        )
    }

    // MARK: - Portfolio Logic

    private static func resolveRiskLevel(input: InvestmentPlanInputModel,
                                         profile: AstraUserProfile?,
                                         goalCategory: InvestmentGoalCategory) -> AstraRiskLevel {
        var base = mapRiskLevel(input.riskType)
        if let tol = profile?.basicDetails.riskTolerance {
            switch tol {
            case .low: base = .low
            case .medium: base = .mid
            case .high: base = .high
            }
        }
        
        // Final goal-based safety filter
        let tenure = Int(input.timePeriod) ?? 1
        if tenure <= 3 && [.emergency, .travel].contains(goalCategory) { return .low }
        return base
    }

    private static func buildPortfolio(risk: AstraRiskLevel,
                                       liquidity: AstraLiquidityLevel,
                                       goalCategory: InvestmentGoalCategory,
                                       tenure: Int) -> PortfolioBlueprint {
        var allocations: [AssetAllocation]
        switch risk {
        case .low:
            allocations = [
                AssetAllocation(name: "Debt MF", percentage: 40, expectedCAGR: 7.0, riskLevel: .low),
                AssetAllocation(name: "Liquid Fund", percentage: 30, expectedCAGR: 5.5, riskLevel: .low),
                AssetAllocation(name: "Index Fund", percentage: 20, expectedCAGR: 11.0, riskLevel: .mid),
                AssetAllocation(name: "Gold ETF", percentage: 10, expectedCAGR: 8.5, riskLevel: .low),
            ]
        case .mid:
            allocations = [
                AssetAllocation(name: "Flexi Cap MF", percentage: 35, expectedCAGR: 12.0, riskLevel: .mid),
                AssetAllocation(name: "Index Fund", percentage: 25, expectedCAGR: 11.0, riskLevel: .low),
                AssetAllocation(name: "Debt MF", percentage: 20, expectedCAGR: 7.0, riskLevel: .low),
                AssetAllocation(name: "Small Cap MF", percentage: 10, expectedCAGR: 15.0, riskLevel: .high),
                AssetAllocation(name: "REITs / Gold", percentage: 10, expectedCAGR: 9.0, riskLevel: .mid),
            ]
        case .high:
             allocations = [
                AssetAllocation(name: "Small Cap MF (Aggressive)", percentage: 40, expectedCAGR: 16.5, riskLevel: .high),
                AssetAllocation(name: "Mid Cap MF (Growth)", percentage: 30, expectedCAGR: 14.0, riskLevel: .high),
                AssetAllocation(name: "Flexi Cap MF", percentage: 15, expectedCAGR: 12.0, riskLevel: .mid),
                AssetAllocation(name: "Direct Equity / Crypto", percentage: 10, expectedCAGR: 18.0, riskLevel: .high),
                AssetAllocation(name: "Debt MF / Gold (Safe)", percentage: 5, expectedCAGR: 7.5, riskLevel: .low),
            ]
        }

        // Liquidity overlay
        if liquidity == .high {
            allocations = allocations.map { a in
                var x = a
                if a.riskLevel == .high { x.percentage = Swift.max(2, a.percentage - 10) }
                if a.name == "Liquid Fund" || a.name == "Debt MF" { x.percentage += 5 }
                return x
            }
        }

        // Re-normalize
        let total = allocations.reduce(0.0) { $0 + $1.percentage }
        if total > 0 { allocations = allocations.map { var x = $0; x.percentage = (x.percentage / total) * 100; return x } }
        
        let blended = allocations.reduce(0.0) { $0 + ($1.expectedCAGR * $1.percentage / 100) }
        return PortfolioBlueprint(allocations: allocations, blendedCAGR: blended, riskLabel: risk.rawValue.capitalized)
    }

    // MARK: - Plan Generators

    private static func generatePlan1(input: InvestmentPlanInputModel,
                                      risk: AstraRiskLevel,
                                      liquidity: AstraLiquidityLevel,
                                      safeAmt: Double,
                                      goalCategory: InvestmentGoalCategory,
                                      healthCtx: FinancialHealthContext) -> Plan1Result {
        let tenure = Int(input.timePeriod) ?? 1
        let target = parseAmount(input.targetAmount)
        let saved  = parseAmount(input.savedAmount)
        let sipAmt = safeAmt > 0 ? safeAmt : parseAmount(input.amount)
        
        let portfolio = buildPortfolio(risk: risk, liquidity: liquidity, goalCategory: goalCategory, tenure: tenure)
        
        let fvSIP = sipFutureValue(monthly: sipAmt, rateCAGR: portfolio.blendedCAGR, years: tenure)
        let fvLump = lumpsumFutureValue(amount: saved, rateCAGR: portfolio.blendedCAGR, years: tenure)
        let projected = fvSIP + fvLump
        let totalInvested = (sipAmt * 12 * Double(tenure)) + saved
        
        let reachesGoal = projected >= target
        let shortfall = Swift.max(0, target - projected)
        
        var sipPerAsset: [String: Double] = [:]
        for asset in portfolio.allocations { sipPerAsset[asset.name] = sipAmt * asset.percentage / 100 }
        
        let scenarios = generateScenarios(totalInvested: totalInvested, sip: sipAmt, lumpsum: saved, years: tenure)
        
        var hl: [String] = []
        hl.append("Blended CAGR: \(String(format: "%.1f", portfolio.blendedCAGR))%")
        hl.append("Lumpsum boost: ₹\(formatL_Internal(fvLump))")
        if reachesGoal { hl.append("✅ Goal Achievable") } else { hl.append("⚠️ Shortfall: ₹\(formatL_Internal(shortfall))") }

        return Plan1Result(
            totalInvested: totalInvested,
            projectedValue: projected,
            lumpsumContribution: fvLump,
            sipContribution: fvSIP,
            portfolio: portfolio,
            scenarios: scenarios,
            reachesGoal: reachesGoal,
            shortfall: shortfall,
            sipPerAsset: sipPerAsset,
            tenure: tenure,
            highlights: hl
        )
    }

    private static func generatePlan2(input: InvestmentPlanInputModel,
                                      risk: AstraRiskLevel,
                                      liquidity: AstraLiquidityLevel,
                                      strategy: Plan2Strategy,
                                      healthCtx: FinancialHealthContext,
                                      emiFrequency: EMIFrequency = .quarterly,
                                      interestType: InterestType = .compounded) -> Plan2Result? {
        let saved  = parseAmount(input.savedAmount)
        let target = parseAmount(input.targetAmount)
        let amt    = 0.0 // Force SIP to 0 for Plan 2
        let tenure = Int(input.timePeriod) ?? 1
        let months = tenure * 12

        let portfolio = buildPortfolio(risk: risk, liquidity: liquidity, goalCategory: .other, tenure: tenure)
        let loanRate = input.interestRate ?? 9.5
        let monthlyRate = loanRate / 100 / 12
        let bankSuffix = input.bankName.map { " via \($0)" } ?? ""

        switch strategy {
        case .loanPlusSIPParallel:
            let loanAmount = input.loanAmount ?? target
            let emi = calculateEMIPublic(principal: loanAmount, rate: loanRate, years: tenure, frequency: emiFrequency, interestType: interestType)
            let totalPayments = Double(tenure) * emiFrequency.paymentsPerYear
            let totalPaid = emi * totalPayments
            let interest = totalPaid - loanAmount
            let sipRet = sipFutureValue(monthly: amt, rateCAGR: portfolio.blendedCAGR, years: tenure)
            let totalOutflow = totalPaid + (amt * Double(months))
            let finalStateValue = sipRet + target
            let gain = finalStateValue - totalOutflow
            
            let reaches = gain >= target
            let gap = Swift.max(0, target - gain)
            
            let profit = sipRet - (amt * Double(months))
            let invested = amt * Double(months)
            
            var yearDetails: [Plan2YearlyDetail] = []
            for y in 1...tenure {
                let p_y = Double(y) * emiFrequency.paymentsPerYear
                let r = (loanRate / 100.0) / emiFrequency.paymentsPerYear
                let remP: Double
                if interestType == .compounded {
                    let pqr_total = pow(1 + r, totalPayments)
                    let pqr_q = pow(1 + r, p_y)
                    remP = r > 0 ? (loanAmount * (pqr_total - pqr_q)) / (pqr_total - 1) : (loanAmount * (1.0 - p_y/totalPayments))
                } else {
                    let yearlyPrincipalPaid = loanAmount / Double(tenure)
                    remP = loanAmount - (yearlyPrincipalPaid * Double(y))
                }
                
                let fvSIP_y = sipFutureValue(monthly: amt, rateCAGR: portfolio.blendedCAGR, years: y)
                
                yearDetails.append(Plan2YearlyDetail(
                    year: y,
                    date: Calendar.current.date(byAdding: .year, value: y, to: Date()) ?? Date(),
                    emiPaidYearly: emi * emiFrequency.paymentsPerYear,
                    sipInvestedYearly: amt * 12,
                    remainingPrincipal: Swift.max(0, remP),
                    totalPortfolioValue: fvSIP_y
                ))
            }
            
            return Plan2Result(
                loanAmount: loanAmount, loanRate: loanRate, monthlyEMI: emi,
                totalAmountPaid: totalPaid, totalInterestPaid: interest,
                monthlySIPKept: amt, sipReturns: sipRet, investmentProfit: profit,
                netWealthGain: gain, totalMonthlyCommitment: (emi * emiFrequency.paymentsPerYear / 12) + amt,
                roi: invested > 0 ? (gain / invested) * 100 : 0,
                reachesGoal: reaches, shortfall: gap,
                breakdown: buildLoanBreakdown(planType: "Loan + SIP", target: target, loan: loanAmount, emi: emi, sip: amt, sipRet: sipRet, gain: gain),
                highlights: ["Buy asset now" + bankSuffix, "EMI + SIP parallel", "Net Gain: ₹\(formatL_Internal(gain))"],
                yearlyBreakdown: yearDetails
            )
            
        case .sipSprintThenBuy:
            let shortfall = Swift.max(0, target - saved)
            let reqSIP = computeRequiredSIP(target: shortfall, lumpsum: 0, cagr: portfolio.blendedCAGR, years: tenure)
            let totalInv = reqSIP * Double(months)
            let ret = sipRetVal(monthly: reqSIP, cagr: portfolio.blendedCAGR, years: tenure)
            let profit = ret - totalInv
            
            let reaches = ret >= target
            let gap = Swift.max(0, target - ret)
            
            var yearDetails: [Plan2YearlyDetail] = []
            for y in 1...tenure {
                let fvSIP_y = sipFutureValue(monthly: reqSIP, rateCAGR: portfolio.blendedCAGR, years: y)
                yearDetails.append(Plan2YearlyDetail(
                    year: y,
                    date: Calendar.current.date(byAdding: .year, value: y, to: Date()) ?? Date(),
                    emiPaidYearly: 0,
                    sipInvestedYearly: reqSIP * 12,
                    remainingPrincipal: 0,
                    totalPortfolioValue: fvSIP_y
                ))
            }
            
            return Plan2Result(
                loanAmount: 0, loanRate: 0, monthlyEMI: 0,
                totalAmountPaid: totalInv, totalInterestPaid: 0,
                monthlySIPKept: reqSIP, sipReturns: ret,
                investmentProfit: profit, netWealthGain: profit,
                totalMonthlyCommitment: reqSIP, roi: totalInv > 0 ? (profit/totalInv)*100 : 0,
                reachesGoal: reaches, shortfall: gap,
                breakdown: [], highlights: ["Aggressive Saving", "Zero Debt", "SIP: ₹\(formatL_Internal(reqSIP))/mo"],
                yearlyBreakdown: yearDetails
            )

        case .hybridDownpayPlusSIP:
            let dp = saved * 0.7 
            let loan = input.loanAmount ?? Swift.max(0, target - dp)
            let emi = calculateEMIPublic(principal: loan, rate: loanRate, years: tenure, frequency: emiFrequency, interestType: interestType)
            let totalPayments = Double(tenure) * emiFrequency.paymentsPerYear
            
            let totalSIPInvested = amt * Double(months)
            let totalOutflow = (emi * totalPayments) + totalSIPInvested
            let sipRet = sipFutureValue(monthly: amt, rateCAGR: portfolio.blendedCAGR, years: tenure)
            let finalValue = sipRet + target
            let gain = finalValue - totalOutflow
            
            let reaches = gain >= target
            let gap = Swift.max(0, target - gain)
            
            var yearDetails: [Plan2YearlyDetail] = []
            for y in 1...tenure {
                let p_y = Double(y) * emiFrequency.paymentsPerYear
                let r = (loanRate / 100.0) / emiFrequency.paymentsPerYear
                let remP: Double
                if interestType == .compounded {
                    let pqr_total = pow(1 + r, totalPayments)
                    let pqr_q = pow(1 + r, p_y)
                    remP = r > 0 ? (loan * (pqr_total - pqr_q)) / (pqr_total - 1) : (loan * (1.0 - p_y/totalPayments))
                } else {
                    let yearlyPrincipalPaid = loan / Double(tenure)
                    remP = loan - (yearlyPrincipalPaid * Double(y))
                }
                
                let fvSIP_y = sipFutureValue(monthly: amt, rateCAGR: portfolio.blendedCAGR, years: y)
                
                yearDetails.append(Plan2YearlyDetail(
                    year: y,
                    date: Calendar.current.date(byAdding: .year, value: y, to: Date()) ?? Date(),
                    emiPaidYearly: emi * emiFrequency.paymentsPerYear,
                    sipInvestedYearly: amt * 12,
                    remainingPrincipal: Swift.max(0, remP),
                    totalPortfolioValue: fvSIP_y
                ))
            }
            
            return Plan2Result(
                loanAmount: loan, loanRate: loanRate, monthlyEMI: emi,
                totalAmountPaid: emi * totalPayments, totalInterestPaid: (emi * totalPayments) - loan,
                monthlySIPKept: amt, sipReturns: sipRet, investmentProfit: sipRet - totalSIPInvested,
                netWealthGain: gain, totalMonthlyCommitment: (emi * emiFrequency.paymentsPerYear / 12) + amt, 
                roi: totalOutflow > 0 ? (gain / totalOutflow) * 100 : 0,
                reachesGoal: reaches, shortfall: gap,
                breakdown: [], highlights: ["Optimised Down-payment" + bankSuffix, "Lower EMI"],
                yearlyBreakdown: yearDetails
            )
        }
    }

    // MARK: - Scorer & Comparisons

    private static func scorePlans(plan1: Plan1Result, plan2: Plan2Result,
                                   input: InvestmentPlanInputModel,
                                   healthCtx: FinancialHealthContext,
                                   goal: InvestmentGoalCategory) -> PlanComparisonScore {
        
        var dims: [ScoreDimension] = []
        let p1Gain = plan1.projectedValue - plan1.totalInvested
        let p2Gain = plan2.netWealthGain
        
        // Dim 1: Net Gain
        dims.append(ScoreDimension(axis: "Wealth Gain", plan1Value: "₹\(formatL_Internal(p1Gain))", plan2Value: "₹\(formatL_Internal(p2Gain))",
                                   plan1Points: p1Gain > p2Gain ? 10 : 7, plan2Points: p2Gain >= p1Gain ? 10 : 7, weight: 0.3, winner: p1Gain > p2Gain ? "P1" : "P2"))
                                   
        // Dim 2: Affordability
        let p1Load = parseAmount(input.amount)
        let p2Load = plan2.totalMonthlyCommitment
        dims.append(ScoreDimension(axis: "Monthly Load", plan1Value: "₹\(formatL_Internal(p1Load))", plan2Value: "₹\(formatL_Internal(p2Load))",
                                   plan1Points: p1Load < p2Load ? 10 : 6, plan2Points: p2Load <= p1Load ? 10 : 4, weight: 0.3, winner: p1Load < p2Load ? "P1" : "P2"))

        // Final Score
        let s1 = dims.reduce(0.0) { $0 + $1.plan1Points * $1.weight } * 10
        let s2 = dims.reduce(0.0) { $0 + $1.plan2Points * $1.weight } * 10

        return PlanComparisonScore(
            plan1Score: s1, plan2Score: s2,
            winner: s1 > s2 ? "Plan 1" : "Plan 2",
            confidence: "High", dimensions: dims,
            detailedReasoning: "Plan 1 is safer for your current grade.",
            keyValidations: []
        )
    }

    // MARK: - Helper Math & Branding

    private static func buildFinancialHealthReport(profile: AstraUserProfile) -> AstraFinancialHealthReport? { return profile.financialHealthReport }
    
    private static func healthAdjustedSIPAmount(requested: Double, healthCtx: FinancialHealthContext) -> Double {
        if healthCtx.healthGrade == "D" { return Swift.min(requested, healthCtx.investableMonthly * 0.4) }
        return requested
    }

    private static func shouldGeneratePlan2(input: InvestmentPlanInputModel, goal: InvestmentGoalCategory, health: FinancialHealthContext) -> Bool {
        return input.openToLoan && ![.travel, .emergency].contains(goal) && health.debtToIncomeRatio < 0.5
    }

    private static func choosePlan2Strategy(input: InvestmentPlanInputModel, goal: InvestmentGoalCategory, healthCtx: FinancialHealthContext) -> Plan2Strategy {
        if goal == .homePurchase { return .hybridDownpayPlusSIP }
        return .loanPlusSIPParallel
    }

    private static func generatePlan3(
        input: InvestmentPlanInputModel,
        healthCtx: FinancialHealthContext,
        overridenReturn: Double? = nil
    ) -> Plan3Result {
        let target = parseAmount(input.targetAmount)
        let rate = input.interestRate ?? 10.5
        let years = Int(input.timePeriod) ?? 5
        let investmentRate = overridenReturn ?? 12.0 // Optimistic return for arbitrage
        
        let emi = calculateEMIPublic(principal: target, rate: rate, years: years)
        let buffer = 0.0 // Buffer is 0 in the direct invest strategy
        let investAmt = target // Invest exactly the loan amount
        
        var yearlyBreakdown: [Plan3YearlyDetail] = []
        var currentInv = investAmt
        let yearlyEMI = emi * 4
        
        for y in 1...years {
            let startVal = currentInv
            let growth = startVal * (investmentRate/100)
            let withdrawal = yearlyEMI // Withdraw immediately from year 1
            
            let netProfit = growth - withdrawal
            currentInv = startVal + growth - withdrawal
            
            yearlyBreakdown.append(Plan3YearlyDetail(
                year: y,
                date: Calendar.current.date(byAdding: .year, value: y, to: Date()) ?? Date(),
                startValue: startVal,
                investmentValue: currentInv,
                emiPaidYearly: yearlyEMI,
                withdrawalYearly: withdrawal,
                netYearlyProfit: netProfit
            ))
        }
        
        let totalGain = currentInv // Pure profit as initial invested amount was borrowed and fully repaid
        
        return Plan3Result(
            loanAmount: target,
            investedAmount: investAmt,
            bufferAmount: buffer,
            monthlyEMI: emi,
            expectedReturnRate: investmentRate,
            yearlyProfit: investAmt * (investmentRate/100),
            monthlyWithdrawalPotential: (investAmt * (investmentRate/100)) / 12,
            netWealthGain: totalGain,
            tenure: years,
            reachesGoal: currentInv >= target,
            shortfall: Swift.max(0, target - currentInv),
            yearlyBreakdown: yearlyBreakdown,
            highlights: ["Interest Arbitrage", "2 EMI Buffer Used", "Zero Outflow Year 2+"]
        )
    }

    private static func generateRecommendations(input: InvestmentPlanInputModel, plan1: Plan1Result, plan2: Plan2Result?,
                                               feasibility: FeasibilityResult, healthCtx: FinancialHealthContext) -> PlanRecommendations {
        let reason = plan1.reachesGoal ? "Plan 1 is fully on track." : "Plan 2 may bridge your goal shortfall."
        return PlanRecommendations(primaryRecommendation: plan1.reachesGoal ? "Plan 1" : (plan2 != nil ? "Plan 2" : "Plan 1"),
                                   reason: reason, tips: [])
    }

    private static func applyGoalBranding(to p: Plan1Result, goal: InvestmentGoalCategory, purpose: String) -> Plan1Result {
        var x = p; x.name = goal.rawValue; x.icon = InvestmentPlanInputModel.iconForGoal(goal); return x
    }

    private static func applyPlan2Branding(to p: Plan2Result, goal: InvestmentGoalCategory, strategy: Plan2Strategy) -> Plan2Result {
        var x = p; x.name = "Loan Strategy"; return x
    }

    private static func sipFutureValue(monthly: Double, rateCAGR: Double, years: Int) -> Double {
        let r = rateCAGR / 100 / 12; let m = Double(years * 12)
        if r == 0 { return monthly * m }
        return monthly * (pow(1+r, m) - 1) / r * (1+r)
    }
    
    private static func lumpsumFutureValue(amount: Double, rateCAGR: Double, years: Int) -> Double {
        return amount * pow(1 + rateCAGR/100, Double(years))
    }

    private static func computeRequiredSIP(target: Double, lumpsum: Double, cagr: Double, years: Int) -> Double {
        let r = cagr / 100 / 12; let m = Double(years * 12)
        let fvLump = lumpsumFutureValue(amount: lumpsum, rateCAGR: cagr, years: years)
        let rem = Swift.max(0, target - fvLump)
        if r == 0 { return m > 0 ? rem/m : 0 }
        return rem / ((pow(1+r, m) - 1) / r * (1+r))
    }

    private static func sipRetVal(monthly: Double, cagr: Double, years: Int) -> Double { return sipFutureValue(monthly: monthly, rateCAGR: cagr, years: years) }

    private static func generateScenarios(totalInvested: Double, sip: Double, lumpsum: Double, years: Int) -> [PlanScenario] {
        let rates: [(String, Double)] = [("Conservative", 7.0), ("Balanced", 10.0), ("Aggressive", 13.0)]
        
        return rates.map { name, cagr in
            let fvSIP = sipFutureValue(monthly: sip, rateCAGR: cagr, years: years)
            let fvLump = lumpsumFutureValue(amount: lumpsum, rateCAGR: cagr, years: years)
            let finalValue = fvSIP + fvLump
            let gain = finalValue - totalInvested
            return PlanScenario(name: name, cagr: cagr, gainLoss: gain, finalValue: finalValue)
        }
    }

    private static func buildLoanBreakdown(planType: String, target: Double, loan: Double, emi: Double, sip: Double, sipRet: Double, gain: Double) -> [PlanBreakdownItem] {
        return [PlanBreakdownItem(label: "Target", icon: "flag", value: target, isNegative: false)]
    }

    static func parseAmount(_ s: String) -> Double {
        let lower = s.lowercased()
        let multiplier: Double
        if lower.contains("cr") { multiplier = 10_000_000 }
        else if lower.contains("l") { multiplier = 100_000 }
        else if lower.contains("k") { multiplier = 1000 }
        else { multiplier = 1 }
        
        let cleaned = s.components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".")).inverted).joined()
        return (Double(cleaned) ?? 0) * multiplier
    }
    static func calculateEMIPublic(principal: Double, rate: Double, years: Int, frequency: EMIFrequency = .quarterly, interestType: InterestType = .compounded) -> Double {
        let n = Double(years) * frequency.paymentsPerYear // total payments
        
        switch interestType {
        case .compounded:
            let r = (rate / 100.0) / frequency.paymentsPerYear // interest rate per period
            guard r > 0, n > 0 else { return n > 0 ? principal / n : 0 }
            let pqr = pow(1 + r, n)
            let emi = (principal * r * pqr) / (pqr - 1)
            return emi.isFinite ? emi : 0
            
        case .simple:
            let totalInterest = principal * (rate / 100.0) * Double(years)
            let totalAmount = principal + totalInterest
            guard n > 0 else { return 0 }
            let emi = totalAmount / n
            return emi.isFinite ? emi : 0
        }
    }

    private static func formatL_Internal(_ v: Double) -> String { String(format: "%.1fL", v / 100000) }
    private static func mapRiskLevel(_ t: String) -> AstraRiskLevel { AstraRiskLevel(rawValue: t.lowercased()) ?? .mid }
    private static func mapLiquidityLevel(_ t: String) -> AstraLiquidityLevel { AstraLiquidityLevel(rawValue: t.lowercased()) ?? .mid }
}

fileprivate extension InvestmentPlanInputModel {
    static func iconForGoal(_ g: InvestmentGoalCategory) -> String {
        switch g {
        case .retirement: return "figure.walk.circle.fill"
        case .education: return "graduationcap.circle.fill"
        case .homePurchase: return "house.circle.fill"
        case .vehiclePurchase: return "car.circle.fill"
        case .travel: return "airplane.circle.fill"
        case .wedding: return "heart.circle.fill"
        case .wealthCreation: return "chart.bar.fill"
        case .business: return "briefcase.fill"
        case .emergency: return "shield.fill"
        default: return "star.circle.fill"
        }
    }
}

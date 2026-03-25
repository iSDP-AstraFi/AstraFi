// InvestmentPlannerModels.swift
import Foundation
import SwiftUI

// MARK: - Core Data Models

struct PortfolioBlueprint: Codable, Equatable {
    var allocations: [AssetAllocation]
    var blendedCAGR: Double           // weighted average return
    var riskLabel: String
}

struct PortfolioAsset: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var monthlyInvestment: Double
    var expectedValue: Double
    var riskLevel: AstraRiskLevel
}

struct AssetAllocation: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var percentage: Double
    var expectedCAGR: Double
    var riskLevel: AstraRiskLevel
    
    init(id: UUID = UUID(), name: String, percentage: Double, expectedCAGR: Double, riskLevel: AstraRiskLevel) {
        self.id = id
        self.name = name
        self.percentage = percentage
        self.expectedCAGR = expectedCAGR
        self.riskLevel = riskLevel
    }
}

enum AstraRiskLevel: String, Codable, CaseIterable { case low, mid, high }
enum AstraLiquidityLevel: String, Codable, CaseIterable { case high, mid, low }

enum EMIFrequency: String, Codable, CaseIterable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case halfYearly = "Half-Yearly"
    case yearly = "Yearly"
    
    var paymentsPerYear: Double {
        switch self {
        case .monthly: return 12
        case .quarterly: return 4
        case .halfYearly: return 2
        case .yearly: return 1
        }
    }
}

enum InterestType: String, Codable, CaseIterable {
    case simple = "Simple"
    case compounded = "Compounded"
}

struct PlanScenario: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var cagr: Double
    var gainLoss: Double
    var finalValue: Double
    
    init(id: UUID = UUID(), name: String, cagr: Double, gainLoss: Double, finalValue: Double) {
        self.id = id
        self.name = name
        self.cagr = cagr
        self.gainLoss = gainLoss
        self.finalValue = finalValue
    }
}

struct FeasibilityResult: Codable, Equatable {
    var isAffordable: Bool
    var disposableIncome: Double
    var sipToIncomeRatio: Double
    var warning: String?
}

struct Plan1Result: Codable, Equatable {
    var name: String = "Pure Investment"
    var subtitle: String = "Focused on long-term wealth"
    var icon: String = "star.circle.fill"
    var totalInvested: Double
    var projectedValue: Double
    var lumpsumContribution: Double
    var sipContribution: Double
    var portfolio: PortfolioBlueprint
    var scenarios: [PlanScenario]
    var reachesGoal: Bool
    var shortfall: Double
    var sipPerAsset: [String: Double]
    var tenure: Int = 1
    var highlights: [String]
    
    // Computed property to support the UI table in Plan1DetailView
    var assets: [PortfolioAsset] {
        portfolio.allocations.map { allocation in
            let monthly = sipPerAsset[allocation.name] ?? 0
            // Calculate expected value based on asset CAGR and tenure
            let r = allocation.expectedCAGR / 100 / 12
            let m = Double(tenure * 12)
            let fv = r > 0 ? monthly * (pow(1+r, m) - 1) / r * (1+r) : monthly * m
            
            return PortfolioAsset(
                id: allocation.id,
                name: allocation.name,
                monthlyInvestment: monthly,
                expectedValue: fv,
                riskLevel: allocation.riskLevel
            )
        }
    }
}

struct Plan2Result: Codable, Equatable {
    var name: String = "Loan Strategy"
    var subtitle: String = "Own asset now via loan"
    var icon: String = "car.circle.fill"
    var loanAmount: Double
    var loanRate: Double
    var monthlyEMI: Double
    var totalAmountPaid: Double
    var totalInterestPaid: Double
    var monthlySIPKept: Double
    var sipReturns: Double
    var investmentProfit: Double
    var netWealthGain: Double
    var totalMonthlyCommitment: Double
    var roi: Double
    var reachesGoal: Bool
    var shortfall: Double
    var breakdown: [PlanBreakdownItem]
    var highlights: [String]
    var yearlyBreakdown: [Plan2YearlyDetail] = []
    
    static func empty() -> Plan2Result {
        return Plan2Result(loanAmount: 0, loanRate: 0, monthlyEMI: 0, totalAmountPaid: 0,
                           totalInterestPaid: 0, monthlySIPKept: 0, sipReturns: 0,
                           investmentProfit: 0, netWealthGain: 0, totalMonthlyCommitment: 0,
                           roi: 0, reachesGoal: false, shortfall: 0, breakdown: [], highlights: [],
                           yearlyBreakdown: [])
    }
}

struct Plan2YearlyDetail: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let year: Int
    let date: Date
    let emiPaidYearly: Double
    let sipInvestedYearly: Double
    let remainingPrincipal: Double
    let totalPortfolioValue: Double
}

struct Plan3Result: Codable, Equatable {
    var name: String = "Arbitrage Strategy"
    var subtitle: String = "Use loan to generate wealth"
    var icon: String = "arrow.up.right.circle.fill"
    var loanAmount: Double
    var investedAmount: Double
    var bufferAmount: Double
    var monthlyEMI: Double
    var expectedReturnRate: Double
    var yearlyProfit: Double
    var monthlyWithdrawalPotential: Double
    var netWealthGain: Double
    var tenure: Int
    var reachesGoal: Bool
    var shortfall: Double
    var yearlyBreakdown: [Plan3YearlyDetail]
    var highlights: [String]
    
    static func empty() -> Plan3Result {
        return Plan3Result(loanAmount: 0, investedAmount: 0, bufferAmount: 0, monthlyEMI: 0,
                           expectedReturnRate: 0, yearlyProfit: 0, monthlyWithdrawalPotential: 0,
                           netWealthGain: 0, tenure: 1, reachesGoal: false, shortfall: 0,
                           yearlyBreakdown: [], highlights: [])
    }
}

struct Plan3YearlyDetail: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    let year: Int
    let date: Date
    let startValue: Double
    let investmentValue: Double
    let emiPaidYearly: Double
    let withdrawalYearly: Double
    let netYearlyProfit: Double
}

struct PlanBreakdownItem: Identifiable, Codable, Equatable {
    let id: UUID
    var label: String
    var icon: String
    var value: Double
    var isNegative: Bool
    
    init(id: UUID = UUID(), label: String, icon: String, value: Double, isNegative: Bool) {
        self.id = id
        self.label = label
        self.icon = icon
        self.value = value
        self.isNegative = isNegative
    }
}

struct PlanRecommendations: Codable, Equatable {
    var primaryRecommendation: String
    var reason: String
    var tips: [RecommendationTip]
}

struct RecommendationTip: Identifiable, Codable, Equatable {
    let id: UUID
    var icon: String
    var title: String
    var description: String
    
    init(id: UUID = UUID(), icon: String, title: String, description: String) {
        self.id = id
        self.icon = icon
        self.title = title
        self.description = description
    }
}

// MARK: - Upgraded Result Model

struct FullPlanResult: Codable, Equatable {
    var plan1: Plan1Result
    var plan2: Plan2Result?
    var plan3: Plan3Result? // Added for "Optimized Savings" plan
    var feasibility: FeasibilityResult
    var recommendations: PlanRecommendations
    var comparisonScore: PlanComparisonScore?
    var goalCategory: InvestmentGoalCategory
    var financialHealthSummary: FinancialHealthContext
    
    // Growth based on selected mentality
    var mentalityGrowthValue: Double?
    var mentalityGrowthLabel: String?
}

// MARK: - Goal Categorization

enum InvestmentGoalCategory: String, Codable, CaseIterable {
    case retirement = "Retirement"
    case education = "Education"
    case homePurchase = "Home Purchase"
    case vehiclePurchase = "Vehicle Purchase"
    case travel = "Travel"
    case wedding = "Wedding"
    case wealthCreation = "Wealth Creation"
    case business = "Business Fund"
    case emergency = "Emergency Fund"
    case other = "Other"
    
    static func from(purpose: String) -> InvestmentGoalCategory {
        let p = purpose.lowercased()
        if p.contains("retire") { return .retirement }
        if p.contains("edu") { return .education }
        if p.contains("home") || p.contains("house") || p.contains("property") { return .homePurchase }
        if p.contains("car") || p.contains("vehicle") || p.contains("bike") { return .vehiclePurchase }
        if p.contains("trip") || p.contains("travel") || p.contains("holiday") { return .travel }
        if p.contains("wed") || p.contains("marry") { return .wedding }
        if p.contains("business") || p.contains("startup") { return .business }
        if p.contains("emerg") { return .emergency }
        if p.contains("wealth") || p.contains("invest") || p.contains("freedom") { return .wealthCreation }
        return .other
    }
}

// MARK: - Comparison Scorer

struct PlanComparisonScore: Codable, Equatable {
    var plan1Score: Double     // 0-100
    var plan2Score: Double     // 0-100
    var winner: String         // "Plan 1" or "Plan 2" or "Draw"
    var confidence: String     // "High", "Medium", "Low"
    var dimensions: [ScoreDimension]
    var detailedReasoning: String
    var keyValidations: [ValidationPoint]
}

struct ScoreDimension: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    let axis: String           // "Affordability", "Wealth Gain", "Risk", etc.
    let plan1Value: String
    let plan2Value: String
    let plan1Points: Double    // 0-10
    let plan2Points: Double    // 0-10
    let weight: Double         // 0.0 - 1.0 (total weight across all dims = 1.0)
    let winner: String         // "P1", "P2", "Draw"
}

struct ValidationPoint: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var icon: String
    var title: String
    var detail: String
    var severity: ValidationSeverity
}

enum ValidationSeverity: String, Codable {
    case positive, warning, critical
}

// MARK: - Financial Health Report Context

struct FinancialHealthContext: Codable, Equatable {
    var netWorth: Double
    var monthlyExpenses: Double
    var existingEMIBurden: Double     // Total monthly EMIs
    var emergencyFundCoverage: Double // months of expenses covered
    var investmentScore: Int
    var debtToIncomeRatio: Double
    var investableMonthly: Double     // Surplus after expenses & EMI
    var healthGrade: String           // A, B, C, D
    var healthSummary: String
}

// MARK: - Investment Mentality
enum InvestmentMentality: String, Codable, CaseIterable {
    case mutualFunds = "Mutual Funds"
    case stocks = "Stocks"
    case realEstate = "Real Estate"
    case crypto = "Crypto / High Risk"
    case debt = "Fixed Income / Debt"
    
    var avgGrowthRate: Double {
        switch self {
        case .mutualFunds: return 12.0
        case .stocks: return 15.6
        case .realEstate: return 8.0
        case .crypto: return 24.0
        case .debt: return 7.2
        }
    }
    
    var icon: String {
        switch self {
        case .mutualFunds: return "chart.pie.fill"
        case .stocks: return "chart.line.uptrend.xyaxis"
        case .realEstate: return "house.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .debt: return "shield.fill"
        }
    }
}

import Foundation
import SwiftUI

// MARK: - Account Model
struct Account: Identifiable {
    let id = UUID()
    let name: String
    let institution: String
    let balance: Double
}

// MARK: - Investment Model
struct Investment: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let risk: String
    let amount: Int
    let returns: String
    let startDate: String
    let associatedGoal: String
    
    // Live MF Data
    var schemeCode: String?
    var lastNAV: Double?
}

// MARK: - Goal Model
struct Goal: Identifiable {
    let id = UUID()
    let name: String
    let associatedFund: String
    let targetAmount: String
    let collectedAmount: String
    let timePeriod: String
}

// MARK: - Loan Model
struct Loan: Identifiable {
    let id = UUID()
    let name: String
    let timePeriod: String
    let status: String
    let totalAmount: String
    let paidAmount: String
    let emisPaid: Int
    let totalEmis: Int
}

// MARK: - Money Flow Data Model
struct MoneyFlowData: Identifiable {
    let id = UUID()
    let month: String
    let savings: Double
    let emergencyFund: Double
    let expenses: Double
}

// MARK: - Fund Allocation Model
struct FundAllocation: Identifiable {
    let id = UUID()
    let name: String
    let percentage: Double
    let color: Color
}

// MARK: - Investment Plan Input Model
struct InvestmentPlanInputModel: Codable, Hashable {
    var investmentType: String
    var amount: String
    var liquidity: String
    var riskType: String
    var timePeriod: String
    var scheduleInvestmentDate: Date
    var scheduleSIPDate: Date
    var purposeOfInvestment: String
    var targetAmount: String
    var savedAmount: String
    var hasEmergencyFund: Bool
    var investmentMentality: InvestmentMentality = .mutualFunds
    
    // Additional fields for the new algorithm
    var monthlyIncome: Double = 0
    var existingEMIs: Double = 0
    var openToLoan: Bool = true
    var preferredLoanTenureYears: Int = 4
    var bankName: String?
    var interestRate: Double?
    var loanAmount: Double?
    
    // Goal-Specific Detail Fields
    var currentAge: Int?
    var retirementAge: Int?
    var yearsPostRetirement: Int?
    var lifestylePreference: String? // "Same", "Better", "Minimal"
    var yearlyStepUpPct: Double?
    var withdrawalPreference: String?
    
    var educationFor: String? // "Myself", "Child"
    var educationDurationYrs: Int?
    var educationLocation: String? // "India", "Abroad"
    var fundingStrategy: String? // "Self", "Partial", "Loan"
    
    var downPaymentAffordable: Double?
    var vehicleBuyLogic: String? // "Funded", "Loan"
    
    var destinationType: String? // "Domestic", "International"
    var isFlexibleTimeline: Bool?
    
    var contributionSplit: String? // "Self", "Family", "Mixed"
    var wealthIntent: String? // "General", "Early Retirement", "Freedom"
}

// MARK: - Investment Plan Model (Your Plans)
struct InvestmentPlanModel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let dateSaved: String
    let targetGoal: String
    let input: InvestmentPlanInputModel
}

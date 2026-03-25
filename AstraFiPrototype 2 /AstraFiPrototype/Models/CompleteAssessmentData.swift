import SwiftUI
import Observation

// MARK: - Complete Assessment Data (observable session model)

@Observable
final class CompleteAssessmentData {

    // Basic
    var name = ""
    var email = ""
    var password = ""
    var age = ""
    var gender: Gender = .male
    var adultDependents = 1
    var childDependents = 0
    var incomeType: IncomeType = .fixed
    var income = ""
    var incomeAfterTax = ""
    var isSetuSelected = false

    // Variable Income specific
    var minMonthlyIncome = ""
    var maxMonthlyIncome = ""
    var taxPercentage = ""

    var expenditure = ""
    var hasEmergencyFund = false
    var emergencyFundAmount = ""
    var hasInvestments = false

    // Investments
    var mutualFunds = ""
    var stocks = ""
    var bonds = ""
    var realEstate = ""
    var gold = ""
    var crypto = ""
    var ppf = ""
    var nps = ""

    // Loans
    var hasLoans = false
    var homeLoan = ""
    var homeLoanEMI = ""
    var carLoan = ""
    var carLoanEMI = ""
    var personalLoan = ""
    var personalLoanEMI = ""
    var educationLoan = ""
    var educationLoanEMI = ""
    var creditCardDebt = ""

    // Insurance toggles
    var hasLifeInsurance = false
    var hasHealthInsurance = false
    var hasCriticalIllness = false

    // Assessment Results
    var investmentEntries: [AssessmentInvestmentEntry] = []
    var loanEntries: [AssessmentLoanEntry] = []
    var insuranceEntries: [AssessmentInsuranceEntry] = []

    enum Gender: String, Codable { case male, female }
    enum IncomeType: String, Codable { case fixed, variable }
}

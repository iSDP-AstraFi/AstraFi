import Foundation
import SwiftUI
import Observation

@Observable
class MFService {
    static let shared = MFService()
    
    var allSchemes: [MFScheme] = []
    var isFetching: Bool = false
    var lastFetchDate: Date?
    
    private let amfiURL = URL(string: "https://www.amfiindia.com/spages/NAVAll.txt")!
    
    func fetchMFData(force: Bool = false) async {
        guard !isFetching else { return }
        
        // Basic caching: If fetched within the last 12 hours, skip (unless forced)
        if !force, let last = lastFetchDate, Date().timeIntervalSince(last) < 12 * 3600, !allSchemes.isEmpty {
            return
        }
        
        isFetching = true
        defer { isFetching = false }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: amfiURL)
            guard let content = String(data: data, encoding: .utf8) else { return }
            
            let parsed = parseAMFIData(content)
            
            await MainActor.run {
                self.allSchemes = parsed
                self.lastFetchDate = Date()
            }
        } catch {
            print("Error fetching AMFI data: \(error)")
        }
    }
    
    private func parseAMFIData(_ content: String) -> [MFScheme] {
        var schemes: [MFScheme] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let components = line.components(separatedBy: ";")
            // Format: Scheme Code;ISIN Div Payout/ ISIN Growth;ISIN Div Reinvestment;Scheme Name;Net Asset Value;Date
            guard components.count >= 6 else { continue }
            
            let schemeCode = components[0].trimmingCharacters(in: .whitespaces)
            // Skip header or metadata lines (if it's not a number, it's likely not a scheme code)
            guard Int(schemeCode) != nil else { continue }
            
            let isin = components[1].trimmingCharacters(in: .whitespaces)
            let name = components[3].trimmingCharacters(in: .whitespaces)
            let navString = components[4].trimmingCharacters(in: .whitespaces)
            let date = components[5].trimmingCharacters(in: .whitespaces)
            
            if let navValue = Double(navString) {
                let scheme = MFScheme(
                    schemeCode: schemeCode,
                    isin: isin,
                    name: name,
                    nav: navValue,
                    date: date
                )
                schemes.append(scheme)
            }
        }
        
        return schemes
    }
    
    func searchSchemes(query: String) -> [MFScheme] {
        guard query.count >= 3 else { return [] }
        let lowerQuery = query.lowercased()
        return allSchemes.filter { $0.name.lowercased().contains(lowerQuery) }
            .prefix(20)
            .map { $0 }
    }
    
    func getScheme(by code: String) -> MFScheme? {
        allSchemes.first { $0.schemeCode == code }
    }
    
    func findSchemeCode(for name: String) -> String? {
        // Try exact match first
        if let exact = allSchemes.first(where: { $0.name.lowercased() == name.lowercased() }) {
            return exact.schemeCode
        }
        // Try fuzzy match
        return allSchemes.first(where: { name.lowercased().contains($0.name.lowercased()) || $0.name.lowercased().contains(name.lowercased()) })?.schemeCode
    }
    
    // MARK: - Historical Data (mfapi.in)
    func fetchHistoricalNAV(schemeCode: String, date: Date) async -> Double? {
        let urlString = "https://api.mfapi.in/mf/\(schemeCode)"
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(MFHistoryResponse.self, from: data)
            
            let df = DateFormatter()
            df.dateFormat = "dd-MM-yyyy"
            let targetDateString = df.string(from: date)
            
            // Try exact date
            if let point = response.data.first(where: { $0.date == targetDateString }) {
                return Double(point.nav)
            }
            
            // Fallback: find the closest date before the target date
            let sortedPoints = response.data.compactMap { p -> (Date, Double)? in
                guard let d = df.date(from: p.date), let v = Double(p.nav) else { return nil }
                return (d, v)
            }.sorted(by: { $0.0 > $1.0 })
            
            return sortedPoints.first(where: { $0.0 <= date })?.1
        } catch {
            print("Error fetching historical NAV: \(error)")
            return nil
        }
    }
    
    func fetchHistoricalGraphData(schemeCode: String, startDate: Date? = nil) async -> [MFHistoryPoint] {
        let urlString = "https://api.mfapi.in/mf/\(schemeCode)"
        guard let url = URL(string: urlString) else { return [] }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(MFHistoryResponse.self, from: data)
            
            if let start = startDate {
                let df = DateFormatter()
                df.dateFormat = "dd-MM-yyyy"
                
                let filtered = response.data.filter { point in
                    if let pointDate = df.date(from: point.date) {
                        // Allow a small buffer (e.g., 1 day) to ensure we capture the start
                        return pointDate >= start.addingTimeInterval(-86400)
                    }
                    return false
                }
                return filtered.reversed()
            } else {
                // Default: last 100 days
                return Array(response.data.prefix(100)).reversed()
            }
        } catch {
            print("Error fetching graph data: \(error)")
            return []
        }
    }
}

// MARK: - MFAPI.in Models
struct MFHistoryResponse: Codable {
    let data: [MFHistoryPoint]
}

struct MFHistoryPoint: Codable {
    let date: String
    let nav: String
}

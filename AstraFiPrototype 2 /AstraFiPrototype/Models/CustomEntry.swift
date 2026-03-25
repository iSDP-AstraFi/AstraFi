// CustomEntry.swift
import Foundation

// MARK: - Custom Entry Model
struct CustomEntry: Identifiable {
    let id = UUID()
    var name: String
    var value: String
}

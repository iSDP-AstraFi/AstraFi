//
//  AstraFiPrototypeApp.swift
//  AstraFiPrototype
//
//  Created by Akash Kashyap on 09/02/26.
//
import SwiftUI

// MARK: - App Entry Point
@main
struct AstraFiPrototypeApp: App {
    @StateObject private var appState = AppStateManager()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(appState)
        }
    }
}

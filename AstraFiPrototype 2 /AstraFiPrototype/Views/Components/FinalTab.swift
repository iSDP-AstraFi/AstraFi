//
//  FinalTab.swift
//  AstraFiPrototype
//

import SwiftUI

struct FinalTab: View {
    @State private var trackerVM = TrackerViewModel()

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            } 

            NavigationStack {
                PlannerView()
            }
            .tabItem {
                Label("Planner", systemImage: "long.text.page.and.pencil.fill")
            }

            NavigationStack {
                TrackerView()
            }
            .tabItem {
                Label("Tracker", systemImage: "chart.pie.fill")
            }
        }
        .tint(AppTheme.primaryTeal)
        .environment(trackerVM)
    }
}

#Preview {
    FinalTab()
        .environmentObject(AppStateManager())
}

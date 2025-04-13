//
//  ContentView.swift
//  Daily Quiz
//
//  Created by Saeed on 4/13/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dependencyContainer) private var dependencyContainer
    
    var body: some View {
        if let container = dependencyContainer {
            QuizDashboardView(viewModel: container.makeQuizDashboardViewModel())
        } else {
            // Fallback if dependency container isn't available
            Text("Initializing application...")
                .font(.headline)
        }
    }
}

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
    
    var body: some View {
        createQuizDashboardView()
    }
    
    // Factory method to create QuizDashboardView with its dependencies
    private func createQuizDashboardView() -> some View {
        // Set up repository and data source
        let dataSource = SwiftDataQuizDataSource(modelContainer: ModelContainer.shared)
        let repository = QuizRepositoryImpl(dataSource: dataSource)
        
        // Create use cases
        let checkDailyQuizAvailabilityUseCase = CheckDailyQuizAvailabilityUseCase(repository: repository)
        let getUserStatsUseCase = GetUserStatsUseCase(repository: repository)
        
        // Create view model
        let viewModel = QuizDashboardViewModel(
            checkDailyQuizAvailabilityUseCase: checkDailyQuizAvailabilityUseCase,
            getUserStatsUseCase: getUserStatsUseCase,
            quizRepository: repository
        )
        
        // Return view
        return QuizDashboardView(viewModel: viewModel)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

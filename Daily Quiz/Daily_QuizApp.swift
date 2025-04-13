//
//  Daily_QuizApp.swift
//  Daily Quiz
//
//  Created by Saeed on 4/13/25.
//

import SwiftUI
import SwiftData
import Swinject

@main
struct Daily_QuizApp: App {
    // Create the model container
    var modelContainer: ModelContainer = {
        do {
            return try ModelContainer(
                for: Question.self, Answer.self, QuizResult.self, UserStats.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    // Create a dependency container that receives the model container
    var dependencyContainer: DependencyContainer!
    
    init() {
        // Initialize dependency container with the model container
        self.dependencyContainer = DependencyContainer(modelContainer: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.dependencyContainer, dependencyContainer)
                .onAppear {
                    NotificationManager.shared.requestPermission { _ in }
                    
                    Task {
                        do {
                            try await dependencyContainer.container.resolve(QuizRepository.self)!.preloadInitialQuizData()
                        } catch {
                            print("Error preloading data: \(error)")
                        }
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}

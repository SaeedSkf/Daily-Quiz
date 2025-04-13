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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Question.self,
            Answer.self,
            CrosswordClue.self,
            QuizResult.self,
            UserStats.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        _ = DependencyContainer.shared
        
        ModelContainer.shared = sharedModelContainer
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NotificationManager.shared.requestPermission { _ in }
                    
                    Task {
                        do {
                            try await DependencyContainer.shared.container.resolve(QuizRepository.self)!.preloadInitialQuizData()
                        } catch {
                            print("Error preloading data: \(error)")
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

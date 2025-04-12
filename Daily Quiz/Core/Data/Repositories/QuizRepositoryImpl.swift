import Foundation
import SwiftData

class QuizRepositoryImpl: QuizRepository {
    private let dataSource: QuizDataSource
    
    init(dataSource: QuizDataSource) {
        self.dataSource = dataSource
    }
    
    func getQuestionsForStage(_ stage: MotherhoodStage, quizType: QuizType) async throws -> [Question] {
        return try await dataSource.getQuestionsForStage(stage, quizType: quizType)
    }
    
    func getCrosswordCluesForStage(_ stage: MotherhoodStage) async throws -> [CrosswordClue] {
        return try await dataSource.getCrosswordCluesForStage(stage)
    }
    
    func saveQuizResult(_ result: QuizResult) async throws {
        try await dataSource.saveQuizResult(result)
    }
    
    func updateUserStats(_ stats: UserStats) async throws {
        try await dataSource.updateUserStats(stats)
    }
    
    func getUserStats() async throws -> UserStats? {
        return try await dataSource.getUserStats()
    }
    
    func isDailyQuizAvailable() async throws -> Bool {
        return try await dataSource.isDailyQuizAvailable()
    }
    
    // Function to preload initial quiz data
    func preloadInitialQuizData() async throws {
        try await dataSource.preloadInitialQuizData()
    }
} 
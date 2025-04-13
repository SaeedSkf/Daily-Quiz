import Foundation
import SwiftData

// Protocol for Quiz Repository
protocol QuizRepository {
    func getQuestionsForStage(_ stage: MotherhoodStage, quizType: QuizType) async throws -> [Question]
    func saveQuizResult(_ result: QuizResult) async throws
    func updateUserStats(_ stats: UserStats) async throws
    func getUserStats() async throws -> UserStats?
    func isDailyQuizAvailable() async throws -> Bool
    func preloadInitialQuizData() async throws
}

// Use Case: Get Quiz Questions
class GetQuizQuestionsUseCase {
    private let repository: QuizRepository
    
    init(repository: QuizRepository) {
        self.repository = repository
    }
    
    func execute(stage: MotherhoodStage, quizType: QuizType) async throws -> [Question] {
        return try await repository.getQuestionsForStage(stage, quizType: quizType)
    }
}

// Use Case: Check Daily Quiz Availability
class CheckDailyQuizAvailabilityUseCase {
    private let repository: QuizRepository
    
    init(repository: QuizRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> Bool {
        return try await repository.isDailyQuizAvailable()
    }
}

// Use Case: Save Quiz Result
class SaveQuizResultUseCase {
    private let repository: QuizRepository
    
    init(repository: QuizRepository) {
        self.repository = repository
    }
    
    func execute(result: QuizResult) async throws {
        try await repository.saveQuizResult(result)
        
        // Get current user stats
        var stats = try await repository.getUserStats() ?? UserStats()
        
        // Update user stats with the new quiz
        stats.updateStreak(withDate: result.date)
        
        // Add badges based on performance if needed
        if result.scorePercentage >= 90 {
            var currentBadges = stats.badges
            
            switch MotherhoodStage(rawValue: result.stage) {
            case .ttc:
                if !currentBadges.contains("Fertility Guru") {
                    currentBadges.append("Fertility Guru")
                }
            case .pregnant:
                if !currentBadges.contains("Pregnancy Pro") {
                    currentBadges.append("Pregnancy Pro")
                }
            case .postpartum:
                if !currentBadges.contains("Postpartum Expert") {
                    currentBadges.append("Postpartum Expert")
                }
            case .none:
                break
            }
            
            stats.badges = currentBadges
        }
        
        // Save updated stats
        try await repository.updateUserStats(stats)
    }
}

// Use Case: Get User Stats
class GetUserStatsUseCase {
    private let repository: QuizRepository
    
    init(repository: QuizRepository) {
        self.repository = repository
    }
    
    func execute() async throws -> UserStats {
        return try await repository.getUserStats() ?? UserStats()
    }
} 
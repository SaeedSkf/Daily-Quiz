import Foundation

// StubQuizRepository for initial view models and testing
class StubQuizRepository: QuizRepository {
    var isUsingStubRepository: Bool { true }
    
    func getQuestionsForStage(_ stage: MotherhoodStage, quizType: QuizType) async throws -> [Question] { [] }
    func saveQuizResult(_ result: QuizResult) async throws {}
    func updateUserStats(_ stats: UserStats) async throws {}
    func getUserStats() async throws -> UserStats? { nil }
    func isDailyQuizAvailable() async throws -> Bool { true }
    func preloadInitialQuizData() async throws {}
} 
import Foundation
import SwiftData
import CommonCrypto

// Protocol defining Quiz data source operations
protocol QuizDataSource {
    func getQuestionsForStage(_ stage: MotherhoodStage, quizType: QuizType) async throws -> [Question]
    func saveQuizResult(_ result: QuizResult) async throws
    func getUserStats() async throws -> UserStats?
    func updateUserStats(_ stats: UserStats) async throws
    func isDailyQuizAvailable() async throws -> Bool
    func preloadInitialQuizData() async throws
}

// Helper struct to decode JSON questions
struct QuestionJSON: Decodable {
    let id: String
    let text: String
    let type: String
    let stage: String
    let explanation: String
    let relatedFeature: String?
    let maxRating: Int?
    let answers: [AnswerJSON]
}

struct AnswerJSON: Decodable {
    let id: String
    let text: String
    let isCorrect: Bool?
    let boolValue: Bool?
    let ratingValue: Int?
}

// SwiftData implementation of QuizDataSource
class SwiftDataQuizDataSource: QuizDataSource {
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    @MainActor
    func getQuestionsForStage(_ stage: MotherhoodStage, quizType: QuizType) async throws -> [Question] {
        let context = modelContainer.mainContext
        
        let stageValue = stage.rawValue
        let typeValue = quizType.rawValue
        
        let descriptor = FetchDescriptor<Question>(
            predicate: #Predicate { question in
                question.stage == stageValue && question.type == typeValue
            }
        )
        
        let questions = try context.fetch(descriptor)
        
        // Return a random selection of questions (5-10 questions)
        let count = min(questions.count, Int.random(in: 5...10))
        return Array(questions.shuffled().prefix(count))
    }
    
    @MainActor
    func saveQuizResult(_ result: QuizResult) async throws {
        let context = modelContainer.mainContext
        context.insert(result)
        try context.save()
    }
    
    @MainActor
    func getUserStats() async throws -> UserStats? {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<UserStats>()
        
        let stats = try context.fetch(descriptor)
        return stats.first
    }
    
    @MainActor
    func updateUserStats(_ stats: UserStats) async throws {
        let context = modelContainer.mainContext
        
        // Check if stats already exist in context
        let statsId = stats.id
        
        let descriptor = FetchDescriptor<UserStats>(
            predicate: #Predicate { existingStats in
                existingStats.id == statsId
            }
        )
        
        let existingStats = try context.fetch(descriptor)
        
        if existingStats.isEmpty {
            context.insert(stats)
        }
        
        try context.save()
    }
    
    func isDailyQuizAvailable() async throws -> Bool {
        let userStats = try await getUserStats()
        
        if let lastQuizDate = userStats?.lastQuizDate {
            // Check if the last quiz was taken today
            return !Calendar.current.isDateInToday(lastQuizDate)
        }
        
        // No quiz taken yet, so it's available
        return true
    }
    
    @MainActor
    func preloadInitialQuizData() async throws {
        let context = modelContainer.mainContext
        
        // Check if we already have questions
        let questionDescriptor = FetchDescriptor<Question>()
        let existingQuestions = try context.fetchCount(questionDescriptor)
        
        // Only preload if no questions exist
        guard existingQuestions == 0 else {
            print("Questions already exist, skipping preload. \(existingQuestions)")
            // Check if user stats exist, create if not
            try await ensureUserStatsExist(context: context)
            return
        }
        
        print("Preloading initial quiz data from JSON...")
        
        // Load questions from JSON
        guard let url = Bundle.main.url(forResource: "quiz_questions", withExtension: "json") else {
            throw NSError(domain: "QuizDataSourceError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to find quiz_questions.json"])
        }
        
        let data = try Data(contentsOf: url)
        let questionsJSON = try JSONDecoder().decode([QuestionJSON].self, from: data)
        
        var questionsAdded = 0
        
        for qJSON in questionsJSON {
            guard let quizType = QuizType(rawValue: qJSON.type) else {
                print("Skipping invalid question data (invalid type): \(qJSON.id)")
                continue
            }
            
            // Convert stage string to proper MotherhoodStage
            let stage: MotherhoodStage
            switch qJSON.stage.lowercased() {
            case "ttc":
                stage = .ttc
            case "pregnant":
                stage = .pregnant
            case "postpartum":
                stage = .postpartum
            default:
                print("Skipping invalid question data (invalid stage): \(qJSON.id)")
                continue
            }
            
            let questionUUID = UUID.deterministic(from: qJSON.id)
            
            var answers: [Answer] = []
            
            for (_, aJSON) in qJSON.answers.enumerated() {
                let answerUUID = UUID.deterministic(from: aJSON.id)
                
                let answer = Answer(
                    id: answerUUID,
                    text: aJSON.text,
                    isCorrect: aJSON.isCorrect ?? false,
                    boolValue: aJSON.boolValue ?? false,
                    ratingValue: aJSON.ratingValue ?? 0
                )
                answers.append(answer)
            }
            
            let question = Question(
                id: questionUUID,
                text: qJSON.text,
                type: quizType,
                stage: stage,
                explanation: qJSON.explanation,
                relatedFeature: qJSON.relatedFeature
            )
            
            // Set answers after creation
            question.answers = answers
            
            context.insert(question)
            answers.forEach { context.insert($0) }
            questionsAdded += 1
        }
        
        // Create initial user stats if they don't exist
        try await ensureUserStatsExist(context: context)
        
        try context.save()
        print("Successfully preloaded \(questionsAdded) questions.")
    }
    
    // Helper to ensure UserStats exist
    @MainActor
    private func ensureUserStatsExist(context: ModelContext) async throws {
        let statsDescriptor = FetchDescriptor<UserStats>()
        let existingStats = try context.fetchCount(statsDescriptor)
        if existingStats == 0 {
            print("Creating initial UserStats.")
            let stats = UserStats()
            context.insert(stats)
            // No need to save here, will be saved after question preloading or if called separately
        }
    }
}

// Helper extension to create deterministic UUIDs from strings
extension UUID {
    static func deterministic(from string: String) -> UUID {
        // Convert string to data
        let data = string.data(using: .utf8)!
        
        // Create SHA1 hash of the data
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        
        // Set the version bits to UUID v5 (SHA1-based)
        digest[6] = (digest[6] & 0x0F) | 0x50 // Version 5
        digest[8] = (digest[8] & 0x3F) | 0x80 // Variant 1
        
        // Create a UUID from the digest
        let uuid = UUID(uuid: (
            digest[0], digest[1], digest[2], digest[3],
            digest[4], digest[5], digest[6], digest[7],
            digest[8], digest[9], digest[10], digest[11],
            digest[12], digest[13], digest[14], digest[15]
        ))
        
        return uuid
    }
} 

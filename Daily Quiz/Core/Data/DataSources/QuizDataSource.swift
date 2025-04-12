import Foundation
import SwiftData

// Protocol defining Quiz data source operations
protocol QuizDataSource {
    func getQuestionsForStage(_ stage: MotherhoodStage, quizType: QuizType) async throws -> [Question]
    func getCrosswordCluesForStage(_ stage: MotherhoodStage) async throws -> [CrosswordClue]
    func saveQuizResult(_ result: QuizResult) async throws
    func getUserStats() async throws -> UserStats?
    func updateUserStats(_ stats: UserStats) async throws
    func isDailyQuizAvailable() async throws -> Bool
    func preloadInitialQuizData() async throws
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
    func getCrosswordCluesForStage(_ stage: MotherhoodStage) async throws -> [CrosswordClue] {
        let context = modelContainer.mainContext
        
        let stageValue = stage.rawValue
        
        let descriptor = FetchDescriptor<CrosswordClue>(
            predicate: #Predicate { clue in
                clue.stage == stageValue
            }
        )
        
        return try context.fetch(descriptor)
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
        // Check if we already have questions
        let context = modelContainer.mainContext
        let questionDescriptor = FetchDescriptor<Question>(
            sortBy: [SortDescriptor(\Question.text)]
        )
        
        let existingQuestions = try context.fetch(questionDescriptor)
        
        // Only preload if no questions exist
        if existingQuestions.isEmpty {
            // Sample Multiple Choice Questions for TTC
            let ttcQuestion1 = Question(
                text: "What is the most fertile time in a woman's cycle?",
                type: .multipleChoice,
                stage: .ttc,
                explanation: "Ovulation typically occurs around day 14 of a 28-day cycle, making this the most fertile period."
            )
            
            let ttcAnswers1 = [
                Answer(text: "During menstruation", isCorrect: false),
                Answer(text: "Right after menstruation", isCorrect: false),
                Answer(text: "During ovulation", isCorrect: true),
                Answer(text: "Right before menstruation", isCorrect: false)
            ]
            
            ttcQuestion1.answers = ttcAnswers1
            
            // Sample Multiple Choice Questions for Pregnant
            let pregnantQuestion1 = Question(
                text: "Which food should be avoided during pregnancy due to potential mercury content?",
                type: .multipleChoice,
                stage: .pregnant,
                explanation: "Some fish like swordfish, king mackerel, and tuna contain high levels of mercury which can be harmful to the developing fetus.",
                relatedFeature: "BellySafe"
            )
            
            let pregnantAnswers1 = [
                Answer(text: "Salmon", isCorrect: false),
                Answer(text: "Tuna", isCorrect: true),
                Answer(text: "Tilapia", isCorrect: false),
                Answer(text: "Cod", isCorrect: false)
            ]
            
            pregnantQuestion1.answers = pregnantAnswers1
            
            // Sample Multiple Choice Questions for Postpartum
            let postpartumQuestion1 = Question(
                text: "How often should a newborn baby eat?",
                type: .multipleChoice,
                stage: .postpartum,
                explanation: "Newborns typically need to feed every 2-3 hours, including overnight."
            )
            
            let postpartumAnswers1 = [
                Answer(text: "Every 2-3 hours", isCorrect: true),
                Answer(text: "Every 4-5 hours", isCorrect: false),
                Answer(text: "Every 6 hours", isCorrect: false),
                Answer(text: "Whenever they cry", isCorrect: false)
            ]
            
            postpartumQuestion1.answers = postpartumAnswers1
            
            // Sample crossword clues
            let crosswordClue1 = CrosswordClue(
                clue: "A fish to avoid during pregnancy",
                answer: "TUNA",
                row: 0,
                column: 0,
                isHorizontal: true,
                stage: .pregnant
            )
            
            let crosswordClue2 = CrosswordClue(
                clue: "Essential vitamin for pregnancy",
                answer: "FOLIC",
                row: 2,
                column: 0,
                isHorizontal: true,
                stage: .pregnant
            )
            
            // Insert all the entities
            context.insert(ttcQuestion1)
            for answer in ttcAnswers1 {
                answer.question = ttcQuestion1
                context.insert(answer)
            }
            
            context.insert(pregnantQuestion1)
            for answer in pregnantAnswers1 {
                answer.question = pregnantQuestion1
                context.insert(answer)
            }
            
            context.insert(postpartumQuestion1)
            for answer in postpartumAnswers1 {
                answer.question = postpartumQuestion1
                context.insert(answer)
            }
            
            context.insert(crosswordClue1)
            context.insert(crosswordClue2)
            
            // Create initial user stats
            let stats = UserStats()
            context.insert(stats)
            
            try context.save()
        }
    }
} 

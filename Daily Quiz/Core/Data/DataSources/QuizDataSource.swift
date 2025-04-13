import Foundation
import SwiftData

// Protocol defining Quiz data source operations
protocol QuizDataSource {
    func getQuestionsForStage(_ stage: MotherhoodStage, quizType: QuizType) async throws -> [Question]
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
            // TTC Stage Questions
            
            // 1. Single Select for TTC
            let ttcSingleQ = Question(
                text: "What is the most fertile time in a woman's cycle?",
                type: .singleSelect,
                stage: .ttc,
                explanation: "Ovulation typically occurs around day 14 of a 28-day cycle, making this the most fertile period."
            )
            
            let ttcSingleAnswers = [
                Answer(text: "During menstruation", isCorrect: false),
                Answer(text: "Right after menstruation", isCorrect: false),
                Answer(text: "During ovulation", isCorrect: true),
                Answer(text: "Right before menstruation", isCorrect: false)
            ]
            
            ttcSingleQ.answers = ttcSingleAnswers
            
            // 2. Multiple Select for TTC
            let ttcMultiQ = Question(
                text: "Which factors can increase your chances of getting pregnant?",
                type: .multipleSelect,
                stage: .ttc,
                explanation: "Multiple lifestyle factors can affect fertility and chances of conception."
            )
            
            let ttcMultiAnswers = [
                Answer(text: "Maintaining a healthy weight", isCorrect: true),
                Answer(text: "Tracking your ovulation", isCorrect: true),
                Answer(text: "Consuming excessive caffeine", isCorrect: false),
                Answer(text: "Taking prenatal vitamins", isCorrect: true)
            ]
            
            ttcMultiQ.answers = ttcMultiAnswers
            
            // 3. Switch Question for TTC
            let ttcSwitchQ = Question(
                text: "Stress can negatively impact fertility.",
                type: .switchQuestion,
                stage: .ttc,
                explanation: "High stress levels can affect hormonal balance and ovulation."
            )
            
            let ttcSwitchAnswers = [
                Answer(text: "True", isCorrect: true, boolValue: true),
                Answer(text: "False", isCorrect: false, boolValue: false)
            ]
            
            ttcSwitchQ.answers = ttcSwitchAnswers
            
            // 4. Star Rating for TTC
            let ttcRatingQ = Question(
                text: "How important is timing intercourse around ovulation for conception?",
                type: .starRating,
                stage: .ttc,
                explanation: "Timing intercourse 1-2 days before ovulation significantly increases chances of conception.",
                maxRating: 5
            )
            
            let ttcRatingAnswers = [
                Answer(text: "Not important", isCorrect: false, ratingValue: 1),
                Answer(text: "Slightly important", isCorrect: false, ratingValue: 2),
                Answer(text: "Moderately important", isCorrect: false, ratingValue: 3),
                Answer(text: "Very important", isCorrect: false, ratingValue: 4),
                Answer(text: "Extremely important", isCorrect: true, ratingValue: 5)
            ]
            
            ttcRatingQ.answers = ttcRatingAnswers
            
            // Pregnant Stage Questions
            
            // 1. Single Select for Pregnant
            let pregSingleQ = Question(
                text: "Which food should be avoided during pregnancy due to potential mercury content?",
                type: .singleSelect,
                stage: .pregnant,
                explanation: "Some fish like swordfish, king mackerel, and tuna contain high levels of mercury which can be harmful to the developing fetus.",
                relatedFeature: "BellySafe"
            )
            
            let pregSingleAnswers = [
                Answer(text: "Salmon", isCorrect: false),
                Answer(text: "Tuna", isCorrect: true),
                Answer(text: "Tilapia", isCorrect: false),
                Answer(text: "Cod", isCorrect: false)
            ]
            
            pregSingleQ.answers = pregSingleAnswers
            
            // 2. Multiple Select for Pregnant
            let pregMultiQ = Question(
                text: "Which symptoms are common in the first trimester of pregnancy?",
                type: .multipleSelect,
                stage: .pregnant,
                explanation: "The first trimester often comes with several physical symptoms as the body adjusts to pregnancy."
            )
            
            let pregMultiAnswers = [
                Answer(text: "Morning sickness", isCorrect: true),
                Answer(text: "Fatigue", isCorrect: true),
                Answer(text: "Frequent urination", isCorrect: true),
                Answer(text: "Braxton Hicks contractions", isCorrect: false)
            ]
            
            pregMultiQ.answers = pregMultiAnswers
            
            // 3. Switch Question for Pregnant
            let pregSwitchQ = Question(
                text: "It's safe to exercise moderately during pregnancy if you were active before conception.",
                type: .switchQuestion,
                stage: .pregnant,
                explanation: "Moderate exercise is generally safe and beneficial during pregnancy, especially if you were active before getting pregnant."
            )
            
            let pregSwitchAnswers = [
                Answer(text: "True", isCorrect: true, boolValue: true),
                Answer(text: "False", isCorrect: false, boolValue: false)
            ]
            
            pregSwitchQ.answers = pregSwitchAnswers
            
            // 4. Star Rating for Pregnant
            let pregRatingQ = Question(
                text: "How important is taking folic acid during pregnancy?",
                type: .starRating,
                stage: .pregnant,
                explanation: "Folic acid is crucial for preventing neural tube defects in the developing baby.",
                maxRating: 5
            )
            
            let pregRatingAnswers = [
                Answer(text: "Not important", isCorrect: false, ratingValue: 1),
                Answer(text: "Slightly important", isCorrect: false, ratingValue: 2),
                Answer(text: "Moderately important", isCorrect: false, ratingValue: 3),
                Answer(text: "Very important", isCorrect: false, ratingValue: 4),
                Answer(text: "Extremely important", isCorrect: true, ratingValue: 5)
            ]
            
            pregRatingQ.answers = pregRatingAnswers
            
            // Postpartum Stage Questions
            
            // 1. Single Select for Postpartum
            let postSingleQ = Question(
                text: "How often should a newborn baby eat?",
                type: .singleSelect,
                stage: .postpartum,
                explanation: "Newborns typically need to feed every 2-3 hours, including overnight."
            )
            
            let postSingleAnswers = [
                Answer(text: "Every 2-3 hours", isCorrect: true),
                Answer(text: "Every 4-5 hours", isCorrect: false),
                Answer(text: "Every 6 hours", isCorrect: false),
                Answer(text: "Whenever they cry", isCorrect: false)
            ]
            
            postSingleQ.answers = postSingleAnswers
            
            // 2. Multiple Select for Postpartum
            let postMultiQ = Question(
                text: "Which signs indicate that a baby is getting enough breast milk?",
                type: .multipleSelect,
                stage: .postpartum,
                explanation: "Several indicators can help determine if a baby is receiving adequate nutrition through breastfeeding."
            )
            
            let postMultiAnswers = [
                Answer(text: "Regular wet diapers", isCorrect: true),
                Answer(text: "Steady weight gain", isCorrect: true),
                Answer(text: "Sleeping through the night", isCorrect: false),
                Answer(text: "Alert and active when awake", isCorrect: true)
            ]
            
            postMultiQ.answers = postMultiAnswers
            
            // 3. Switch Question for Postpartum
            let postSwitchQ = Question(
                text: "Postpartum depression only affects mothers who had complications during delivery.",
                type: .switchQuestion,
                stage: .postpartum,
                explanation: "Postpartum depression can affect any new mother, regardless of birth experience or previous mental health history."
            )
            
            let postSwitchAnswers = [
                Answer(text: "True", isCorrect: false, boolValue: true),
                Answer(text: "False", isCorrect: true, boolValue: false)
            ]
            
            postSwitchQ.answers = postSwitchAnswers
            
            // 4. Star Rating for Postpartum
            let postRatingQ = Question(
                text: "How important is skin-to-skin contact with your newborn?",
                type: .starRating,
                stage: .postpartum,
                explanation: "Skin-to-skin contact promotes bonding, regulates baby's temperature and heart rate, and encourages breastfeeding success.",
                maxRating: 5
            )
            
            let postRatingAnswers = [
                Answer(text: "Not important", isCorrect: false, ratingValue: 1),
                Answer(text: "Slightly important", isCorrect: false, ratingValue: 2),
                Answer(text: "Moderately important", isCorrect: false, ratingValue: 3),
                Answer(text: "Very important", isCorrect: false, ratingValue: 4),
                Answer(text: "Extremely important", isCorrect: true, ratingValue: 5)
            ]
            
            postRatingQ.answers = postRatingAnswers
            
            // Insert all questions and answers
            
            // TTC
            context.insert(ttcSingleQ)
            for answer in ttcSingleAnswers {
                answer.question = ttcSingleQ
                context.insert(answer)
            }
            
            context.insert(ttcMultiQ)
            for answer in ttcMultiAnswers {
                answer.question = ttcMultiQ
                context.insert(answer)
            }
            
            context.insert(ttcSwitchQ)
            for answer in ttcSwitchAnswers {
                answer.question = ttcSwitchQ
                context.insert(answer)
            }
            
            context.insert(ttcRatingQ)
            for answer in ttcRatingAnswers {
                answer.question = ttcRatingQ
                context.insert(answer)
            }
            
            // Pregnant
            context.insert(pregSingleQ)
            for answer in pregSingleAnswers {
                answer.question = pregSingleQ
                context.insert(answer)
            }
            
            context.insert(pregMultiQ)
            for answer in pregMultiAnswers {
                answer.question = pregMultiQ
                context.insert(answer)
            }
            
            context.insert(pregSwitchQ)
            for answer in pregSwitchAnswers {
                answer.question = pregSwitchQ
                context.insert(answer)
            }
            
            context.insert(pregRatingQ)
            for answer in pregRatingAnswers {
                answer.question = pregRatingQ
                context.insert(answer)
            }
            
            // Postpartum
            context.insert(postSingleQ)
            for answer in postSingleAnswers {
                answer.question = postSingleQ
                context.insert(answer)
            }
            
            context.insert(postMultiQ)
            for answer in postMultiAnswers {
                answer.question = postMultiQ
                context.insert(answer)
            }
            
            context.insert(postSwitchQ)
            for answer in postSwitchAnswers {
                answer.question = postSwitchQ
                context.insert(answer)
            }
            
            context.insert(postRatingQ)
            for answer in postRatingAnswers {
                answer.question = postRatingQ
                context.insert(answer)
            }
            
            // Create initial user stats
            let stats = UserStats()
            context.insert(stats)
            
            try context.save()
        }
    }
} 

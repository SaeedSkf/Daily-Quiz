import Foundation
import SwiftData

// Quiz Question Types
enum QuizType: String, Codable {
    case singleSelect
    case multipleSelect
    case switchQuestion
    case starRating
}

// Question Model
@Model
final class Question {
    @Attribute(.unique) var id: UUID
    var text: String
    var type: String // QuizType as string for SwiftData
    var stage: String // MotherhoodStage as string for SwiftData
    var answers: [Answer] = []
    var explanation: String
    var relatedFeature: String?
    var maxRating: Int = 5 // Used for star rating type questions
    
    init(id: UUID = UUID(), text: String, type: QuizType, stage: MotherhoodStage, explanation: String, relatedFeature: String? = nil, maxRating: Int = 5) {
        self.id = id
        self.text = text
        self.type = type.rawValue
        self.stage = stage.rawValue
        self.explanation = explanation
        self.relatedFeature = relatedFeature
        self.maxRating = maxRating
    }
    
    var quizType: QuizType {
        return QuizType(rawValue: type) ?? .singleSelect
    }
    
    var motherhoodStage: MotherhoodStage? {
        return MotherhoodStage(rawValue: stage)
    }
}

// Answer Model
@Model
final class Answer {
    @Attribute(.unique) var id: UUID
    var text: String
    var isCorrect: Bool
    
    // Used for switch questions (true/false)
    var boolValue: Bool?
    
    // Used for star rating
    var ratingValue: Int?
    
    // Relationship
    var question: Question?
    
    init(id: UUID = UUID(), text: String, isCorrect: Bool = false, boolValue: Bool? = nil, ratingValue: Int? = nil) {
        self.id = id
        self.text = text
        self.isCorrect = isCorrect
        self.boolValue = boolValue
        self.ratingValue = ratingValue
    }
}

// Quiz Result
@Model
final class QuizResult {
    @Attribute(.unique) var id: UUID
    var date: Date
    var score: Int
    var totalQuestions: Int
    var stage: String // MotherhoodStage as string
    var quizType: String // QuizType as string
    
    init(id: UUID = UUID(), date: Date = Date(), score: Int, totalQuestions: Int, stage: MotherhoodStage, quizType: QuizType) {
        self.id = id
        self.date = date
        self.score = score
        self.totalQuestions = totalQuestions
        self.stage = stage.rawValue
        self.quizType = quizType.rawValue
    }
    
    var scorePercentage: Double {
        return Double(score) / Double(totalQuestions) * 100.0
    }
    
    var isPassing: Bool {
        return scorePercentage >= 60.0
    }
    
    var motherhoodStage: MotherhoodStage? {
        return MotherhoodStage(rawValue: stage)
    }
}

// User stats and streak tracking
@Model
final class UserStats {
    @Attribute(.unique) var id: UUID
    var lastQuizDate: Date?
    var currentStreak: Int
    var highestStreak: Int
    var totalQuizzesTaken: Int
    var badgesString: String = ""
    
    init(id: UUID = UUID(), lastQuizDate: Date? = nil, currentStreak: Int = 0, highestStreak: Int = 0, totalQuizzesTaken: Int = 0) {
        self.id = id
        self.lastQuizDate = lastQuizDate
        self.currentStreak = currentStreak
        self.highestStreak = highestStreak
        self.totalQuizzesTaken = totalQuizzesTaken
    }
    
    // Computed property to work with badges as an array
    var badges: [String] {
        get {
            return badgesString.isEmpty ? [] : badgesString.components(separatedBy: ",")
        }
        set {
            badgesString = newValue.joined(separator: ",")
        }
    }
    
    func updateStreak(withDate date: Date) {
        let calendar = Calendar.current
        
        if let lastDate = lastQuizDate {
            // Check if quiz was taken yesterday
            if calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: date) ?? date) {
                currentStreak += 1
                if currentStreak > highestStreak {
                    highestStreak = currentStreak
                }
            } 
            // If quiz wasn't taken yesterday but was taken today, maintain streak
            else if !calendar.isDate(lastDate, inSameDayAs: date) {
                currentStreak = 1
            }
        } else {
            // First quiz
            currentStreak = 1
        }
        
        lastQuizDate = date
        totalQuizzesTaken += 1
    }
} 
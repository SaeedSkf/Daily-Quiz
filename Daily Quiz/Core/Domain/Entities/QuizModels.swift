import Foundation
import SwiftData

// Quiz Question Types
enum QuizType: String, Codable {
    case multipleChoice
    case crossword
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
    
    init(id: UUID = UUID(), text: String, type: QuizType, stage: MotherhoodStage, explanation: String, relatedFeature: String? = nil) {
        self.id = id
        self.text = text
        self.type = type.rawValue
        self.stage = stage.rawValue
        self.explanation = explanation
        self.relatedFeature = relatedFeature
    }
    
    var quizType: QuizType {
        return QuizType(rawValue: type) ?? .multipleChoice
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
    
    // Relationship
    var question: Question?
    
    init(id: UUID = UUID(), text: String, isCorrect: Bool = false) {
        self.id = id
        self.text = text
        self.isCorrect = isCorrect
    }
}

// Crossword Clue
@Model
final class CrosswordClue {
    @Attribute(.unique) var id: UUID
    var clue: String
    var answer: String
    var row: Int
    var column: Int
    var isHorizontal: Bool
    var stage: String // MotherhoodStage as string
    
    init(id: UUID = UUID(), clue: String, answer: String, row: Int, column: Int, isHorizontal: Bool, stage: MotherhoodStage) {
        self.id = id
        self.clue = clue
        self.answer = answer
        self.row = row
        self.column = column
        self.isHorizontal = isHorizontal
        self.stage = stage.rawValue
    }
    
    var motherhoodStage: MotherhoodStage? {
        return MotherhoodStage(rawValue: stage)
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
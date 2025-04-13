import Foundation
import SwiftData
import Combine

enum QuizState {
    case loading
    case questions
    case results
    case error(String)
}

class QuizViewModel: ObservableObject {
    // Dependencies
    private let getQuizQuestionsUseCase: GetQuizQuestionsUseCase
    private let saveQuizResultUseCase: SaveQuizResultUseCase
    
    // Published properties
    @Published var quizState: QuizState = .loading
    @Published var currentQuestionIndex = 0
    @Published var questions: [Question] = []
    
    // User answers by question type
    @Published var singleSelectAnswers: [UUID: UUID] = [:]  // question.id -> selectedAnswer.id
    @Published var multipleSelectAnswers: [UUID: Set<UUID>] = [:]  // question.id -> set of selectedAnswer.ids
    @Published var switchAnswers: [UUID: Bool] = [:]  // question.id -> true/false
    @Published var starRatingAnswers: [UUID: Int] = [:]  // question.id -> rating value
    
    @Published var score = 0
    @Published var quizResult: QuizResult?
    @Published var showConfetti = false
    
    // Quiz parameters
    let stage: MotherhoodStage
    
    init(
        getQuizQuestionsUseCase: GetQuizQuestionsUseCase,
        saveQuizResultUseCase: SaveQuizResultUseCase,
        stage: MotherhoodStage
    ) {
        self.getQuizQuestionsUseCase = getQuizQuestionsUseCase
        self.saveQuizResultUseCase = saveQuizResultUseCase
        self.stage = stage
        
        // Load questions
        Task {
            await loadQuestions()
        }
    }
    
    @MainActor
    private func loadQuestions() async {
        quizState = .loading
        
        do {
            // Get all questions for this stage
            var allQuestions: [Question] = []
            
            // Get single select questions
            let singleSelectQuestions = try await getQuizQuestionsUseCase.execute(stage: stage, quizType: QuizType.singleSelect)
            allQuestions.append(contentsOf: singleSelectQuestions)
            
            // Get multiple select questions
            let multipleSelectQuestions = try await getQuizQuestionsUseCase.execute(stage: stage, quizType: QuizType.multipleSelect)
            allQuestions.append(contentsOf: multipleSelectQuestions)
            
            // Get switch questions
            let switchQuestions = try await getQuizQuestionsUseCase.execute(stage: stage, quizType: QuizType.switchQuestion)
            allQuestions.append(contentsOf: switchQuestions)
            
            // Get star rating questions
            let ratingQuestions = try await getQuizQuestionsUseCase.execute(stage: stage, quizType: QuizType.starRating)
            allQuestions.append(contentsOf: ratingQuestions)
            
            // Shuffle all questions and take the first 5
            questions = Array(allQuestions.shuffled().prefix(5))
            
            if questions.isEmpty {
                quizState = .error("No questions available for this stage.")
            } else {
                quizState = .questions
            }
        } catch {
            quizState = .error("Failed to load quiz: \(error.localizedDescription)")
        }
    }
    
    // Select single answer
    func selectSingleAnswer(questionId: UUID, answerId: UUID) {
        singleSelectAnswers[questionId] = answerId
    }
    
    // Toggle multiple select answer
    func toggleMultipleAnswer(questionId: UUID, answerId: UUID) {
        var selectedAnswers = multipleSelectAnswers[questionId] ?? Set<UUID>()
        
        if selectedAnswers.contains(answerId) {
            selectedAnswers.remove(answerId)
        } else {
            selectedAnswers.insert(answerId)
        }
        
        multipleSelectAnswers[questionId] = selectedAnswers
    }
    
    // Set switch answer
    func setSwitchAnswer(questionId: UUID, value: Bool) {
        switchAnswers[questionId] = value
    }
    
    // Set star rating answer
    func setStarRating(questionId: UUID, rating: Int) {
        starRatingAnswers[questionId] = rating
    }
    
    // Go to next question
    func nextQuestion() async {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            await calculateResults()
        }
    }
    
    // Go to previous question
    func previousQuestion() {
        if currentQuestionIndex > 0 {
            currentQuestionIndex -= 1
        }
    }
    
    // Calculate results
    @MainActor
    func calculateResults() async {
        score = 0
        
        for question in questions {
            switch question.quizType {
            case .singleSelect:
                if let selectedAnswerId = singleSelectAnswers[question.id],
                   let selectedAnswer = question.answers.first(where: { $0.id == selectedAnswerId }),
                   selectedAnswer.isCorrect {
                    score += 1
                }
                
            case .multipleSelect:
                let selectedAnswerIds = multipleSelectAnswers[question.id] ?? []
                let correctAnswers = question.answers.filter { $0.isCorrect }
                let incorrectAnswers = question.answers.filter { !$0.isCorrect }
                
                // Check if all correct answers are selected and no incorrect answers are selected
                let allCorrectSelected = correctAnswers.allSatisfy { selectedAnswerIds.contains($0.id) }
                let noIncorrectSelected = incorrectAnswers.allSatisfy { !selectedAnswerIds.contains($0.id) }
                
                if allCorrectSelected && noIncorrectSelected {
                    score += 1
                }
                
            case .switchQuestion:
                if let selectedValue = switchAnswers[question.id],
                   let correctAnswer = question.answers.first(where: { $0.isCorrect }),
                   correctAnswer.boolValue == selectedValue {
                    score += 1
                }
                
            case .starRating:
                if let selectedRating = starRatingAnswers[question.id],
                   let correctAnswer = question.answers.first(where: { $0.isCorrect }),
                   correctAnswer.ratingValue == selectedRating {
                    score += 1
                }
            }
        }
        
        // Create and save result
        let result = QuizResult(
            score: score,
            totalQuestions: questions.count,
            stage: stage,
            quizType: QuizType.singleSelect  // We're using mixed types, but need a type for the result
        )
        
        quizResult = result
        
        // Show confetti for passing score
        showConfetti = result.isPassing
        
        // Save result
        do {
            try await saveQuizResultUseCase.execute(result: result)
        } catch {
            print("Error saving quiz result: \(error.localizedDescription)")
        }
        
        quizState = .results
    }
    
    // Check if user has answered current question
    var hasAnsweredCurrentQuestion: Bool {
        guard currentQuestionIndex < questions.count else { return false }
        
        let question = questions[currentQuestionIndex]
        
        switch question.quizType {
        case .singleSelect:
            return singleSelectAnswers[question.id] != nil
        case .multipleSelect:
            return (multipleSelectAnswers[question.id]?.isEmpty == false)
        case .switchQuestion:
            return switchAnswers[question.id] != nil
        case .starRating:
            return starRatingAnswers[question.id] != nil
        }
    }
    
    // Get current question
    var currentQuestion: Question? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
} 

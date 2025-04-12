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
    private let getCrosswordCluesUseCase: GetCrosswordCluesUseCase
    private let saveQuizResultUseCase: SaveQuizResultUseCase
    
    // Published properties
    @Published var quizState: QuizState = .loading
    @Published var currentQuestionIndex = 0
    @Published var questions: [Question] = []
    @Published var crosswordClues: [CrosswordClue] = []
    @Published var userAnswers: [UUID: UUID] = [:]  // question.id -> selectedAnswer.id
    @Published var crosswordAnswers: [UUID: String] = [:] // clue.id -> user input
    @Published var score = 0
    @Published var quizResult: QuizResult?
    @Published var showConfetti = false
    
    // Quiz parameters
    let stage: MotherhoodStage
    let quizType: QuizType
    
    init(
        getQuizQuestionsUseCase: GetQuizQuestionsUseCase,
        getCrosswordCluesUseCase: GetCrosswordCluesUseCase,
        saveQuizResultUseCase: SaveQuizResultUseCase,
        stage: MotherhoodStage,
        quizType: QuizType
    ) {
        self.getQuizQuestionsUseCase = getQuizQuestionsUseCase
        self.getCrosswordCluesUseCase = getCrosswordCluesUseCase
        self.saveQuizResultUseCase = saveQuizResultUseCase
        self.stage = stage
        self.quizType = quizType
        
        // Load questions
        Task {
            await loadQuestions()
        }
    }
    
    @MainActor
    private func loadQuestions() async {
        quizState = .loading
        
        do {
            if quizType == .multipleChoice {
                questions = try await getQuizQuestionsUseCase.execute(stage: stage, quizType: quizType)
                
                if questions.isEmpty {
                    quizState = .error("No questions available for this stage.")
                } else {
                    quizState = .questions
                }
            } else {
                // Load crossword clues
                crosswordClues = try await getCrosswordCluesUseCase.execute(stage: stage)
                
                if crosswordClues.isEmpty {
                    quizState = .error("No crossword available for this stage.")
                } else {
                    quizState = .questions
                }
            }
        } catch {
            quizState = .error("Failed to load quiz: \(error.localizedDescription)")
        }
    }
    
    // Select an answer
    func selectAnswer(questionId: UUID, answerId: UUID) {
        userAnswers[questionId] = answerId
    }
    
    // Enter crossword answer
    func enterCrosswordAnswer(clueId: UUID, answer: String) {
        crosswordAnswers[clueId] = answer.uppercased()
    }
    
    // Go to next question
    @MainActor
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
        if quizType == .multipleChoice {
            // Calculate score for multiple choice
            score = 0
            
            for question in questions {
                if let selectedAnswerId = userAnswers[question.id],
                   let selectedAnswer = question.answers.first(where: { $0.id == selectedAnswerId }),
                   selectedAnswer.isCorrect {
                    score += 1
                }
            }
            
            // Create and save result
            let result = QuizResult(
                score: score,
                totalQuestions: questions.count,
                stage: stage,
                quizType: quizType
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
        } else {
            // Calculate score for crossword
            score = 0
            
            for clue in crosswordClues {
                if let userAnswer = crosswordAnswers[clue.id],
                   userAnswer.uppercased() == clue.answer.uppercased() {
                    score += 1
                }
            }
            
            // Create and save result
            let result = QuizResult(
                score: score,
                totalQuestions: crosswordClues.count,
                stage: stage,
                quizType: quizType
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
        }
        
        quizState = .results
    }
    
    // Check if user has answered current question
    var hasAnsweredCurrentQuestion: Bool {
        if quizType == .multipleChoice && currentQuestionIndex < questions.count {
            return userAnswers[questions[currentQuestionIndex].id] != nil
        }
        return false
    }
    
    // Get current question
    var currentQuestion: Question? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
} 

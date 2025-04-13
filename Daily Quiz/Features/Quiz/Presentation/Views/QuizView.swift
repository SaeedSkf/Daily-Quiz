import SwiftUI
import Foundation
// Import not needed since these are in the same module
// Components are directly accessible

struct QuizView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: QuizViewModel
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground).ignoresSafeArea()
            
            // Content based on state
            switch viewModel.quizState {
            case .loading:
                ProgressView("Loading quiz...")
                
            case .questions:
                QuizQuestionView(viewModel: viewModel)
                
            case .results:
                QuizResultsView(
                    result: viewModel.quizResult,
                    questions: viewModel.questions,
                    showConfetti: viewModel.showConfetti,
                    singleSelectAnswers: viewModel.singleSelectAnswers,
                    multipleSelectAnswers: viewModel.multipleSelectAnswers,
                    switchAnswers: viewModel.switchAnswers,
                    starRatingAnswers: viewModel.starRatingAnswers
                )
                
            case .error(let message):
                ErrorView(message: message)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}

struct QuizQuestionView: View {
    @ObservedObject var viewModel: QuizViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressBar(
                progress: Double(viewModel.currentQuestionIndex + 1) / Double(viewModel.questions.count),
                label: "\(viewModel.currentQuestionIndex + 1)/\(viewModel.questions.count)"
            )
            .padding(.horizontal)
            .padding(.top)
            
            // Question
            if let question = viewModel.currentQuestion {
                ScrollView {
                    Text(question.text)
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    // Different answer UIs based on question type
                    switch question.quizType {
                    case .singleSelect:
                        SingleSelectView(
                            question: question,
                            selectedAnswerId: viewModel.singleSelectAnswers[question.id],
                            onSelect: { answerId in
                                viewModel.selectSingleAnswer(questionId: question.id, answerId: answerId)
                            }
                        )
                        
                    case .multipleSelect:
                        MultipleSelectView(
                            question: question,
                            selectedAnswerIds: viewModel.multipleSelectAnswers[question.id] ?? [],
                            onToggle: { answerId in
                                viewModel.toggleMultipleAnswer(questionId: question.id, answerId: answerId)
                            }
                        )
                        
                    case .switchQuestion:
                        SwitchQuestionView(
                            question: question,
                            isOn: viewModel.switchAnswers[question.id] ?? false,
                            onValueChange: { value in
                                viewModel.setSwitchAnswer(questionId: question.id, value: value)
                            }
                        )
                        
                    case .starRating:
                        StarRatingView(
                            question: question,
                            rating: viewModel.starRatingAnswers[question.id] ?? 0,
                            onRatingChange: { rating in
                                viewModel.setStarRating(questionId: question.id, rating: rating)
                            }
                        )
                    }
                }
                
                // Navigation buttons
                HStack {
                    if viewModel.currentQuestionIndex > 0 {
                        Button("Previous") {
                            viewModel.previousQuestion()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Spacer()
                    
                    Button(viewModel.currentQuestionIndex < viewModel.questions.count - 1 ? "Next" : "Finish") {
                        Task {
                            if viewModel.currentQuestionIndex < viewModel.questions.count - 1 {
                                await viewModel.nextQuestion()
                            } else {
                                await viewModel.calculateResults()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.hasAnsweredCurrentQuestion)
                }
                .padding()
            }
        }
    }
}


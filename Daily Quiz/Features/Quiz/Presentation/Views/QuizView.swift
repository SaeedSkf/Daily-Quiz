import SwiftUI

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
                if viewModel.quizType == .multipleChoice {
                    multipleChoiceQuizView
                } else {
                    crosswordQuizView
                }
                
            case .results:
                resultsView
                
            case .error(let message):
                errorView(message)
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
    
    // Multiple choice quiz view
    private var multipleChoiceQuizView: some View {
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
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    // Answers
                    VStack(spacing: 16) {
                        ForEach(question.answers, id: \.id) { answer in
                            AnswerButton(
                                text: answer.text,
                                isSelected: viewModel.userAnswers[question.id] == answer.id,
                                action: {
                                    viewModel.selectAnswer(questionId: question.id, answerId: answer.id)
                                }
                            )
                        }
                    }
                    .padding()
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
                            await viewModel.nextQuestion()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.hasAnsweredCurrentQuestion)
                }
                .padding()
            }
        }
    }
    
    // Crossword quiz view
    private var crosswordQuizView: some View {
        VStack {
            Text("Crossword Puzzle")
                .font(.title.bold())
                .padding()
            
            // Simple implementation - in a real app this would be more interactive
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(viewModel.crosswordClues, id: \.id) { clue in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(clue.isHorizontal ? "Across" : "Down"): \(clue.clue)")
                                .font(.headline)
                            
                            TextField("Answer", text: Binding(
                                get: { viewModel.crosswordAnswers[clue.id] ?? "" },
                                set: { viewModel.enterCrosswordAnswer(clueId: clue.id, answer: $0) }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.allCharacters)
                            .disableAutocorrection(true)
                        }
                    }
                }
                .padding()
            }
            
            Button("Submit Answers") {
                Task {
                    await viewModel.calculateResults()
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .frame(maxWidth: .infinity)
        }
    }
    
    // Results view
    private var resultsView: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let result = viewModel.quizResult {
                        // Score
                        VStack(spacing: 12) {
                            Text("Quiz Complete!")
                                .font(.largeTitle.bold())
                            
                            HStack {
                                Text("Your Score")
                                    .font(.headline)
                                Spacer()
                                Text("\(result.score)/\(result.totalQuestions)")
                                    .font(.title.bold())
                                    .foregroundStyle(result.isPassing ? .green : .red)
                            }
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            }
                            
                            // Percentage
                            Text("\(Int(result.scorePercentage))%")
                                .font(.system(size: 80, weight: .bold))
                                .foregroundStyle(result.isPassing ? .green : .red)
                            
                            // Pass/Fail message
                            Text(result.isPassing ? "Great job!" : "Keep practicing!")
                                .font(.title3.bold())
                                .foregroundStyle(result.isPassing ? .green : .red)
                        }
                        .padding()
                        
                        // Explanations
                        if viewModel.quizType == .multipleChoice {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Explanations")
                                    .font(.headline)
                                
                                ForEach(viewModel.questions, id: \.id) { question in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(question.text)
                                            .font(.subheadline.bold())
                                        
                                        // Correct answer
                                        if let correctAnswer = question.answers.first(where: { $0.isCorrect }) {
                                            Text("Correct answer: \(correctAnswer.text)")
                                                .font(.callout)
                                                .foregroundStyle(.green)
                                        }
                                        
                                        // User's answer
                                        if let selectedAnswerId = viewModel.userAnswers[question.id],
                                           let selectedAnswer = question.answers.first(where: { $0.id == selectedAnswerId }) {
                                            Text("Your answer: \(selectedAnswer.text)")
                                                .font(.callout)
                                                .foregroundStyle(selectedAnswer.isCorrect ? .green : .red)
                                        }
                                        
                                        // Explanation
                                        Text(question.explanation)
                                            .font(.callout)
                                            .foregroundStyle(.secondary)
                                        
                                        // Related feature
                                        if let relatedFeature = question.relatedFeature {
                                            HStack {
                                                Image(systemName: "link")
                                                Text("Related: \(relatedFeature)")
                                            }
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                        }
                                    }
                                    .padding()
                                    .background {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.tertiarySystemBackground))
                                    }
                                }
                            }
                            .padding()
                        }
                        
                        // Done button
                        Button("Done") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                }
                .padding(.bottom, 100)
            }
            
            // Confetti overlay
            if viewModel.showConfetti {
                ConfettiView()
            }
        }
    }
    
    // Error view
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)
            
            Text("Error")
                .font(.title.bold())
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button("Go Back") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .padding()
    }
}

// Helper for progress bar
struct ProgressBar: View {
    let progress: Double
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(width: geometry.size.width, height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            Text(label)
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

// Helper for answer buttons
struct AnswerButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }
} 
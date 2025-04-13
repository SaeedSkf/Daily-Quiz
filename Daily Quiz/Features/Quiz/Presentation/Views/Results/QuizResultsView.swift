import SwiftUI

struct QuizResultsView: View {
    @Environment(\.dismiss) private var dismiss
    let result: QuizResult?
    let questions: [Question]
    let showConfetti: Bool
    let singleSelectAnswers: [UUID: UUID]
    let multipleSelectAnswers: [UUID: Set<UUID>]
    let switchAnswers: [UUID: Bool]
    let starRatingAnswers: [UUID: Int]
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let result = result {
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
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Question Explanations")
                                .font(.headline)
                            
                            ForEach(questions, id: \.id) { question in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(question.text)
                                        .font(.subheadline.bold())
                                    
                                    // Correct answer based on question type
                                    switch question.quizType {
                                    case .singleSelect:
                                        if let correctAnswer = question.answers.first(where: { $0.isCorrect }) {
                                            Text("Correct answer: \(correctAnswer.text)")
                                                .font(.callout)
                                                .foregroundStyle(.green)
                                        }
                                        
                                        if let selectedAnswerId = singleSelectAnswers[question.id],
                                           let selectedAnswer = question.answers.first(where: { $0.id == selectedAnswerId }) {
                                            Text("Your answer: \(selectedAnswer.text)")
                                                .font(.callout)
                                                .foregroundStyle(selectedAnswer.isCorrect ? .green : .red)
                                        }
                                        
                                    case .multipleSelect:
                                        let correctAnswers = question.answers.filter { $0.isCorrect }
                                        Text("Correct answers: \(correctAnswers.map { $0.text }.joined(separator: ", "))")
                                            .font(.callout)
                                            .foregroundStyle(.green)
                                        
                                        let selectedIds = multipleSelectAnswers[question.id] ?? []
                                        let selectedAnswers = question.answers.filter { selectedIds.contains($0.id) }
                                        if !selectedAnswers.isEmpty {
                                            Text("Your answers: \(selectedAnswers.map { $0.text }.joined(separator: ", "))")
                                                .font(.callout)
                                                .foregroundStyle(
                                                    selectedAnswers.count == correctAnswers.count &&
                                                    selectedAnswers.allSatisfy { $0.isCorrect } ? .green : .red
                                                )
                                        }
                                        
                                    case .switchQuestion:
                                        if let correctAnswer = question.answers.first(where: { $0.isCorrect }) {
                                            Text("Correct answer: \(correctAnswer.text)")
                                                .font(.callout)
                                                .foregroundStyle(.green)
                                        }
                                        
                                        if let selectedValue = switchAnswers[question.id],
                                           let matchingAnswer = question.answers.first(where: { $0.boolValue == selectedValue }) {
                                            Text("Your answer: \(matchingAnswer.text)")
                                                .font(.callout)
                                                .foregroundStyle(matchingAnswer.isCorrect ? .green : .red)
                                        }
                                        
                                    case .starRating:
                                        if let correctAnswer = question.answers.first(where: { $0.isCorrect }) {
                                            Text("Correct answer: \(correctAnswer.text) (\(correctAnswer.ratingValue ?? 0) stars)")
                                                .font(.callout)
                                                .foregroundStyle(.green)
                                        }
                                        
                                        if let selectedRating = starRatingAnswers[question.id],
                                           let matchingAnswer = question.answers.first(where: { $0.ratingValue == selectedRating }) {
                                            Text("Your answer: \(matchingAnswer.text) (\(selectedRating) stars)")
                                                .font(.callout)
                                                .foregroundStyle(matchingAnswer.isCorrect ? .green : .red)
                                        }
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
            if showConfetti {
                ConfettiView()
            }
        }
    }
} 
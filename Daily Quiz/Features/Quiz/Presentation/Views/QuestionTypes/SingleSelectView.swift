import SwiftUI

struct SingleSelectView: View {
    let question: Question
    let selectedAnswerId: UUID?
    let onSelect: (UUID) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(question.answers, id: \.id) { answer in
                AnswerButton(
                    text: answer.text,
                    isSelected: selectedAnswerId == answer.id,
                    action: {
                        onSelect(answer.id)
                    }
                )
            }
        }
        .padding()
    }
} 
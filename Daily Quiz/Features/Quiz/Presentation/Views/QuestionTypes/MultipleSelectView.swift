import SwiftUI

struct MultipleSelectView: View {
    let question: Question
    let selectedAnswerIds: Set<UUID>
    let onToggle: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select all that apply:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            ForEach(question.answers, id: \.id) { answer in
                MultipleSelectButton(
                    text: answer.text,
                    isSelected: selectedAnswerIds.contains(answer.id),
                    action: {
                        onToggle(answer.id)
                    }
                )
            }
        }
        .padding()
    }
} 
import SwiftUI

struct SwitchQuestionView: View {
    let question: Question
    let isOn: Bool
    let onValueChange: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(question.answers, id: \.id) { answer in
                if let boolValue = answer.boolValue {
                    HStack {
                        Text(answer.text)
                            .font(.body)
                        
                        Spacer()
                        
                        if boolValue {
                            Circle()
                                .fill(isOn ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .onTapGesture {
                                    onValueChange(true)
                                }
                        } else {
                            Circle()
                                .fill(!isOn ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 20, height: 20)
                                .onTapGesture {
                                    onValueChange(false)
                                }
                        }
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.secondarySystemBackground))
                    }
                }
            }
        }
        .padding()
    }
} 
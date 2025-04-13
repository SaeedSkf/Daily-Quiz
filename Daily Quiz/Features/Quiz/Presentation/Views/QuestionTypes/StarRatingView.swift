import SwiftUI

struct StarRatingView: View {
    let question: Question
    let rating: Int
    let onRatingChange: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                ForEach(1...question.maxRating, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .foregroundStyle(star <= rating ? .yellow : .gray)
                        .font(.title2)
                        .onTapGesture {
                            onRatingChange(star)
                        }
                }
            }
            
            if rating > 0, let selectedAnswer = question.answers.first(where: { $0.ratingValue == rating }) {
                Text(selectedAnswer.text)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
} 
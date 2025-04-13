import SwiftUI

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
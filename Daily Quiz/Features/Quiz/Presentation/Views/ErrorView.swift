import SwiftUI

struct ErrorView: View {
    @Environment(\.dismiss) private var dismiss
    let message: String
    
    var body: some View {
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
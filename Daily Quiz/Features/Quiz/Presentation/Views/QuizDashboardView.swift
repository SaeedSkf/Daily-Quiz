import SwiftUI
import SwiftData

struct QuizDashboardView: View {
    @StateObject var viewModel: QuizDashboardViewModel
    @State private var showQuiz = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                Text("Daily Quiz")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text("Something went wrong")
                            .font(.headline)
                        
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            viewModel.refresh()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    // Stats Card
                    StatisticsCard(userStats: viewModel.userStats)
                        .padding(.horizontal)
                    
                    // Stage Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Your Stage")
                            .font(.headline)
                        
                        Picker("Stage", selection: $viewModel.selectedStage) {
                            ForEach(MotherhoodStage.allCases) { stage in
                                Text(stage.rawValue).tag(stage)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        Text(viewModel.selectedStage.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Quiz Type Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quiz Type")
                            .font(.headline)
                        
                        Picker("Quiz Type", selection: $viewModel.selectedQuizType) {
                            Text("Multiple Choice").tag(QuizType.multipleChoice)
                            Text("Crossword").tag(QuizType.crossword)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Start Button
                    Button {
                        showQuiz = true
                    } label: {
                        HStack {
                            Text("Start Quiz")
                            Image(systemName: "play.fill")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.isQuizAvailable ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!viewModel.isQuizAvailable)
                    .padding(.horizontal)
                    
                    if !viewModel.isQuizAvailable {
                        Text("You've already taken today's quiz. Come back tomorrow!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
            .navigationDestination(isPresented: $showQuiz) {
                // TODO: We'll implement the factory method later
                QuizView(viewModel: createQuizViewModel())
            }
            .refreshable {
                viewModel.refresh()
            }
            .onAppear {
                viewModel.refresh()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.enableNotifications()
                    } label: {
                        Image(systemName: "bell")
                    }
                }
            }
        }
    }
    
    // Factory method to create QuizViewModel - this would be handled by a dependency injection container in a real app
    private func createQuizViewModel() -> QuizViewModel {
        let repository = QuizRepositoryImpl(dataSource: SwiftDataQuizDataSource(modelContainer: ModelContainer.shared))
        
        let getQuizQuestionsUseCase = GetQuizQuestionsUseCase(repository: repository)
        let getCrosswordCluesUseCase = GetCrosswordCluesUseCase(repository: repository)
        let saveQuizResultUseCase = SaveQuizResultUseCase(repository: repository)
        
        return QuizViewModel(
            getQuizQuestionsUseCase: getQuizQuestionsUseCase,
            getCrosswordCluesUseCase: getCrosswordCluesUseCase,
            saveQuizResultUseCase: saveQuizResultUseCase,
            stage: viewModel.selectedStage,
            quizType: viewModel.selectedQuizType
        )
    }
}

// Helper view for showing user stats
struct StatisticsCard: View {
    let userStats: UserStats?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                StatItem(
                    title: "Current Streak",
                    value: "\(userStats?.currentStreak ?? 0)",
                    iconName: "flame.fill"
                )
                
                Divider()
                
                StatItem(
                    title: "Record Streak",
                    value: "\(userStats?.highestStreak ?? 0)",
                    iconName: "trophy.fill"
                )
                
                Divider()
                
                StatItem(
                    title: "Total Quizzes",
                    value: "\(userStats?.totalQuizzesTaken ?? 0)",
                    iconName: "checkmark.circle.fill"
                )
            }
            
            if let badges = userStats?.badges, !badges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(badges, id: \.self) { badge in
                            Badge(title: badge)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        }
    }
}

// Helper view for showing a single statistic
struct StatItem: View {
    let title: String
    let value: String
    let iconName: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: iconName)
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.title2.bold())
        }
        .frame(maxWidth: .infinity)
    }
}

// Helper view for showing a badge
struct Badge: View {
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: "rosette")
                .foregroundStyle(.yellow)
            Text(title)
                .font(.caption)
                .bold()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background {
            Capsule()
                .fill(Color(.tertiarySystemBackground))
        }
    }
}

// Add a static property to ModelContainer for easy access
extension ModelContainer {
    static var shared: ModelContainer {
        guard let container = try? ModelContainer(for: Question.self, Answer.self, CrosswordClue.self, QuizResult.self, UserStats.self) else {
            fatalError("Failed to create model container")
        }
        return container
    }
} 
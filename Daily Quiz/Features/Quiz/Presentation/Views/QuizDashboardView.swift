import SwiftUI
import SwiftData

struct QuizDashboardView: View {
    @StateObject private var viewModel: QuizDashboardViewModel
    @State private var showQuiz = false
    @Environment(\.dependencyContainer) private var dependencyContainer
    
    init(viewModel: QuizDashboardViewModel? = nil) {
        // If a viewModel is provided, use it (useful for testing)
        // Otherwise, create a stub viewModel that will load data when the container is available
        if let providedViewModel = viewModel {
            _viewModel = StateObject(wrappedValue: providedViewModel)
        } else {
            // Create with a stub repository - will be replaced with real data later
            _viewModel = StateObject(wrappedValue: QuizDashboardViewModel(
                checkDailyQuizAvailabilityUseCase: CheckDailyQuizAvailabilityUseCase(repository: StubQuizRepository()),
                getUserStatsUseCase: GetUserStatsUseCase(repository: StubQuizRepository()),
                quizRepository: StubQuizRepository()
            ))
        }
    }
    
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
//                    .disabled(!viewModel.isQuizAvailable)
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
                if let container = dependencyContainer {
                    QuizView(viewModel: container.makeQuizViewModel(
                        stage: viewModel.selectedStage
                    ))
                }
            }
            .refreshable {
                viewModel.refresh()
            }
            .onAppear {
                // Instead of replacing the viewModel, just load real data when possible
                if viewModel.isUsingStubRepository, let container = dependencyContainer {
                    // Load data from the real repository without replacing the viewModel
                    Task {
                        await viewModel.loadDataFromRepository(container.container.resolve(QuizRepository.self)!)
                    }
                } else {
                    viewModel.refresh()
                }
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

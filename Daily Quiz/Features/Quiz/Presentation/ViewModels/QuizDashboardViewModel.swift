import Foundation
import SwiftData
import Combine

class QuizDashboardViewModel: ObservableObject {
    // Dependencies
    private let checkDailyQuizAvailabilityUseCase: CheckDailyQuizAvailabilityUseCase
    private let getUserStatsUseCase: GetUserStatsUseCase
    private let quizRepository: QuizRepository
    
    // Published properties
    @Published var selectedStage: MotherhoodStage = .pregnant
    @Published var selectedQuizType: QuizType = .multipleChoice
    @Published var isQuizAvailable = false
    @Published var userStats: UserStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init(
        checkDailyQuizAvailabilityUseCase: CheckDailyQuizAvailabilityUseCase,
        getUserStatsUseCase: GetUserStatsUseCase,
        quizRepository: QuizRepository
    ) {
        self.checkDailyQuizAvailabilityUseCase = checkDailyQuizAvailabilityUseCase
        self.getUserStatsUseCase = getUserStatsUseCase
        self.quizRepository = quizRepository
        
        // Load data
        Task {
            await loadData()
        }
    }
    
    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Preload quiz data if needed
            try await quizRepository.preloadInitialQuizData()
            
            // Check if daily quiz is available
            isQuizAvailable = try await checkDailyQuizAvailabilityUseCase.execute()
            
            // Get user stats
            userStats = try await getUserStatsUseCase.execute()
            
            isLoading = false
        } catch {
            errorMessage = "Failed to load quiz data: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // Refresh data (for pull-to-refresh)
    func refresh() {
        Task {
            await loadData()
        }
    }
    
    // Enable notifications
    func enableNotifications() {
        NotificationManager.shared.requestPermission { granted in
            if granted {
                NotificationManager.shared.scheduleDailyQuizReminder()
            }
        }
    }
} 
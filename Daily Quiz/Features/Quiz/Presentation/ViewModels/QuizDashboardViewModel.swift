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
    @Published var isQuizAvailable = false
    @Published var userStats: UserStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Flag to check if using stub repository for initialization
    var isUsingStubRepository: Bool {
        if let repository = quizRepository as? StubQuizRepository {
            return repository.isUsingStubRepository
        }
        return false
    }
    
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
    
    // Load data from a specific repository (used when starting with stub and getting real repository later)
    @MainActor
    func loadDataFromRepository(_ repository: QuizRepository) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Preload quiz data if needed
            try await repository.preloadInitialQuizData()
            
            // Check if daily quiz is available
            isQuizAvailable = try await repository.isDailyQuizAvailable()
            
            // Get user stats
            userStats = try await repository.getUserStats()
            
            isLoading = false
        } catch {
            errorMessage = "Failed to load quiz data: \(error.localizedDescription)"
            isLoading = false
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
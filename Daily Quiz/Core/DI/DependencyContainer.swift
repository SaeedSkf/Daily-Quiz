import Foundation
import Swinject
import SwiftData
import SwiftUI

// MARK: - Environment Key for DependencyContainer
struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue: DependencyContainer? = nil
}

extension EnvironmentValues {
    var dependencyContainer: DependencyContainer? {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// Extension to easily get dependencies from the environment
extension View {
    func inject<T>(_ keyPath: KeyPath<DependencyContainer, T>) -> T? {
        @Environment(\.dependencyContainer) var container
        return container?[keyPath: keyPath]
    }
}

// MARK: - DependencyContainer
class DependencyContainer {
    let container: Container
    
    init(modelContainer: ModelContainer) {
        self.container = Container()
        registerDependencies(with: modelContainer)
    }
    
    private func registerDependencies(with modelContainer: ModelContainer) {
        registerDataSources(with: modelContainer)
        registerRepositories()
        registerUseCases()
    }
    
    private func registerDataSources(with modelContainer: ModelContainer) {
        container.register(ModelContainer.self) { _ in
            return modelContainer
        }.inObjectScope(.container)
        
        container.register(QuizDataSource.self) { resolver in
            let modelContainer = resolver.resolve(ModelContainer.self)!
            return SwiftDataQuizDataSource(modelContainer: modelContainer)
        }.inObjectScope(.container)
    }
    
    private func registerRepositories() {
        container.register(QuizRepository.self) { resolver in
            let dataSource = resolver.resolve(QuizDataSource.self)!
            return QuizRepositoryImpl(dataSource: dataSource)
        }.inObjectScope(.container)
    }
    
    private func registerUseCases() {
        container.register(GetQuizQuestionsUseCase.self) { resolver in
            let repository = resolver.resolve(QuizRepository.self)!
            return GetQuizQuestionsUseCase(repository: repository)
        }
        
        container.register(CheckDailyQuizAvailabilityUseCase.self) { resolver in
            let repository = resolver.resolve(QuizRepository.self)!
            return CheckDailyQuizAvailabilityUseCase(repository: repository)
        }
        
        container.register(SaveQuizResultUseCase.self) { resolver in
            let repository = resolver.resolve(QuizRepository.self)!
            return SaveQuizResultUseCase(repository: repository)
        }
        
        container.register(GetUserStatsUseCase.self) { resolver in
            let repository = resolver.resolve(QuizRepository.self)!
            return GetUserStatsUseCase(repository: repository)
        }
    }
    
    // MARK: - ViewModel Factory Methods
    func makeQuizDashboardViewModel() -> QuizDashboardViewModel {
        let checkDailyQuizAvailabilityUseCase = container.resolve(CheckDailyQuizAvailabilityUseCase.self)!
        let getUserStatsUseCase = container.resolve(GetUserStatsUseCase.self)!
        let repository = container.resolve(QuizRepository.self)!
        
        return QuizDashboardViewModel(
            checkDailyQuizAvailabilityUseCase: checkDailyQuizAvailabilityUseCase,
            getUserStatsUseCase: getUserStatsUseCase,
            quizRepository: repository
        )
    }
    
    func makeQuizViewModel(stage: MotherhoodStage) -> QuizViewModel {
        let getQuizQuestionsUseCase = container.resolve(GetQuizQuestionsUseCase.self)!
        let saveQuizResultUseCase = container.resolve(SaveQuizResultUseCase.self)!
        
        return QuizViewModel(
            getQuizQuestionsUseCase: getQuizQuestionsUseCase,
            saveQuizResultUseCase: saveQuizResultUseCase,
            stage: stage
        )
    }
} 
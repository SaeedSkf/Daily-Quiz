import Foundation
import Swinject
import SwiftData

// MARK: - DependencyContainer
class DependencyContainer {
    static let shared = DependencyContainer()
    
    let container: Container
    
    private init() {
        container = Container()
        registerDependencies()
    }
    
    private func registerDependencies() {
        registerDataSources()
        registerRepositories()
        registerUseCases()
    }
    
    private func registerDataSources() {
        container.register(ModelContainer.self) { _ in
            return ModelContainer.shared
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
        
        container.register(GetCrosswordCluesUseCase.self) { resolver in
            let repository = resolver.resolve(QuizRepository.self)!
            return GetCrosswordCluesUseCase(repository: repository)
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
    
    func makeQuizViewModel(stage: MotherhoodStage, quizType: QuizType) -> QuizViewModel {
        let getQuizQuestionsUseCase = container.resolve(GetQuizQuestionsUseCase.self)!
        let getCrosswordCluesUseCase = container.resolve(GetCrosswordCluesUseCase.self)!
        let saveQuizResultUseCase = container.resolve(SaveQuizResultUseCase.self)!
        
        return QuizViewModel(
            getQuizQuestionsUseCase: getQuizQuestionsUseCase,
            getCrosswordCluesUseCase: getCrosswordCluesUseCase,
            saveQuizResultUseCase: saveQuizResultUseCase,
            stage: stage,
            quizType: quizType
        )
    }
} 
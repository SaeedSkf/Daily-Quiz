# Daily Quiz

A SwiftUI application that provides daily quizzes for women during different stages of motherhood, including those trying to conceive, pregnant women, and those in the postpartum period.

## Features

- **Daily Quizzes**: Take daily quizzes specific to your motherhood stage
- **Multiple Quiz Types**: Includes single-select, multiple-select, true/false, and star rating questions
- **Progress Tracking**: Track your quiz scores and learning progress
- **Streaks & Achievements**: Maintain a daily streak and earn badges
- **Personalization**: Content tailored to your current motherhood stage
- **Explanations**: Learn from detailed explanations for each question

## Technologies

- SwiftUI
- SwiftData for persistence
- MVVM architecture
- Dependency Injection using Swinject
- Notifications for daily reminders

## Getting Started

### Prerequisites

- Xcode 15 or later
- iOS 17.0+
- macOS 14.0+ (for macOS version)

### Installation

1. Clone the repository
2. Open `Daily Quiz.xcodeproj` in Xcode
3. Build and run the project on your device or simulator

## Project Structure

- **Core**: Contains the application's domain models, data access layer, and dependency injection setup
- **Features**: Contains feature-specific implementations, organized by domain
  - **Quiz**: The main quiz feature implementation
- **Resources**: Contains app resources and assets

## License

This project is proprietary and not licensed for redistribution.

## Acknowledgments

- Created by Saeed 
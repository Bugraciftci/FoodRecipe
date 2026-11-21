import Foundation
import Combine

@MainActor
final class CookingSessionViewModel: ObservableObject {
    let recipe: Recipe
    let servings: Int

    @Published private(set) var currentStepIndex: Int = 0
    @Published private(set) var completedStepNumbers: Set<Int> = []
    @Published private(set) var remainingSeconds: Int = 0
    @Published private(set) var isTimerRunning: Bool = false

    private var timerCancellable: AnyCancellable?

    init(recipe: Recipe, servings: Int) {
        self.recipe = recipe
        self.servings = servings
        if let firstDuration = recipe.steps.first?.durationSeconds {
            self.remainingSeconds = firstDuration
        }
    }

    var currentStep: CookingStep? {
        guard recipe.steps.indices.contains(currentStepIndex) else { return nil }
        return recipe.steps[currentStepIndex]
    }

    var progressFraction: Double {
        guard !recipe.steps.isEmpty else { return 1.0 }
        return Double(currentStepIndex + 1) / Double(recipe.steps.count)
    }

    var formattedRemainingTime: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    func toggleTimer() {
        if isTimerRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }

    func startTimer() {
        if remainingSeconds <= 0, let stepDuration = currentStep?.durationSeconds {
            remainingSeconds = stepDuration
        }
        guard remainingSeconds > 0 else { return }
        isTimerRunning = true
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                } else {
                    self.pauseTimer()
                }
            }
    }

    func pauseTimer() {
        isTimerRunning = false
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func resetStepTimer() {
        pauseTimer()
        remainingSeconds = currentStep?.durationSeconds ?? 180
    }

    func completeCurrentStepAndAdvance() {
        if let step = currentStep {
            completedStepNumbers.insert(step.stepNumber)
        }
        if currentStepIndex + 1 < recipe.steps.count {
            currentStepIndex += 1
            resetStepTimer()
        } else {
            pauseTimer()
        }
    }

    func goToPreviousStep() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
        resetStepTimer()
    }
}

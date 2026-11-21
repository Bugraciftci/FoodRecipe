import SwiftUI

struct CookingSessionView: View {
    @StateObject var viewModel: CookingSessionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                progressHeader

                if let step = viewModel.currentStep {
                    stepCard(step)
                    timerConsole
                }

                Spacer()
                navigationControls
            }
            .padding(20)
            .background(CulinaryTheme.background.ignoresSafeArea())
            .navigationTitle("Hands-Free Cooking Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Finish") {
                        viewModel.pauseTimer()
                        dismiss()
                    }
                    .foregroundStyle(CulinaryTheme.saffronAccent)
                }
            }
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Step \(viewModel.currentStepIndex + 1) of \(viewModel.recipe.steps.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(CulinaryTheme.saffronAccent)
                Spacer()
                Text("\(viewModel.servings) Servings")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CulinaryTheme.textSecondary)
            }

            ProgressView(value: viewModel.progressFraction)
                .tint(CulinaryTheme.saffronAccent)
        }
    }

    private func stepCard(_ step: CookingStep) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(step.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(CulinaryTheme.textPrimary)

            Text(step.instruction)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(CulinaryTheme.textPrimary.opacity(0.92))
                .lineSpacing(5)

            if let tip = step.chefTip {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(CulinaryTheme.carbAmber)
                    Text(tip)
                        .font(.caption)
                        .foregroundStyle(CulinaryTheme.carbAmber)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(CulinaryTheme.elevatedSurface)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(CulinaryTheme.cardBackground)
        )
    }

    private var timerConsole: some View {
        VStack(spacing: 12) {
            Text("STEP TIMER")
                .font(.caption2.weight(.bold))
                .foregroundStyle(CulinaryTheme.textSecondary)

            Text(viewModel.formattedRemainingTime)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundStyle(viewModel.isTimerRunning ? CulinaryTheme.herbEmerald : CulinaryTheme.textPrimary)

            HStack(spacing: 16) {
                Button {
                    viewModel.toggleTimer()
                } label: {
                    Label(
                        viewModel.isTimerRunning ? "Pause Timer" : "Start Timer",
                        systemImage: viewModel.isTimerRunning ? "pause.fill" : "play.fill"
                    )
                    .font(.subheadline.weight(.bold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(CulinaryTheme.saffronAccent))
                    .foregroundStyle(Color.black)
                }

                Button {
                    viewModel.resetStepTimer()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(CulinaryTheme.elevatedSurface))
                        .foregroundStyle(CulinaryTheme.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(CulinaryTheme.cardBackground)
        )
    }

    private var navigationControls: some View {
        HStack(spacing: 14) {
            Button {
                viewModel.goToPreviousStep()
            } label: {
                Label("Previous", systemImage: "chevron.left")
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(CulinaryTheme.elevatedSurface)
                    )
                    .foregroundStyle(CulinaryTheme.textPrimary)
            }
            .disabled(viewModel.currentStepIndex == 0)
            .opacity(viewModel.currentStepIndex == 0 ? 0.45 : 1)

            Button {
                if viewModel.currentStepIndex + 1 < viewModel.recipe.steps.count {
                    viewModel.completeCurrentStepAndAdvance()
                } else {
                    viewModel.pauseTimer()
                    dismiss()
                }
            } label: {
                Label(
                    viewModel.currentStepIndex + 1 < viewModel.recipe.steps.count ? "Next Step" : "Complete Dish",
                    systemImage: "checkmark.circle.fill"
                )
                .font(.subheadline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(CulinaryTheme.heroGradient)
                )
                .foregroundStyle(Color.white)
            }
        }
    }
}

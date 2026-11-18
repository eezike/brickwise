import Foundation
import Combine

/// Drives the build: which step is active, what is already built, what to show as a hologram.
@MainActor
final class BuildSession: ObservableObject {
    let build: Build
    @Published private(set) var stepIndex: Int = 0   // zero-based into build.steps

    init(build: Build) {
        self.build = build
    }

    var currentStep: Build.Step { build.steps[stepIndex] }
    var stepNumber: Int { stepIndex + 1 }
    var stepCount: Int { build.steps.count }
    var progress: Double { Double(stepNumber) / Double(stepCount) }
    var isFirst: Bool { stepIndex == 0 }
    var isLast: Bool { stepIndex == stepCount - 1 }

    /// Pieces from every earlier step, rendered as solid bricks.
    var placed: [Build.Placement] {
        build.steps[..<stepIndex].flatMap(\.placements)
    }

    /// Pieces for the current step, rendered as the glowing hologram.
    var hologram: [Build.Placement] {
        currentStep.placements
    }

    func next() {
        guard !isLast else { return }
        stepIndex += 1
    }

    func back() {
        guard !isFirst else { return }
        stepIndex -= 1
    }

    func restart() {
        stepIndex = 0
    }
}

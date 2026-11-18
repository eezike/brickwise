import SwiftUI

/// Minimal-HUD build screen (concept 3B): camera first, one instruction, big Next.
struct BuildScreen: View {
    @ObservedObject var session: BuildSession

    var body: some View {
        ZStack {
            ARBuildView(session: session)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                topBar
                Spacer()
                if !session.markerVisible {
                    markerPrompt
                }
                instructionCard
                controlBar
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background(Theme.background)
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
    }

    // MARK: Pieces

    private var topBar: some View {
        HStack {
            circleButton(systemName: "arrow.counterclockwise", label: "Start over") {
                session.restart()
            }
            Spacer()
            HStack(spacing: 6) {
                Text("Step \(session.stepNumber)")
                    .fontWeight(.semibold)
                Text("of \(session.stepCount)")
                    .foregroundStyle(Theme.secondary)
            }
            .font(.subheadline)
            .padding(.horizontal, 18)
            .frame(height: 44)
            .background(Theme.background.opacity(0.8), in: Capsule())
            Spacer()
            circleButton(
                systemName: session.showBuiltPieces ? "eye.fill" : "eye",
                label: "Preview finished pieces"
            ) {
                session.showBuiltPieces.toggle()
            }
        }
        .foregroundStyle(Theme.text)
    }

    private var markerPrompt: some View {
        HStack(spacing: 10) {
            Image(systemName: "viewfinder")
                .foregroundStyle(Theme.holo)
            Text("Point the camera at the marker")
                .font(.subheadline.weight(.medium))
        }
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Theme.background.opacity(0.85), in: Capsule())
    }

    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.currentStep.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.text)
            Text(session.currentStep.instruction)
                .font(.subheadline)
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.background.opacity(0.9), in: RoundedRectangle(cornerRadius: 18))
    }

    private var controlBar: some View {
        HStack(spacing: 12) {
            Button {
                session.back()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .frame(width: 56, height: 56)
                    .background(Theme.surface, in: Circle())
                    .overlay(Circle().stroke(Theme.border, lineWidth: 1))
                    .foregroundStyle(Theme.text)
            }
            .accessibilityLabel("Previous step")
            .opacity(session.isFirst ? 0.4 : 1)

            Button {
                session.isLast ? session.restart() : session.next()
            } label: {
                HStack(spacing: 8) {
                    Text(session.isLast ? "Start over" : "Next step")
                    Image(systemName: session.isLast ? "arrow.counterclockwise" : "chevron.right")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Theme.holo, in: Capsule())
                .foregroundStyle(Theme.onHolo)
            }
        }
    }

    private func circleButton(systemName: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .background(Theme.background.opacity(0.8), in: Circle())
        }
        .accessibilityLabel(label)
    }
}

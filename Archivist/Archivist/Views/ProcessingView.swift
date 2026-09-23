import SwiftUI
import Combine

@MainActor
final class ProcessingState: ObservableObject {

    @Published var isActive = false
    @Published var title = ""
    @Published var inputName = ""
    @Published var sizeLabel = ""
    @Published var progress: Double = 0
    @Published var logLines: [String] = []
    @Published var statusText = "PROCESSING"
    @Published var errorMessage: String?

    func run(
        title: String,
        inputName: String,
        sizeLabel: String,
        steps: [String],
        work: @escaping () throws -> String
    ) {
        self.title = title
        self.inputName = inputName
        self.sizeLabel = sizeLabel
        self.progress = 0
        self.logLines = []
        self.statusText = "PROCESSING"
        self.errorMessage = nil
        self.isActive = true

        Task { @MainActor in

            // Animate the terminal while the real PDF operation runs.
            let animationTask = Task { @MainActor in
                for (index, step) in steps.enumerated() {
                    try? await Task.sleep(
                        nanoseconds: 350_000_000
                    )

                    self.logLines.append(step)

                    self.progress = min(
                        0.9,
                        Double(index + 1) / Double(steps.count) * 0.9
                    )
                }
            }

            // Run the actual PDF operation away from the main UI thread.
            let result: Result<String, Error> = await withCheckedContinuation {
                continuation in

                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        let result = try work()

                        continuation.resume(
                            returning: .success(result)
                        )
                    } catch {
                        continuation.resume(
                            returning: .failure(error)
                        )
                    }
                }
            }

            _ = await animationTask.result

            switch result {

            case .success(let resultLine):
                self.logLines.append(resultLine)
                self.progress = 1.0
                self.statusText = "DONE"

            case .failure(let error):
                self.logLines.append(
                    "ERROR: \(error.localizedDescription)"
                )

                self.errorMessage = error.localizedDescription
                self.statusText = "FAILED"
            }

            try? await Task.sleep(
                nanoseconds: 700_000_000
            )
        }
    }

    func dismiss() {
        isActive = false
    }
}


struct ProcessingOverlay: View {

    @ObservedObject var state: ProcessingState

    var body: some View {

        if state.isActive {

            ZStack {

                Color.black
                    .opacity(0.35)
                    .ignoresSafeArea()

                VStack(spacing: 12) {

                    StatusTerminal(
                        title: state.title,
                        inputName: state.inputName,
                        sizeLabel: state.sizeLabel,
                        progress: state.progress,
                        logLines: state.logLines,
                        statusText: state.statusText
                    )

                    if state.statusText != "PROCESSING" {

                        RetroButton(
                            title: "OK",
                            action: state.dismiss
                        )
                    }
                }
            }
            .transition(.opacity)
        }
    }
}

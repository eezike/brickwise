import SwiftUI

@main
@MainActor
struct BrickwiseApp: App {
    @StateObject private var session: BuildSession

    init() {
        do {
            let build = try Build.load(named: "demo-cabin")
            _session = StateObject(wrappedValue: BuildSession(build: build))
        } catch {
            fatalError("Could not load demo-cabin.json: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            BuildScreen(session: session)
        }
    }
}

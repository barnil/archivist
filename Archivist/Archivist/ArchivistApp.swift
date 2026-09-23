import SwiftUI

@main
struct ArchivistApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 640, idealWidth: 720, minHeight: 560, idealHeight: 600)
                .background(RetroPalette.background)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 720, height: 600)
    }
}

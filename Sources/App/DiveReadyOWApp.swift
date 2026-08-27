import SwiftUI

@main
@MainActor
struct DiveReadyOWApp: App {
    @State private var store = StudyStore()
    private let launchData = CatalogLoader.bundled()

    var body: some Scene {
        WindowGroup {
            AppShellView(
                catalog: launchData.catalog,
                loadMessage: launchData.loadMessage,
                store: store
            )
            .tint(AppTheme.aqua)
            .preferredColorScheme(.dark)
        }
    }
}

import SwiftUI

@main
struct HitchApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(ProgressStore.shared)
                .tint(.ink)
        }
    }
}

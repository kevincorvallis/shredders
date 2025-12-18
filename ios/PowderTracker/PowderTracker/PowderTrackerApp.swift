import SwiftUI

@main
struct PowderTrackerApp: App {
    @State private var showIntro = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .opacity(showIntro ? 0.3 : 1)

                if showIntro {
                    IntroView(showIntro: $showIntro)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showIntro)
        }
    }
}

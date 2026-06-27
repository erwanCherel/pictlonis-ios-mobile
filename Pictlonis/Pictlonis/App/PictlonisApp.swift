import SwiftUI
import FirebaseCore
#if DEBUG
import FirebaseAppCheck
#endif
#if canImport(FirebaseInAppMessaging)
import FirebaseInAppMessaging
#endif

@main
struct PictionisApp: App {
    @StateObject private var router = AppRouter()

    init() {
        FirebaseApp.configure()
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .onOpenURL { url in
                    guard url.scheme == "pictionis" else { return }
                    guard url.host == "join",
                          let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
                          let room = comps.queryItems?.first(where: { $0.name == "room" })?.value
                    else { return }
                    router.pendingRoomId = room
                }
        }
    }
}

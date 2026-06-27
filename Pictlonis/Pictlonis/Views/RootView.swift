import SwiftUI
import FirebaseAuth

struct RootView: View {
    @StateObject private var auth = AuthViewModel()

    var body: some View {
        Group {
            if auth.user != nil {
                RoomListView()
            } else {
                AuthView()
            }
        }
        .environmentObject(auth)
    }
}

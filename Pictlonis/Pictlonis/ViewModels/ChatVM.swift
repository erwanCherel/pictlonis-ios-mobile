import Foundation
import Combine
import FirebaseFirestore

final class ChatVM: ObservableObject {
@Published var messages: [ChatMessage] = []
private let db = Firestore.firestore()
private var listener: ListenerRegistration?
let roomId: String


init(roomId: String) { self.roomId = roomId }


func start() {
listener = db.collection("rooms").document(roomId)
.collection("chat")
.order(by: "createdAt", descending: false)
.addSnapshotListener { [weak self] snap, _ in
guard let self = self else { return }
self.messages = snap?.documents.compactMap(ChatMessage.init(doc:)) ?? []
}
}


func stop() { listener?.remove() }


func send(uid: String, text: String, isGuess: Bool = true) async throws {
let ref = db.collection("rooms").document(roomId).collection("chat").document()
try await ref.setData([
"uid": uid,
"text": text,
"createdAt": FieldValue.serverTimestamp(),
"isGuess": isGuess,
"isCorrect": false
])
}
}

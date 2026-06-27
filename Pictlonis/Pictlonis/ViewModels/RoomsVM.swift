// ViewModels/RoomsVM.swift
import Foundation
import Combine
import FirebaseFirestore


@MainActor
extension RoomsVM {
func rename(roomId: String, to newName: String) async throws {
try await db.collection("rooms").document(roomId)
.updateData(["name": newName, "updatedAt": FieldValue.serverTimestamp()])
}
@MainActor
    func join(roomId: String, uid: String) async throws {
        let ref = Firestore.firestore().collection("rooms").document(roomId)
        try await ref.setData([
            "members": FieldValue.arrayUnion([uid])
        ], merge: true)
    }
}
final class RoomsVM: ObservableObject {
    @Published var rooms: [Room] = []
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func start() {
        listener = db.collection("rooms")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                self.rooms = snapshot?.documents.compactMap(Room.init(doc:)) ?? []
            }
    }

    func stop() { listener?.remove() }

    func create(name: String, ownerUid: String) async throws {
        let ref = db.collection("rooms").document()
        try await ref.setData([
            "name": name,
            "createdAt": FieldValue.serverTimestamp(),
            "ownerUid": ownerUid,
            "status": "lobby",
            "currentRound": 0,
            "currentWordMasked": ""
        ])
    }

    // Quand tu connais le dessinateur :
    func setDrawer(roomId: String, uid: String) async throws {
        try await db.collection("rooms").document(roomId)
            .updateData(["drawerUid": uid])
    }

    // Pour retirer le dessinateur :
    func clearDrawer(roomId: String) async throws {
        try await db.collection("rooms").document(roomId)
            .updateData(["drawerUid": FieldValue.delete()])
    }
}

import Foundation
import FirebaseFirestore

// MARK: - ROOM MODEL
struct Room: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var createdAt: Date?
    var ownerUid: String
    var status: String          // lobby, playing, ended
    var currentRound: Int
    var currentWordMasked: String
    var drawerUid: String?
    
    // Optionnel pour affichage
    var updatedAt: Date?
}

extension Room {
    init?(doc: DocumentSnapshot) {
        guard let data = doc.data() else { return nil }
        self.id = doc.documentID
        self.name = data["name"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
        self.ownerUid = data["ownerUid"] as? String ?? ""
        self.status = data["status"] as? String ?? "lobby"
        self.currentRound = data["currentRound"] as? Int ?? 0
        self.currentWordMasked = data["currentWordMasked"] as? String ?? ""
        self.drawerUid = data["drawerUid"] as? String
    }
}

// MARK: - CHAT MESSAGE
struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String?
    var uid: String
    var text: String
    var createdAt: Date?
    var isGuess: Bool
    var isCorrect: Bool
}

extension ChatMessage {
    init?(doc: DocumentSnapshot) {
        guard let data = doc.data() else { return nil }
        self.id = doc.documentID
        self.uid = data["uid"] as? String ?? ""
        self.text = data["text"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        self.isGuess = data["isGuess"] as? Bool ?? true
        self.isCorrect = data["isCorrect"] as? Bool ?? false
    }
}

// MARK: - DRAWING
struct StrokePoint: Codable, Hashable {
    let x: Double
    let y: Double
}

// MARK: - USER PROFILE
struct UserProfile: Identifiable, Codable {
    var id: String { uid }
    let uid: String
    var email: String
    var firstName: String
    var lastName: String
    var username: String        // unique handle, lowercase
    var avatar: String          // key or URL
    var createdAt: Date?
    var updatedAt: Date?
    var lastLoginAt: Date?
    var totalScore: Int
    var gamesCount: Int
}

extension UserProfile {
    init?(doc: DocumentSnapshot) {
        guard let d = doc.data() else { return nil }
        self.uid = doc.documentID
        self.email = d["email"] as? String ?? ""
        self.firstName = d["firstName"] as? String ?? ""
        self.lastName = d["lastName"] as? String ?? ""
        self.username = d["username"] as? String ?? ""
        self.avatar = d["avatar"] as? String ?? "astronaut"
        self.createdAt = (d["createdAt"] as? Timestamp)?.dateValue()
        self.updatedAt = (d["updatedAt"] as? Timestamp)?.dateValue()
        self.lastLoginAt = (d["lastLoginAt"] as? Timestamp)?.dateValue()
        self.totalScore = d["totalScore"] as? Int ?? 0
        self.gamesCount = d["gamesCount"] as? Int ?? 0
    }
}

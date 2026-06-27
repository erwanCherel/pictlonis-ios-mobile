import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var profile: UserProfile?
    private let db = Firestore.firestore()
    
    
    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                if let uid = user?.uid { await self?.loadProfile(uid: uid) }
            }
        }
    }
    
    
    func signUp(email: String, password: String, first: String, last: String, username: String, avatar: String) async throws {
        let lowered = username.lowercased()
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let uid = result.user.uid
        
        
        // Réservation du handle + création user (batch atomique)
        let batch = db.batch()
        let handleRef = db.collection("handles").document(lowered)
        let userRef = db.collection("users").document(uid)
        
        
        // si le handle existe déjà, l’écriture échouera côté règles (ou côté client après get())
        // pour UX, on peut vérifier avant :
        let snap = try await handleRef.getDocument()
        if snap.exists { throw NSError(domain: "signup", code: 409, userInfo: [NSLocalizedDescriptionKey: "Pseudo déjà pris"]) }
        
        
        batch.setData(["uid": uid], forDocument: handleRef)
        batch.setData([
            "email": email,
            "firstName": first,
            "lastName": last,
            "username": lowered,
            "avatar": avatar,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
            "lastLoginAt": FieldValue.serverTimestamp(),
            "totalScore": 0,
            "gamesCount": 0
        ], forDocument: userRef)
        
        
        try await batch.commit()
        await loadProfile(uid: uid)
    }
    
    
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let uid = result.user.uid
        try await db.collection("users").document(uid)
            .updateData(["lastLoginAt": FieldValue.serverTimestamp()])
        await loadProfile(uid: uid)
    }
    
    
    func updateProfile(first: String, last: String, avatar: String) async throws {
        guard let uid = user?.uid else { return }
        try await db.collection("users").document(uid).updateData([
            "firstName": first,
            "lastName":  last,
            "avatar":    avatar,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        await loadProfile(uid: uid)
    }
    
    func changeUsername(to newUsername: String) async throws {
        guard let uid = user?.uid, let old = profile?.username else { return }
        let lowered = newUsername.lowercased()
        if lowered == old { return }
        
        let handles = db.collection("handles")
        let users   = db.collection("users")
        
        // vérifie la dispo
        if try await handles.document(lowered).getDocument().exists {
            throw NSError(domain: "profile", code: 409,
                          userInfo: [NSLocalizedDescriptionKey: "Pseudo déjà pris"])
        }
        
        let batch = db.batch()
        batch.deleteDocument(handles.document(old))
        batch.setData(["uid": uid], forDocument: handles.document(lowered))
        batch.updateData(["username": lowered,
                          "updatedAt": FieldValue.serverTimestamp()],
                         forDocument: users.document(uid))
        try await batch.commit()
        await loadProfile(uid: uid)
    }
    
    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    func signOut() throws {
            try Auth.auth().signOut()
            user = nil
            profile = nil
        }
    func deleteAccount() async throws {
        guard let uid = user?.uid else { return }
        if let p = profile {
            let batch = db.batch()
            batch.deleteDocument(db.collection("handles").document(p.username))
            batch.deleteDocument(db.collection("users").document(uid))
            try await batch.commit()
        }
        try await user?.delete()
        self.user = nil
        self.profile = nil
    }
    
    func loadProfile(uid: String) async {
        let doc = try? await db.collection("users").document(uid).getDocument()
        if let doc, let p = UserProfile(doc: doc) { self.profile = p }
    }}

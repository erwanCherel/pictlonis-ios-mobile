import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var auth: AuthViewModel

    @State private var first = ""
    @State private var last  = ""
    @State private var avatar = "astronaut"
    @State private var newUsername = ""
    @State private var games: [QueryDocumentSnapshot] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                // --- Fond dégradé moderne ---
                LinearGradient(
                    colors: [Color.blue.opacity(0.9), Color.purple.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    if let p = auth.profile {
                        ScrollView {
                            VStack(spacing: 24) {

                                // ------ AVATAR + NOM ------
                                VStack(spacing: 12) {
                                    AvatarView(
                                        tokenString: avatar,
                                        size: 110,
                                        seed: p.username
                                    )
                                    .shadow(radius: 8)

                                    Text("@\(p.username)")
                                        .font(.title2.bold())
                                        .foregroundStyle(.white)

                                    Text("\(p.firstName) \(p.lastName)")
                                        .font(.headline)
                                        .foregroundStyle(.white.opacity(0.9))
                                }
                                .padding(.top, 20)

                                // ------ BOUTON CHANGER AVATAR ------
                                NavigationLink {
                                    AvatarPickerView(
                                        selectedToken: $avatar,
                                        seed: p.username,
                                        onConfirm: { newToken in
                                            Task {
                                                do {
                                                    try await auth.updateProfile(first: first, last: last, avatar: newToken)
                                                    avatar = newToken
                                                } catch { errorMessage = error.localizedDescription }
                                            }
                                        }
                                    )
                                } label: {
                                    Text("Changer l’avatar")
                                        .font(.subheadline)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(.white.opacity(0.2))
                                        .clipShape(Capsule())
                                        .foregroundStyle(.white)
                                }

                                // ------ CARD INFOS ------
                                VStack(spacing: 16) {
                                    Text("Informations personnelles")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    TextField("Prénom", text: $first)
                                        .textFieldStyle(ProfileFieldStyle())

                                    TextField("Nom", text: $last)
                                        .textFieldStyle(ProfileFieldStyle())

                                    Button("Enregistrer") {
                                        Task {
                                            do {
                                                try await auth.updateProfile(first: first, last: last, avatar: avatar)
                                            } catch { errorMessage = error.localizedDescription }
                                        }
                                    }
                                    .buttonStyle(ProfilePrimaryButton())
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding(.horizontal)

                                // ------ PSEUDO ------
                                VStack(spacing: 16) {
                                    Text("Pseudo")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    HStack {
                                        Text("Actuel : \(p.username)")
                                        Spacer()
                                    }
                                    .foregroundStyle(.secondary)

                                    TextField("Nouveau pseudo", text: $newUsername)
                                        .textFieldStyle(ProfileFieldStyle())

                                    Button("Changer le pseudo") {
                                        Task {
                                            do { try await auth.changeUsername(to: newUsername) }
                                            catch { errorMessage = error.localizedDescription }
                                        }
                                    }
                                    .buttonStyle(ProfilePrimaryButton())
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding(.horizontal)

                                // ------ STATS ------
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Statistiques")
                                        .font(.headline)

                                    ProfileStatRow(label: "Score total", value: String(p.totalScore))
                                    ProfileStatRow(label: "Parties jouées", value: String(p.gamesCount))

                                    if let lastLogin = p.lastLoginAt {
                                        ProfileStatRow(label: "Dernière connexion", value: lastLogin.formatted())
                                    }
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding(.horizontal)

                                // ------ HISTORIQUE ------
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Mes dernières parties")
                                        .font(.headline)

                                    if games.isEmpty {
                                        Text("Aucune partie.")
                                            .foregroundStyle(.secondary)
                                    }

                                    ForEach(games, id: \.documentID) { g in
                                        let d = g.data()
                                        let roomId = d["roomId"] as? String ?? "?"
                                        let score = d["scoreDelta"] as? Int ?? 0

                                        HStack {
                                            Text("Room \(roomId)")
                                            Spacer()
                                            Text("Score: \(score)")
                                        }
                                        .padding(.vertical, 4)
                                        .foregroundStyle(.white.opacity(0.9))
                                    }
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding(.horizontal)

                                // ------ SÉCURITÉ ------
                                VStack(spacing: 12) {
                                    Button(role: .destructive) {
                                        do { try auth.signOut() }
                                        catch { errorMessage = error.localizedDescription }
                                    } label: {
                                        ProfileDangerButton(label: "Se déconnecter", icon: "rectangle.portrait.and.arrow.right")
                                    }

                                    Button(role: .destructive) {
                                        Task {
                                            do { try await auth.sendPasswordReset(email: p.email) }
                                            catch { errorMessage = error.localizedDescription }
                                        }
                                    } label: {
                                        ProfileDangerButton(label: "Réinitialiser le mot de passe", icon: "key.fill")
                                    }

                                    Button(role: .destructive) {
                                        Task {
                                            do { try await auth.deleteAccount() }
                                            catch { errorMessage = error.localizedDescription }
                                        }
                                    } label: {
                                        ProfileDangerButton(label: "Supprimer le compte", icon: "trash.fill")
                                    }
                                }
                                .padding(.bottom, 40)
                            }
                        }
                        .onAppear {
                            first = p.firstName
                            last = p.lastName
                            avatar = p.avatar
                            loadGames()
                        }
                    } else {
                        ProgressView().task {
                            if let uid = auth.user?.uid {
                                await auth.loadProfile(uid: uid)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profil")
            .foregroundStyle(.white)
            .alert("Erreur", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    // MARK: - Firestore queries
    private func loadGames() {
        guard let uid = auth.user?.uid else { return }
        Firestore.firestore()
            .collection("users").document(uid).collection("games")
            .order(by: "startedAt", descending: true)
            .limit(to: 50)
            .getDocuments { snap, _ in
                games = snap?.documents ?? []
            }
    }
}

struct ProfileFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
    }
}

struct ProfilePrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.9))
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

struct ProfileDangerButton: View {
    let label: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(label)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.red.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

struct ProfileStatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .bold()
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.vertical, 3)
    }
}

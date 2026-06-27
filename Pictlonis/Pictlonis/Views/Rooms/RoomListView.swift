import SwiftUI
import FirebaseAuth

struct RoomListView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var router: AppRouter
    @StateObject private var vm = RoomsVM()

    @State private var newRoomName: String = ""
    @State private var isCreating: Bool = false
    @State private var errorMessage: String?
    @State private var renameTarget: Room?
    @State private var signOutError: String?
    
    @State private var shareURL: URL?
    @State private var showingShare = false

    private func invite(roomId: String) {
        if let url = URL(string: "pictionis://join?room=\(roomId)") {
            shareURL = url
            showingShare = true

        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // --- Création d'une nouvelle room ---
                VStack(spacing: 12) {
                    Text("Créer une nouvelle room")
                        .font(.headline)

                    HStack(spacing: 10) {
                        TextField("Nom de la room…", text: $newRoomName)
                            .padding(12)
                            .background(.thinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)

                        Button {
                            createRoom()
                        } label: {
                            if isCreating {
                                ProgressView()
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 28))
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(
                            isCreating ||
                            newRoomName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        )
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)

                // --- Liste des rooms ---
                List {
                    Section(header: Text("Rooms disponibles")) {
                        if vm.rooms.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "rectangle.3.group")
                                    .font(.largeTitle)
                                Text("Aucune room pour l’instant.")
                                    .foregroundStyle(.secondary)
                                Text("Crée la première avec le champ ci-dessus 🙌")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(vm.rooms) { room in

                                // ---- Carte room ----
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(room.name.isEmpty ? "(sans nom)" : room.name)
                                            .font(.headline)

                                        HStack(spacing: 8) {
                                            Text(room.status.capitalized)
                                            if let created = room.createdAt {
                                                Text(created, style: .relative)
                                            }
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.tertiary)
                                }
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.secondary.opacity(0.05))
                                )
                                .onTapGesture {
                                    if let id = room.id {
                                        router.pendingRoomId = id
                                    }
                                }
                                .disabled((room.id ?? "").isEmpty)

                                // ---- Swipe Actions ----
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    if room.ownerUid == auth.user?.uid {
                                        Button("Renommer") {
                                            renameTarget = room
                                        }
                                        .tint(.blue)

                                        Button("Inviter") {
                                            invite(roomId: room.id ?? "")
                                        }
                                        .tint(.green)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    vm.stop()
                    vm.start()
                }

            }
            // -------- Navigation Title + Toolbar --------
            .navigationTitle("Rooms")
            .toolbar {
                // Profil (avatar)
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        if let p = auth.profile {
                            AvatarView(
                                tokenString: p.avatar,
                                size: 32,
                                seed: p.username.isEmpty ? p.uid : p.username
                            )
                        } else {
                            Image(systemName: "person.crop.circle")
                                .imageScale(.large)
                        }
                    }
                }

                // Déconnexion
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        do { try auth.signOut() }
                        catch { signOutError = error.localizedDescription }
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                }
            }

            // --- Alerts ---
            .alert(
                "Déconnexion impossible",
                isPresented: Binding(
                    get: { signOutError != nil },
                    set: { _ in signOutError = nil }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(signOutError ?? "")
            }

            // --- Modal rename ---
            .sheet(item: $renameTarget) { room in
                RenameRoomSheet(room: room) { newName in
                    Task { try? await vm.rename(roomId: room.id ?? "", to: newName) }
                }
            }

            // --- Share Sheet ---
            .sheet(isPresented: $showingShare) {
                if let url = shareURL {
                    ShareSheet(
                        activityItems: ["Rejoins ma partie Pictionis 🎨", url]
                    )
                }
            }

            // --- Navigation automatique via deep link ---
            .navigationDestination(
                isPresented: .constant(router.pendingRoomId != nil)
            ) {
                if let id = router.pendingRoomId {
                    GameView(roomId: id, isDrawer: false)
                        .onDisappear { router.pendingRoomId = nil }
                }
            }

            .onChange(of: router.pendingRoomId) { _, _ in }

        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }

    // MARK: - Création de room
    private func createRoom() {
        guard let uid = auth.user?.uid else {
            errorMessage = "Vous devez être connecté pour créer une room."
            return
        }

        let name = newRoomName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        isCreating = true
        errorMessage = nil

        Task {
            do {
                try await vm.create(name: name, ownerUid: uid)
                newRoomName = ""
            } catch {
                errorMessage = "Échec de création : \(error.localizedDescription)"
            }
            isCreating = false
        }
    }

    // MARK: - ShareSheet
    struct ShareSheet: UIViewControllerRepresentable {
        let activityItems: [Any]

        func makeUIViewController(context: Context)
            -> UIActivityViewController
        {
            UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: nil
            )
        }

        func updateUIViewController(
            _ uiViewController: UIActivityViewController,
            context: Context
        ) {}
    }
}

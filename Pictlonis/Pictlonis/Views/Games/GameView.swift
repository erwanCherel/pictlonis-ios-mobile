import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct GameView: View {
    let roomId: String
    let isDrawer: Bool

    @StateObject private var chat: ChatVM
    @StateObject private var drawing: DrawingVM

    @State private var messageText: String = ""
    @State private var roomName: String = "Room"
    @State private var showingRename: Bool = false
    @State private var newRoomName: String = ""

    @State private var nameCache: [String: String] = [:]
    @State private var shareURL: URL?
    @State private var showingShare = false

    init(roomId: String, isDrawer: Bool) {
        self.roomId = roomId
        self.isDrawer = isDrawer
        _chat = StateObject(wrappedValue: ChatVM(roomId: roomId))
        _drawing = StateObject(wrappedValue: DrawingVM(roomId: roomId))
    }

    var body: some View {
        VStack(spacing: 0) {

            // ----- ZONE DE DESSIN -----
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.9), .white.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 4)

                DrawingCanvas(vm: drawing)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .frame(height: 320)
            .padding()
            .padding(.bottom, 4)

            // ----- CHAT -----
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(chat.messages.enumerated()), id: \.element.id) { index, msg in
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(displayName(for: msg.uid))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)

                                    Text(msg.text)
                                        .padding(12)
                                        .background(
                                            msg.isCorrect
                                            ? Color.green.opacity(0.8)
                                            : Color.blue.opacity(
                                                msg.uid == Auth.auth().currentUser?.uid ? 0.85 : 0.5
                                            )
                                        )
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .shadow(radius: msg.isCorrect ? 4 : 0)
                                }
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: msg.uid == Auth.auth().currentUser?.uid ? .trailing : .leading
                                )
                            }
                            .padding(.horizontal)
                            .id(index)
                        }

                        Spacer().frame(height: 12)
                    }
                }
                .background(Color.white.opacity(0.05))
                .onChange(of: chat.messages.count) { _, new in
                    guard new > 0 else { return }
                    withAnimation { proxy.scrollTo(new - 1, anchor: .bottom) }
                }
            }

            // ----- BARRE D’ENVOI -----
            HStack(spacing: 12) {
                TextField("Votre message…", text: $messageText)
                    .padding(12)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.regularMaterial)
        }

        // ----- NAVIGATION -----
        .navigationTitle(roomName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Clear Canvas
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    drawing.clearCanvas()
                } label: {
                    Image(systemName: "eraser.line.dashed")
                }
            }

            // Menu
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Renommer la room") { showingRename = true }
                    if let url = inviteLink() {
                        Button("Partager l’invitation") {
                            shareURL = url
                            showingShare = true
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }

        // ----- Alert rename -----
        .alert("Renommer la room", isPresented: $showingRename) {
            TextField("Nom", text: $newRoomName)
            Button("OK") {
                Task { try? await renameRoom(to: newRoomName) }
            }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("Entrez le nouveau nom")
        }

        // ----- Lifecycle -----
        .onAppear {
            chat.start()
            drawing.start()
            fetchRoomName()
        }
        .onDisappear {
            chat.stop()
            drawing.stop()
        }

        // ----- ShareSheet -----
        .sheet(isPresented: $showingShare) {
            if let url = shareURL {
                ShareSheet(activityItems: ["Rejoins ma partie Pictionis 🎨", url])
            }
        }
    }

    // MARK: - Helpers

    private func inviteLink() -> URL? {
        URL(string: "pictionis://join?room=\(roomId)")
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let uid = Auth.auth().currentUser?.uid else { return }
        Task {
            try? await chat.send(uid: uid, text: text)
            await MainActor.run { messageText = "" }
        }
    }

    private func fetchRoomName() {
        Firestore.firestore().collection("rooms").document(roomId)
            .getDocument { snap, _ in
                if let name = snap?.data()?["name"] as? String, !name.isEmpty {
                    roomName = name
                }
            }
    }

    private func renameRoom(to newName: String) async throws {
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        try await Firestore.firestore()
            .collection("rooms").document(roomId)
            .updateData([
                "name": name,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        await MainActor.run {
            roomName = name
            newRoomName = ""
        }
    }

    // UID -> Username (avec cache)
    private func displayName(for uid: String) -> String {
        if let cached = nameCache[uid] { return cached }
        let short = String(uid.prefix(6))
        nameCache[uid] = short // valeur provisoire

        Firestore.firestore().collection("users").document(uid).getDocument { doc, _ in
            if let d = doc?.data() {
                if let uname = d["username"] as? String, !uname.isEmpty {
                    nameCache[uid] = uname
                } else if let first = d["firstName"] as? String, !first.isEmpty {
                    nameCache[uid] = first
                }
            }
        }
        return short
    }

    // MARK: - ShareSheet (pour l’invitation)
    struct ShareSheet: UIViewControllerRepresentable {
        let activityItems: [Any]

        func makeUIViewController(context: Context) -> UIActivityViewController {
            UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
    }
}

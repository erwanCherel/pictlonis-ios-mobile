import SwiftUI

struct AvatarPickerView: View {
    @Binding var selectedToken: String          // "init:alice#4" ou "emoji:🦊"
    let seed: String                             // ex. username
    var onConfirm: ((String) -> Void)? = nil     // callback optionnel

    @Environment(\.dismiss) private var dismiss
    private let columns = [GridItem(.adaptive(minimum: 68), spacing: 14)]
    private let emojis = ["🐼","🐱","🦊","🐯","🦄","🤖","👾","🧠","⚡️","🎯"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // 📌 Aperçu en grand
                VStack(spacing: 10) {
                    AvatarView(tokenString: selectedToken, size: 110, seed: seed)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.1), radius: 6)
                        )
                    Text(tokenLabel(selectedToken))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 10)

                // 🅰️ Initiales
                Text("Initiales")
                    .font(.title3.bold())

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(0..<12, id: \.self) { v in
                        let token = AvatarToken.initials(seed: seed, variant: v).stringValue
                        AvatarOptionButton(token: token)
                    }
                }

                // 😀 Emojis
                Text("Emojis")
                    .font(.title3.bold())

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(emojis, id: \.self) { emo in
                        let token = AvatarToken.emoji(symbol: emo).stringValue
                        AvatarOptionButton(token: token)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Choisir un avatar")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Utiliser") {
                    onConfirm?(selectedToken)
                    dismiss()
                }
            }
        }
    }

    // --- SUBVIEW ---
    @ViewBuilder
    private func AvatarOptionButton(token: String) -> some View {
        Button {
            selectedToken = token
        } label: {
            ZStack {
                AvatarView(tokenString: token, size: 68, seed: seed)
                    .overlay(
                        Circle()
                            .stroke(
                                selectedToken == token
                                    ? Color.accentColor : .clear,
                                lineWidth: selectedToken == token ? 4 : 0
                            )
                            .animation(.easeOut(duration: 0.2), value: selectedToken)
                    )
            }
        }
        .buttonStyle(.plain)
    }

    private func tokenLabel(_ token: String) -> String {
        switch AvatarToken.parse(token) {
        case .emoji(let s): return "Emoji \(s)"
        case .initials(_, let v): return "Initiales • Variante \(v + 1)"
        }
    }
}

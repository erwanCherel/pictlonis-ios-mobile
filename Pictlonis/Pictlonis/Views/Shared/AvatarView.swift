import SwiftUI

struct AvatarView: View {
    let token: AvatarToken
    let size: CGFloat
    let seedForInitials: String   // ex: username, first+last…

    init(tokenString: String, size: CGFloat, seed: String) {
        self.token = AvatarToken.parse(tokenString)
        self.size = size
        self.seedForInitials = seed
    }

    var body: some View {
        ZStack {
            switch token {

            // --- INITIALS TOKEN ---
            case .initials(let seed, let variant):
                let grad = AvatarPalette.gradient(seed: seed, variant: variant)
                Circle()
                    .fill(grad)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: size * 0.03)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 3)

                let h = AvatarPalette.hues(seed: seed, variant: variant).0

                Text(initials(from: seedForInitials))
                    .font(.system(size: size * 0.42, weight: .bold, design: .rounded))
                    .foregroundStyle(AvatarPalette.textColor(forBackgroundHue: h))

            // --- EMOJI TOKEN ---
            case .emoji(let symbol):
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.18), lineWidth: size * 0.03)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 3, y: 2)

                Text(symbol)
                    .font(.system(size: size * 0.60))
            }
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .animation(.spring(duration: 0.25), value: token.stringValue)
    }
}

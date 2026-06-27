import SwiftUI

struct RenameRoomSheet: View {
    var room: Room
    var onRename: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var newName: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {

                Text("Renommer la room")
                    .font(.title2.bold())
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Nouveau nom")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("Nom de la room", text: $newName)
                        .padding()
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)

                Spacer()

                // Boutons confirm / cancel
                HStack {
                    Button("Annuler") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Button("Renommer") {
                        onRename(newName)
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(newName.isEmpty ? 0.3 : 0.9))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(newName.isEmpty)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .onAppear {
                newName = room.name
            }
        }
    }
}

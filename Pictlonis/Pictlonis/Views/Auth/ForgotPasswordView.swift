import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = ""
    @State private var sent = false
    @State private var loading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 28) {

            Text("🔒 Réinitialiser le mot de passe")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.top, 40)

            VStack(spacing: 18) {
                // Champ email
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)

                // Bouton envoyer
                Button {
                    Task {
                        loading = true
                        do {
                            try await auth.sendPasswordReset(email: email)
                            sent = true
                            errorMessage = nil
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                        loading = false
                    }
                } label: {
                    if loading {
                        ProgressView()
                    } else {
                        Text("Envoyer le lien")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(email.isEmpty || loading)
            }

            // Message d’erreur
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .padding(.horizontal)
                    .transition(.opacity)
            }

            // Message de succès
            if sent {
                Text("Un email de réinitialisation a été envoyé ✔️")
                    .foregroundStyle(.green)
                    .font(.footnote.bold())
                    .padding(.top, 10)
                    .transition(.opacity.combined(with: .scale))
            }

            Spacer()
        }
        .animation(.spring(duration: 0.25), value: sent)
        .animation(.easeInOut, value: errorMessage)
        .navigationTitle("Mot de passe oublié")
        .navigationBarTitleDisplayMode(.inline)
    }
}

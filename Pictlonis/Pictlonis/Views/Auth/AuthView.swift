import SwiftUI

struct AuthView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @State private var errorMessage: String?
    @State private var loading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                
                // --- Logo + titre ---
                VStack(spacing: 8) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.8))
                    Text("PictIonis")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                }
                .padding(.top, 80)

                // --- Card de connexion ---
                VStack(spacing: 16) {
                    // Email
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    // Password
                    SecureField("Mot de passe", text: $password)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4)
                    }

                    // --- Button login ---
                    Button {
                        Task {
                            loading = true
                            do {
                                try await auth.signIn(email: email, password: password)
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            loading = false
                        }
                    } label: {
                        HStack {
                            if loading { ProgressView() }
                            else { Text("Se connecter") }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(email.isEmpty || password.isEmpty)

                    Button("Mot de passe oublié ?") {
                        showForgotPassword = true
                    }
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.top, 6)
                }
                .padding(24)
                .background(.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)

                Spacer()

                // --- Sign up ---
                VStack(spacing: 6) {
                    Text("Pas encore de compte ?")
                        .foregroundStyle(.white.opacity(0.9))
                    NavigationLink("Créer un compte", destination: SignUpView())
                        .font(.footnote.bold())
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 50)
            }
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationDestination(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
}

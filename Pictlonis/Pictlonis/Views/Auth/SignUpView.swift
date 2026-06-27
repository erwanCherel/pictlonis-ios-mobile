//
//  SignUpView.swift
//  PictIonis
//
//  Created by Etienne Roche on 06/11/2025.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var first = ""
    @State private var last = ""
    @State private var username = ""
    @State private var avatar = "init:seed#0"
    @State private var error: String?
    @State private var loading = false

    let avatars = ["astronaut", "panda", "cat", "robot", "unicorn"]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.65), Color.indigo.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Form {
                Section("Identifiants") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    SecureField("Mot de passe", text: $password)
                }

                Section("Profil") {
                    TextField("Prénom", text: $first)
                    TextField("Nom", text: $last)
                    TextField("Pseudo (unique)", text: $username)
                        .textInputAutocapitalization(.never)

                    NavigationLink {
                        AvatarPickerView(
                            selectedToken: $avatar,
                            seed: username.isEmpty ? "guest" : username
                        )
                    } label: {
                        HStack {
                            AvatarView(
                                tokenString: avatar,
                                size: 44,
                                seed: username.isEmpty ? "guest" : username
                            )
                            Text("Choisir un avatar")
                            Spacer()
                        }
                    }
                }

                if let error {
                    Text(error)
                        .foregroundStyle(.red)
                }

                Button {
                    Task {
                        loading = true
                        do {
                            try await auth.signUp(
                                email: email,
                                password: password,
                                first: first,
                                last: last,
                                username: username,
                                avatar: avatar
                            )
                        } catch {
                            self.error = error.localizedDescription
                        }
                        loading = false
                    }
                } label: {
                    HStack {
                        Spacer()
                        if loading { ProgressView() }
                        else { Text("Créer le compte").bold() }
                        Spacer()
                    }
                }
                .tint(.blue)
                .disabled(
                    loading ||
                    email.isEmpty ||
                    password.count < 6 ||
                    username.isEmpty
                )
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Inscription")
    }
}

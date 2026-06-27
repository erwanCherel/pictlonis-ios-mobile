# PictIonis — Jeu de dessin multijoueur iOS

Application iOS de type Pictionary multijoueur en temps réel (ETNA Master 1). Développé en Swift/SwiftUI avec Firebase comme backend.

## Fonctionnalités

- **Authentification** — inscription/connexion email, réinitialisation de mot de passe
- **Salles de jeu** — création, invitation via deep link (`pictionis://join?room=...`), renommage
- **Dessin temps réel** — canvas synchronisé entre tous les joueurs via Firebase Realtime Database
- **Chat & devinettes** — validation côté serveur (Cloud Function) par hash HMAC-SHA256 du mot à deviner
- **Avatars** — génération procédurale par hash du nom d'utilisateur
- **Profil** — édition, suppression de compte

## Stack

- **Swift 5 / SwiftUI** — iOS natif
- **Firebase Auth** — authentification
- **Cloud Firestore** — salles, joueurs, messages
- **Firebase Realtime Database** — synchronisation des traits de dessin (faible latence)
- **Firebase Cloud Functions** (Node.js) — validation des devinettes côté serveur

## Architecture

```
Pictlonis/
├── App/            # Point d'entrée, routing
├── Models/         # Structures de données (Room, User, Message)
├── Services/       # Singletons Firestore et Realtime DB
├── ViewModels/     # AuthVM, RoomsVM, DrawingVM, ChatVM
├── Views/
│   ├── Auth/       # Login, inscription, mot de passe oublié
│   ├── Rooms/      # Liste des salles, invitation
│   ├── Games/      # Canvas de dessin, chat en jeu
│   └── Profile/    # Édition du profil, avatar
├── FirebaseRules/  # Règles Firestore et Realtime DB
└── Functions/      # Cloud Function de validation des devinettes
```

Pattern MVVM tout du long. Les ViewModels exposent des `@Published` properties consommées par les vues SwiftUI.

## Prérequis

- Xcode 15+, iOS 16+
- Un projet Firebase avec Auth, Firestore, Realtime Database et Cloud Functions activés
- Ajouter votre propre `GoogleService-Info.plist` à `Pictlonis/` (non versionné)

## Configuration Firebase

```bash
# Déployer les Cloud Functions
cd Pictlonis/Pictlonis/Functions
npm install
firebase functions:config:set game.secret="votre-cle-secrete"
firebase deploy --only functions

# Déployer les règles de sécurité
firebase deploy --only firestore:rules,database
```

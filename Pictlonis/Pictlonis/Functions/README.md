# Cloud Functions (optionnel)

- Valide les guesses côté serveur en comparant un HMAC du texte deviné avec `currentWordHash` dans le document `rooms/{roomId}`.
- Définissez une clé secrète : `firebase functions:config:set game.secret="votre-cle-secrete"` puis `firebase deploy --only functions`.

> Dans votre app, **ne stockez pas** le mot clair.
> Stockez seulement `currentWordMasked` (ex: `_ _ _`) et `currentWordHash` (HMAC-SHA256 du mot).


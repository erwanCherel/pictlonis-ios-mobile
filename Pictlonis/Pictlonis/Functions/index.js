const functions = require('firebase-functions');
const admin = require('firebase-admin');
const CryptoJS = require('crypto-js');
admin.initializeApp();

// Configurer dans Firebase env: functions.config().game.secret = "votre-cle-secrete"
const getSecret = () => {
  const secret = (functions.config().game || {}).secret;
  if (!secret) throw new Error("game.secret is not configured");
  return secret;
};

// On new chat message, check guess hash against room currentWordHash (if present)
exports.onGuessCreate = functions.firestore
  .document('rooms/{roomId}/chat/{messageId}')
  .onCreate(async (snap, context) => {
    const { roomId } = context.params;
    const msg = snap.data();
    if (!msg.isGuess || !msg.text) return null;

    const roomRef = admin.firestore().doc(`rooms/${roomId}`);
    const room = (await roomRef.get()).data();
    if (!room || !room.currentWordHash) return null;

    const secret = getSecret();
    const guessHash = CryptoJS.HmacSHA256(msg.text.toLowerCase().trim(), secret).toString();

    if (guessHash === room.currentWordHash) {
      // Mark correct
      await snap.ref.update({ isCorrect: true });
      // Increment score (players subcollection expected)
      const playerRef = admin.firestore().doc(`rooms/${roomId}/players/${msg.uid}`);
      await admin.firestore().runTransaction(async (tx) => {
        const p = await tx.get(playerRef);
        const score = (p.exists && p.data().score) ? p.data().score : 0;
        tx.set(playerRef, { score: score + 10 }, { merge: true });
      });
      // TODO: trigger next round, rotate drawer, clear strokes in RTDB
    }
    return null;
  });

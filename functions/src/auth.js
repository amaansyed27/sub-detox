const admin = require("firebase-admin");

function extractBearerToken(authorizationHeader = "") {
  if (!authorizationHeader || !authorizationHeader.startsWith("Bearer ")) {
    return null;
  }
  return authorizationHeader.split(" ")[1] || null;
}

function verifyFirebaseAuth(db) {
  return async (req, res, next) => {
    try {
      const token = extractBearerToken(req.headers.authorization);
      if (!token) {
        return res.status(401).json({
          error: "unauthenticated",
          message: "Missing bearer token.",
        });
      }

      const decodedToken = await admin.auth().verifyIdToken(token);
      req.user = decodedToken;

      const userDocRef = db.collection("users").doc(decodedToken.uid);
      await userDocRef.set(
        {
          userId: decodedToken.uid,
          email: decodedToken.email || null,
          phoneNumber: decodedToken.phone_number || null,
          displayName: decodedToken.name || null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      return next();
    } catch (error) {
      return res.status(401).json({
        error: "unauthenticated",
        message: "Invalid or expired token.",
      });
    }
  };
}

module.exports = {
  verifyFirebaseAuth,
};

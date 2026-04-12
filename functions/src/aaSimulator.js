const admin = require("firebase-admin");

async function createConsent(db, userId, payload = {}) {
  const docRef = db.collection("consents").doc();
  const consent = {
    userId,
    consentId: docRef.id,
    status: "ACTIVE",
    scope: payload.scope || "DEPOSIT_TRANSACTIONS",
    linkedAccounts: payload.linkedAccounts || ["XXXXXX4521"],
    fipId: payload.fipId || "FIP-ICIC-IND-001",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await docRef.set(consent);
  return { id: docRef.id, ...consent };
}

async function getConsent(db, userId, consentId) {
  const docRef = db.collection("consents").doc(consentId);
  const snapshot = await docRef.get();
  if (!snapshot.exists) {
    return null;
  }

  const data = snapshot.data();
  if (data.userId !== userId) {
    return null;
  }

  return { id: snapshot.id, ...data };
}

async function revokeConsent(db, userId, consentId) {
  const docRef = db.collection("consents").doc(consentId);
  const snapshot = await docRef.get();
  if (!snapshot.exists) {
    return null;
  }

  const data = snapshot.data();
  if (data.userId !== userId) {
    return null;
  }

  await docRef.update({
    status: "REVOKED",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { id: consentId, status: "REVOKED" };
}

function getScenarioOutcome(scenario) {
  switch (scenario) {
    case "provider_timeout":
      return {
        status: "FAILED",
        code: "AA_PROVIDER_TIMEOUT",
        message: "Provider timeout while fetching FI records.",
      };
    case "provider_down":
      return {
        status: "FAILED",
        code: "AA_PROVIDER_DOWN",
        message: "Provider temporarily unavailable.",
      };
    default:
      return {
        status: "COMPLETED",
        code: null,
        message: "FI session completed successfully.",
      };
  }
}

async function startFiSession(db, userId, payload, generateMockAaPayload) {
  const docRef = db.collection("fi_sessions").doc();
  const scenario = payload?.scenario || "success";
  const outcome = getScenarioOutcome(scenario);
  const mockPayload = outcome.status === "COMPLETED" ? generateMockAaPayload(userId, payload?.user || {}) : null;

  const session = {
    userId,
    sessionId: docRef.id,
    consentId: payload?.consentId || null,
    scenario,
    status: outcome.status,
    errorCode: outcome.code,
    errorMessage: outcome.message,
    resultPayload: mockPayload,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await docRef.set(session);
  return { id: docRef.id, ...session };
}

async function getFiSession(db, userId, sessionId) {
  const docRef = db.collection("fi_sessions").doc(sessionId);
  const snapshot = await docRef.get();
  if (!snapshot.exists) {
    return null;
  }

  const data = snapshot.data();
  if (data.userId !== userId) {
    return null;
  }

  return { id: snapshot.id, ...data };
}

module.exports = {
  createConsent,
  getConsent,
  revokeConsent,
  startFiSession,
  getFiSession,
};

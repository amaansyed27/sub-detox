const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

const { verifyFirebaseAuth } = require("./auth");
const { generateMockAaPayload } = require("./mockAaData");
const { analyzeTransactionsPayload } = require("./analysisEngine");
const {
  createConsent,
  getConsent,
  revokeConsent,
  startFiSession,
  getFiSession,
} = require("./aaSimulator");

admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

app.get("/health", (req, res) => {
  res.json({ status: "ok", service: "subdetox-firebase-api" });
});

app.use(verifyFirebaseAuth(db));

app.get("/me", async (req, res) => {
  const userDoc = await db.collection("users").doc(req.user.uid).get();
  res.json({
    uid: req.user.uid,
    email: req.user.email || null,
    phone_number: req.user.phone_number || null,
    profile: userDoc.exists ? userDoc.data() : null,
  });
});

app.get("/mock-aa-data", async (req, res, next) => {
  try {
    const payload = generateMockAaPayload(req.user.uid, req.user);
    await db.collection("audit_events").add({
      userId: req.user.uid,
      eventType: "MOCK_AA_DATA_FETCHED",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    res.json(payload);
  } catch (error) {
    next(error);
  }
});

app.post("/analyze-transactions", async (req, res, next) => {
  try {
    const payload = req.body?.aa_payload || generateMockAaPayload(req.user.uid, req.user);
    const analysis = analyzeTransactionsPayload(payload);

    await persistAnalysisRun(req.user.uid, payload, analysis);

    res.json(analysis);
  } catch (error) {
    next(error);
  }
});

app.post("/revoke-mandate", async (req, res, next) => {
  try {
    const merchantCode = req.body?.merchant_code;
    if (!merchantCode) {
      return res.status(400).json({
        error: "invalid_request",
        message: "merchant_code is required.",
      });
    }

    const subscriptionRef = db
      .collection("detected_subscriptions")
      .doc(`${req.user.uid}_${merchantCode}`);
    const subscriptionDoc = await subscriptionRef.get();

    if (!subscriptionDoc.exists) {
      return res.status(404).json({
        error: "not_found",
        message: "Subscription not found for this user.",
      });
    }

    const subscriptionData = subscriptionDoc.data();
    const monthlyAmount = Number(subscriptionData.estimatedMonthlyAmount || 0);

    await subscriptionRef.set(
      {
        resolved: true,
        resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await db.collection("revoke_actions").add({
      userId: req.user.uid,
      merchantCode,
      monthlyAmount,
      annualSavings: Number((monthlyAmount * 12).toFixed(2)),
      status: "COMPLETED",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.json({
      status: "resolved",
      merchant_code: merchantCode,
      annual_savings: Number((monthlyAmount * 12).toFixed(2)),
      message: "Mandate revoked in simulator.",
    });
  } catch (error) {
    next(error);
  }
});

app.post("/simulator/consents", async (req, res, next) => {
  try {
    const consent = await createConsent(db, req.user.uid, req.body || {});
    res.status(201).json(consent);
  } catch (error) {
    next(error);
  }
});

app.get("/simulator/consents/:consentId", async (req, res, next) => {
  try {
    const consent = await getConsent(db, req.user.uid, req.params.consentId);
    if (!consent) {
      return res.status(404).json({ error: "not_found", message: "Consent not found." });
    }
    return res.json(consent);
  } catch (error) {
    next(error);
  }
});

app.post("/simulator/consents/:consentId/revoke", async (req, res, next) => {
  try {
    const consent = await revokeConsent(db, req.user.uid, req.params.consentId);
    if (!consent) {
      return res.status(404).json({ error: "not_found", message: "Consent not found." });
    }
    return res.json(consent);
  } catch (error) {
    next(error);
  }
});

app.post("/simulator/fi-sessions", async (req, res, next) => {
  try {
    const session = await startFiSession(db, req.user.uid, req.body || {}, generateMockAaPayload);
    return res.status(201).json(session);
  } catch (error) {
    next(error);
  }
});

app.get("/simulator/fi-sessions/:sessionId", async (req, res, next) => {
  try {
    const session = await getFiSession(db, req.user.uid, req.params.sessionId);
    if (!session) {
      return res.status(404).json({ error: "not_found", message: "FI session not found." });
    }
    return res.json(session);
  } catch (error) {
    next(error);
  }
});

app.use((error, req, res, next) => {
  logger.error("API error", { message: error.message, stack: error.stack });
  res.status(500).json({
    error: "internal_error",
    message: "Unexpected server error.",
  });
});

async function persistAnalysisRun(userId, payload, analysis) {
  const runRef = await db.collection("analysis_runs").add({
    userId,
    generatedAt: admin.firestore.FieldValue.serverTimestamp(),
    scannedTransactionCount: analysis.scanned_transaction_count,
    totalMonthlyLeakage: analysis.total_monthly_leakage,
    currency: analysis.currency,
    source: payload?.txnid || "generated",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  for (const subscription of analysis.detected_subscriptions) {
    const docId = `${userId}_${subscription.merchant_code}`;
    const docRef = db.collection("detected_subscriptions").doc(docId);
    const existing = await docRef.get();
    const previousResolved = existing.exists ? existing.data().resolved === true : false;

    await docRef.set(
      {
        userId,
        merchantCode: subscription.merchant_code,
        displayName: subscription.display_name,
        sampleNarration: subscription.sample_narration,
        threatLevel: subscription.threat_level,
        confidenceScore: subscription.confidence_score,
        occurrenceCount: subscription.occurrence_count,
        averageAmount: subscription.average_amount,
        estimatedMonthlyAmount: subscription.estimated_monthly_amount,
        firstSeen: subscription.first_seen,
        lastChargedOn: subscription.last_charged_on,
        reasoning: subscription.reasoning,
        resolved: previousResolved,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }

  await db.collection("audit_events").add({
    userId,
    eventType: "ANALYSIS_COMPLETED",
    runId: runRef.id,
    detectedCount: analysis.detected_subscriptions.length,
    totalMonthlyLeakage: analysis.total_monthly_leakage,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

exports.api = onRequest(
  {
    region: "asia-south1",
    cors: true,
    memory: "256MiB",
    timeoutSeconds: 120,
    maxInstances: 20,
  },
  app
);

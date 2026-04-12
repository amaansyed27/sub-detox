function roundMoney(amount) {
  return Number(Number(amount).toFixed(2));
}

const SUBSCRIPTION_RULES = [
  {
    code: "GYMCULT_AUTOPAY",
    displayName: "Gymcult AutoPay",
    keywords: ["GYMCULT", "AUTOPAY"],
    threatLevel: "MEDIUM",
    reasoning: "AutoPay fitness membership detected as recurring debit.",
  },
  {
    code: "VIL_VAS_HELLOTUNE",
    displayName: "VIL HelloTune VAS",
    keywords: ["VIL", "VAS", "HELLOTUNE"],
    threatLevel: "HIGH",
    reasoning: "Obscure telecom VAS pattern indicates silent recurring leakage.",
  },
  {
    code: "CREDIT_SHIELD",
    displayName: "Credit Shield Add-On",
    keywords: ["CREDIT", "SHIELD"],
    threatLevel: "HIGH",
    reasoning: "Card protection add-on often remains active unnoticed.",
  },
  {
    code: "NETFLIX_STANDARD",
    displayName: "Netflix Standard",
    keywords: ["NETFLIX"],
    threatLevel: "LOW",
    reasoning: "Known mainstream streaming subscription.",
  },
];

function normalize(text) {
  return String(text || "")
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, " ")
    .trim();
}

function matchesRule(narration) {
  const n = normalize(narration);
  return SUBSCRIPTION_RULES.find((rule) => rule.keywords.every((k) => n.includes(k))) || null;
}

function extractTransactions(payload) {
  const fiRecords = payload?.FI || payload?.fi || [];
  const transactions = [];

  fiRecords.forEach((fi) => {
    const fiTransactions = fi?.Transactions || fi?.transactions || [];
    fiTransactions.forEach((txn) => {
      transactions.push({
        valueDate: txn.valueDate || txn.value_date,
        narration: txn.narration,
        amount: Number(txn.amount || 0),
        type: txn.type || txn.txn_type,
      });
    });
  });

  return transactions;
}

function dayDiff(a, b) {
  const dateA = new Date(a);
  const dateB = new Date(b);
  return Math.round((dateB - dateA) / (24 * 60 * 60 * 1000));
}

function isMonthlyRecurring(transactions) {
  if (transactions.length < 2) {
    return false;
  }

  const sorted = [...transactions].sort((x, y) => (x.valueDate < y.valueDate ? -1 : 1));
  for (let i = 1; i < sorted.length; i += 1) {
    const gap = dayDiff(sorted[i - 1].valueDate, sorted[i].valueDate);
    if (gap < 25 || gap > 35) {
      return false;
    }
  }
  return true;
}

function confidence(occurrenceCount) {
  if (occurrenceCount >= 3) {
    return 0.95;
  }
  if (occurrenceCount === 2) {
    return 0.8;
  }
  return 0.65;
}

function analyzeTransactionsPayload(payload) {
  const allTransactions = extractTransactions(payload);
  const debitTransactions = allTransactions.filter((txn) => txn.type === "DEBIT");

  const grouped = new Map();

  debitTransactions.forEach((txn) => {
    const rule = matchesRule(txn.narration);
    if (!rule) {
      return;
    }

    if (!grouped.has(rule.code)) {
      grouped.set(rule.code, { rule, transactions: [] });
    }
    grouped.get(rule.code).transactions.push(txn);
  });

  const detected = [];

  grouped.forEach(({ rule, transactions }) => {
    if (!isMonthlyRecurring(transactions)) {
      return;
    }

    const sorted = [...transactions].sort((a, b) => (a.valueDate < b.valueDate ? -1 : 1));
    const avg =
      transactions.reduce((sum, txn) => sum + Number(txn.amount || 0), 0) /
      transactions.length;

    detected.push({
      merchant_code: rule.code,
      display_name: rule.displayName,
      sample_narration: sorted[sorted.length - 1].narration,
      threat_level: rule.threatLevel,
      confidence_score: confidence(transactions.length),
      occurrence_count: transactions.length,
      average_amount: roundMoney(avg),
      estimated_monthly_amount: roundMoney(avg),
      first_seen: sorted[0].valueDate,
      last_charged_on: sorted[sorted.length - 1].valueDate,
      reasoning: `${rule.reasoning} Recurring monthly pattern observed over ${transactions.length} cycles.`,
    });
  });

  detected.sort((a, b) => b.estimated_monthly_amount - a.estimated_monthly_amount);

  const total = detected.reduce((sum, item) => sum + item.estimated_monthly_amount, 0);

  return {
    generated_at: new Date().toISOString(),
    scanned_transaction_count: allTransactions.length,
    detected_subscriptions: detected,
    total_monthly_leakage: roundMoney(total),
    currency: "INR",
  };
}

module.exports = {
  analyzeTransactionsPayload,
};

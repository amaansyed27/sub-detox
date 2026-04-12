function toISODate(date) {
  return date.toISOString().slice(0, 10);
}

function roundMoney(amount) {
  return Number(amount.toFixed(2));
}

function makeTxn({ serial, valueDate, narration, amount, type, mode, category }) {
  return {
    txnId: `AA-TXN-${valueDate.slice(0, 7).replace("-", "")}-${String(serial).padStart(4, "0")}`,
    valueDate,
    narration,
    amount: roundMoney(amount),
    currency: "INR",
    type,
    mode,
    category,
    status: "SUCCESS",
  };
}

function generateMockAaPayload(userId, user = {}) {
  const now = new Date();
  const txns = [];
  let serial = 1;

  const add = (daysAgo, narration, amount, type, mode, category) => {
    const date = new Date(now);
    date.setDate(date.getDate() - daysAgo);
    txns.push(
      makeTxn({
        serial,
        valueDate: toISODate(date),
        narration,
        amount,
        type,
        mode,
        category,
      })
    );
    serial += 1;
  };

  [8, 38, 68].forEach((d) => add(d, "GYMCULT-AUTOPAY 1499.00", 1499, "DEBIT", "UPI_AUTOPAY", "SUBSCRIPTION"));
  [6, 36, 66].forEach((d) => add(d, "VIL-VAS-HELLOTUNE 49.00", 49, "DEBIT", "AUTO_DEBIT", "TELECOM_VAS"));
  [4, 34, 64].forEach((d) => add(d, "CREDIT-SHIELD 199.00", 199, "DEBIT", "AUTO_DEBIT", "INSURANCE_ADDON"));
  [10, 40, 70].forEach((d) => add(d, "NETFLIX-SUBSCRIPTION 649.00", 649, "DEBIT", "CARD_ECOM", "SUBSCRIPTION"));

  [12, 42, 72].forEach((d) => add(d, "ACME CORP SALARY CREDIT", 95000, "CREDIT", "NEFT", "SALARY"));

  [
    [1, 342],
    [14, 287],
    [27, 418],
    [46, 361],
    [61, 299],
    [79, 322],
  ].forEach(([d, a]) => add(d, "ZOMATO ORDER", a, "DEBIT", "UPI", "FOOD"));

  [
    [3, 221],
    [18, 312],
    [33, 188],
    [52, 274],
    [74, 197],
  ].forEach(([d, a]) => add(d, "UBER TRIP", a, "DEBIT", "UPI", "TRANSPORT"));

  [
    [5, 2289],
    [24, 3411],
    [49, 2750],
    [83, 3012],
  ].forEach(([d, a]) => add(d, "BIGBAZAAR GROCERIES", a, "DEBIT", "UPI", "GROCERIES"));

  [
    [21, 1320],
    [54, 1459],
    [86, 1389],
  ].forEach(([d, a]) => add(d, "BESCOM ELECTRICITY BILL", a, "DEBIT", "UPI", "UTILITIES"));

  txns.sort((a, b) => (a.valueDate < b.valueDate ? 1 : -1));

  const debitTotal = txns.filter((t) => t.type === "DEBIT").reduce((sum, t) => sum + t.amount, 0);
  const creditTotal = txns.filter((t) => t.type === "CREDIT").reduce((sum, t) => sum + t.amount, 0);
  const balance = roundMoney(125000 + creditTotal - debitTotal);

  const fromDate = new Date(now);
  fromDate.setDate(fromDate.getDate() - 90);

  return {
    ver: "1.1.3",
    timestamp: now.toISOString(),
    txnid: `TXN-${userId.slice(0, 8).toUpperCase()}-${Date.now()}`,
    Consent: {
      id: `CONSENT-${userId.slice(0, 8).toUpperCase()}`,
      status: "ACTIVE",
      FIDataRange: {
        from: toISODate(fromDate),
        to: toISODate(now),
      },
    },
    FI: [
      {
        FIType: "DEPOSIT",
        FIPID: "FIP-ICIC-IND-001",
        linkRefNumber: `LNK-${userId.slice(0, 6).toUpperCase()}`,
        maskedAccNumber: "XXXXXX4521",
        Profile: {
          Holders: [
            {
              name: user.name || user.displayName || "SubDetox User",
              mobile: user.phone_number || user.phoneNumber || null,
              email: user.email || null,
            },
          ],
          Summary: {
            currentBalance: balance,
            averageMonthlyDebit: roundMoney(debitTotal / 3),
            averageMonthlyCredit: roundMoney(creditTotal / 3),
          },
        },
        Transactions: txns,
      },
    ],
  };
}

module.exports = {
  generateMockAaPayload,
};

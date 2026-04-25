/**
 * ─── Payment Routes ─────────────────────────────────────────────────────────
 * All endpoints related to Stripe payment processing.
 * POST /api/payments/create-payment-intent
 * POST /api/payments/confirm
 * POST /api/payments/release-escrow/:paymentId
 * GET  /api/payments/my-payments
 * GET  /api/payments/wallet
 * POST /stripe/webhook  (registered separately in server.js with raw body)
 */

const express = require("express");
const router = express.Router();
const { verifyToken, requireRole } = require("../middleware/auth");
const {
  stripe,
  createPaymentIntent,
  confirmPayment,
  releaseEscrow,
  handleWebhookEvent,
} = require("../utils/payment.service");

// ─── VALIDATION ────────────────────────────────────────────────────────────
const { validatePrice } = require("../utils/validators");

const Payment = require("../models/payment.model");
const Wallet = require("../models/wallet.model");
const Transaction = require("../models/transaction.model");

// ─── POST /api/payments/create-payment-intent ─────────────────────────────────
// Creates a Stripe PaymentIntent and returns clientSecret to frontend.
// Frontend NEVER receives the secret key here — only the clientSecret.
router.post("/create-payment-intent", verifyToken, async (req, res) => {
  try {
    const { bookingId, serviceType } = req.body;

    if (!bookingId || !serviceType) {
      return res.status(400).json({
        success: false,
        message: "bookingId and serviceType are required",
      });
    }

    const allowedTypes = ["Meal Provider", "Laundry", "Housing", "Maintenance"];
    if (!allowedTypes.includes(serviceType)) {
      return res.status(400).json({
        success: false,
        message: "Invalid serviceType",
      });
    }

    const result = await createPaymentIntent({
      bookingId,
      serviceType,
      userId: req.user.userId,
    });

    // ─── AMOUNT BOUNDS VALIDATION ────────────────────────────────────────
    const amount = result.amount || 0;
    if (!validatePrice(amount, 100, 500000)) {
      return res.status(400).json({
        success: false,
        message: "Payment amount must be between 100 and 500,000 PKR",
      });
    }

    res.status(200).json({
      success: true,
      clientSecret: result.clientSecret,
      paymentId: result.paymentId,
      amount: result.amount,
      commission: result.commission,
      providerAmount: result.providerAmount,
    });
  } catch (error) {
    console.error("Create payment intent error:", error.message);
    const statusCode = error.message.includes("not found")
      ? 404
      : error.message.includes("Unauthorized")
        ? 403
        : error.message.includes("already been paid")
          ? 409
          : 500;
    res.status(statusCode).json({ success: false, message: error.message });
  }
});

// ─── POST /api/payments/confirm ───────────────────────────────────────────────
// Called by Flutter after payment sheet succeeds.
// We verify with Stripe API before trusting anything.
router.post("/confirm", verifyToken, async (req, res) => {
  try {
    const { stripePaymentIntentId } = req.body;

    if (!stripePaymentIntentId) {
      return res
        .status(400)
        .json({ success: false, message: "stripePaymentIntentId is required" });
    }

    const result = await confirmPayment({
      stripePaymentIntentId,
      userId: req.user.userId,
    });

    res.status(200).json({
      success: true,
      message: "Payment confirmed successfully",
      payment: result.payment,
    });
  } catch (error) {
    console.error("Confirm payment error:", error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── POST /api/payments/release-escrow/:paymentId ────────────────────────────
// Releases escrow funds from pending to available wallet balance.
// Called when: order delivered, housing check-in confirmed, maintenance approved
router.post("/release-escrow/:paymentId", verifyToken, async (req, res) => {
  try {
    const result = await releaseEscrow(req.params.paymentId);
    res.status(200).json({
      success: true,
      message: "Escrow released to provider wallet",
      payment: result.payment,
      wallet: result.wallet,
    });
  } catch (error) {
    console.error("Release escrow error:", error.message);
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── GET /api/payments/my-payments ───────────────────────────────────────────
// Returns all payments for the logged-in user
router.get("/my-payments", verifyToken, async (req, res) => {
  try {
    const payments = await Payment.find({ userId: req.user.userId })
      .sort({ createdAt: -1 })
      .limit(50);
    res.status(200).json({ success: true, payments });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── GET /api/payments/wallet ─────────────────────────────────────────────────
// Returns wallet info for the logged-in provider
router.get("/wallet", verifyToken, async (req, res) => {
  try {
    let wallet = await Wallet.findOne({ userId: req.user.userId });
    if (!wallet) {
      wallet = await Wallet.create({ userId: req.user.userId });
    }
    const transactions = await Transaction.find({
      providerId: req.user.userId,
    })
      .sort({ createdAt: -1 })
      .limit(20);
    res.status(200).json({ success: true, wallet, transactions });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ─── GET /api/payments/publishable-key ───────────────────────────────────────
// Returns the Stripe publishable key to Flutter
// This is SAFE — publishable key can be in the app/frontend
router.get("/publishable-key", async (req, res) => {
  res.status(200).json({
    success: true,
    publishableKey: process.env.STRIPE_PUBLISHABLE_KEY,
  });
});

module.exports = router;

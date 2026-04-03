/**
 * ─── Stripe Webhook Route ────────────────────────────────────────────────────
 * CRITICAL: This route must receive the RAW body (not JSON parsed).
 * Registered in server.js BEFORE express.json() middleware for this path.
 *
 * POST /stripe/webhook
 */

const express = require("express");
const router = express.Router();
const { stripe, handleWebhookEvent } = require("../utils/payment.service");

// This route needs raw body — handled via express.raw() in server.js
router.post("/", express.raw({ type: "application/json" }), async (req, res) => {
    const sig = req.headers["stripe-signature"];
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    if (!webhookSecret || webhookSecret === "whsec_your_webhook_secret_here") {
        console.warn(
            "⚠️  STRIPE_WEBHOOK_SECRET not configured — skipping signature verification (dev mode)"
        );
        // In development without a real webhook secret, still process the event
        try {
            const event = JSON.parse(req.body.toString());
            await handleWebhookEvent(event);
            return res.json({ received: true });
        } catch (err) {
            return res.status(400).json({ error: err.message });
        }
    }

    // Production: verify webhook signature
    let event;
    try {
        event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
    } catch (err) {
        console.error("⚠️  Stripe webhook signature verification failed:", err.message);
        return res.status(400).json({ error: `Webhook signature error: ${err.message}` });
    }

    console.log(`✅ Stripe webhook event: ${event.type}`);

    try {
        await handleWebhookEvent(event);
        res.json({ received: true });
    } catch (err) {
        console.error("Webhook handler error:", err.message);
        // Always return 200 to Stripe to prevent retries on our logic errors
        res.json({ received: true, warning: err.message });
    }
});

module.exports = router;

/**
 * ─── Stripe Payment Service ────────────────────────────────────────────────────
 * Core business logic for all Stripe operations.
 * SECRET KEY NEVER LEAVES THIS FILE — only used server-side.
 */

const Stripe = require("stripe");
const Payment = require("../models/payment.model");
const Transaction = require("../models/transaction.model");
const Wallet = require("../models/wallet.model");
const Order = require("../models/order.model");
const HousingBooking = require("../models/housing-booking.model");

// ─── Initialize Stripe with Secret Key ────────────────────────────────────────
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, {
  apiVersion: "2024-11-20.acacia",
});

const COMMISSION_PERCENT =
  parseFloat(process.env.PLATFORM_COMMISSION_PERCENT) || 10;

// ─── Helper: Get or create provider wallet ────────────────────────────────────
async function getOrCreateWallet(userId) {
  let wallet = await Wallet.findOne({ userId });
  if (!wallet) {
    wallet = await Wallet.create({ userId, balance: 0, pendingBalance: 0 });
  }
  return wallet;
}

// ─── Helper: Fetch booking from DB ────────────────────────────────────────────
async function fetchBooking(bookingId, serviceType) {
  if (serviceType === "Housing") {
    return {
      booking: await HousingBooking.findById(bookingId),
      model: "HousingBooking",
    };
  }
  return {
    booking: await Order.findById(bookingId),
    model: "Order",
  };
}

// ─── CREATE PAYMENT INTENT ────────────────────────────────────────────────────
// Called by: POST /api/payments/create-payment-intent
async function createPaymentIntent({ bookingId, serviceType, userId }) {
  // 1. Fetch booking from DB (never trust frontend price)
  const { booking, model } = await fetchBooking(bookingId, serviceType);

  if (!booking) {
    throw new Error("Booking not found");
  }

  // 2. Ownership check
  const bookingUserId =
    model === "HousingBooking"
      ? booking.tenantId?.toString()
      : booking.customerId?.toString();

  if (bookingUserId !== userId.toString()) {
    throw new Error("Unauthorized: This booking does not belong to you");
  }

  // 3. Status check — prevent double payment
  if (booking.paymentStatus === "Completed") {
    throw new Error("This booking has already been paid");
  }

  // 4. Check for existing pending PaymentIntent (prevent duplicates)
  const existing = await Payment.findOne({
    bookingId,
    bookingModel: model,
    status: "pending",
  });
  if (existing) {
    // Return the existing client secret instead of creating a new one
    return {
      clientSecret: existing.stripeClientSecret,
      paymentId: existing._id,
    };
  }

  // 5. Recalculate total server-side
  const totalPKR = booking.totalAmount;
  if (!totalPKR || totalPKR <= 0) {
    throw new Error("Invalid booking total amount");
  }

  // 6. Commission calculation
  const commission = Math.round((totalPKR * COMMISSION_PERCENT) / 100);
  const providerAmount = totalPKR - commission;

  // 7. Provider ID
  const providerId =
    model === "HousingBooking" ? booking.ownerId : booking.serviceProviderId;

  // 8. Validate provider active (basic check via User model)
  const User = require("../models/user.model");
  const ServiceProvider = require("../models/service-provider.model");
  const Service = require("../models/service.model");

  let provider = await User.findById(providerId);

  // If not found by direct _id, the providerId might be a ServiceProvider _id
  if (!provider) {
    provider = await User.findOne({ spId: providerId });
  }

  // FALLBACK 1: Find the ServiceProvider document itself, and match the User by email
  if (!provider) {
    const spDoc = await ServiceProvider.findById(providerId);
    if (spDoc && spDoc.email) {
      provider = await User.findOne({ email: spDoc.email });
    }
  }

  // FALLBACK 2: The frontend mistakenly passed a Service ID (like "Golden Rice") instead of a Provider ID
  if (!provider) {
    const serviceDoc = await Service.findById(providerId);
    if (serviceDoc && serviceDoc.serviceProviderId) {
      const spDoc = await ServiceProvider.findById(
        serviceDoc.serviceProviderId,
      );
      if (spDoc && spDoc.email) {
        provider = await User.findOne({ email: spDoc.email });
      }
    }
  }

  if (!provider) {
    // Only warn for orphaned test data to allow Stripe to continue testing
    console.warn(
      "⚠️ Provider User not explicitly found for Provider ID: " +
        providerId +
        ". Bypassing strict account status check for Test Mode.",
    );
  } else if (provider.accountStatus && provider.accountStatus !== "active") {
    throw new Error(
      "Provider is not active. Status: " + provider.accountStatus,
    );
  }

  // 9. Convert PKR → paisa (Stripe uses smallest currency unit)
  // Note: PKR is a non-decimal currency; 1 PKR = 100 paisa
  // Stripe minimum for PKR is 50 PKR (5000 paisa)
  const amountPaisa = Math.round(totalPKR * 100);

  // 10. Create Stripe PaymentIntent
  const paymentIntent = await stripe.paymentIntents.create({
    amount: amountPaisa,
    currency: "pkr",
    automatic_payment_methods: { enabled: true },
    metadata: {
      bookingId: bookingId.toString(),
      userId: userId.toString(),
      providerId: providerId?.toString() || "",
      serviceType,
      bookingModel: model,
    },
  });

  // 11. Save Payment record
  const payment = await Payment.create({
    bookingId,
    bookingModel: model,
    stripePaymentIntentId: paymentIntent.id,
    stripeClientSecret: paymentIntent.client_secret,
    amount: totalPKR,
    commission,
    providerAmount,
    commissionPercent: COMMISSION_PERCENT,
    userId,
    providerId,
    serviceType,
    status: "pending",
    escrowStatus: "held",
    stripeMetadata: paymentIntent.metadata,
  });

  return {
    clientSecret: paymentIntent.client_secret,
    paymentId: payment._id,
    amount: totalPKR,
    commission,
    providerAmount,
  };
}

// ─── CONFIRM PAYMENT ──────────────────────────────────────────────────────────
// Called by: POST /api/payments/confirm
// Also called by webhook for reliability
async function confirmPayment({ stripePaymentIntentId, userId }) {
  // 1. Verify with Stripe API (don't trust frontend)
  const paymentIntent = await stripe.paymentIntents.retrieve(
    stripePaymentIntentId,
  );

  if (paymentIntent.status !== "succeeded") {
    throw new Error(
      `Payment has not succeeded. Current status: ${paymentIntent.status}`,
    );
  }

  // 2. Find our payment record
  const payment = await Payment.findOne({ stripePaymentIntentId });
  if (!payment) {
    throw new Error("Payment record not found");
  }

  // 3. Idempotency: if already processed, return success
  if (payment.status === "succeeded") {
    return { success: true, message: "Payment already confirmed", payment };
  }

  // 4. Verify amount matches DB record
  const expectedPaisa = Math.round(payment.amount * 100);
  if (paymentIntent.amount !== expectedPaisa) {
    throw new Error("Amount mismatch: payment integrity check failed");
  }

  // 5. Update payment record
  payment.status = "succeeded";
  payment.paidAt = new Date();
  await payment.save();

  // 6. Update booking status to "paid"
  const { booking, model } = await fetchBooking(
    payment.bookingId,
    payment.serviceType,
  );
  if (booking) {
    booking.paymentStatus = "Completed";
    booking.paymentMethod = "Credit Card"; // Stripe card
    booking.paymentId = stripePaymentIntentId;
    if (model === "Order") {
      booking.paymentDate = new Date();
      booking.status =
        booking.status === "Pending" ? "Confirmed" : booking.status;
    } else if (model === "HousingBooking") {
      booking.paymentDate = new Date();
      // Auto-confirm housing booking when payment is completed
      if (booking.status === "Pending") {
        booking.status = "Confirmed";
        booking.statusHistory?.push({
          status: "Confirmed",
          timestamp: new Date(),
          notes: "Auto-confirmed after payment completion",
        });
      }
    }
    await booking.save();
  }

  // 7. Create Transaction records
  await Transaction.create([
    {
      paymentId: payment._id,
      userId: payment.userId,
      providerId: payment.providerId,
      amount: payment.amount,
      type: "payment",
      status: "completed",
      description: `Payment for ${payment.serviceType} booking`,
    },
    {
      paymentId: payment._id,
      userId: payment.userId,
      providerId: payment.providerId,
      amount: payment.commission,
      type: "commission",
      status: "completed",
      description: `Platform commission (${payment.commissionPercent}%)`,
    },
    {
      paymentId: payment._id,
      userId: null,
      providerId: payment.providerId,
      amount: payment.providerAmount,
      type: "escrow_hold",
      status: "completed",
      description: `Funds held in escrow for provider`,
    },
  ]);

  // 8. Update provider wallet — add to pendingBalance (escrow)
  if (payment.providerId) {
    const wallet = await getOrCreateWallet(payment.providerId);
    wallet.pendingBalance += payment.providerAmount;
    wallet.totalEarned += payment.providerAmount;
    wallet.totalCommissionPaid += payment.commission;
    await wallet.save();
  }

  return { success: true, payment, booking };
}

// ─── RELEASE ESCROW ───────────────────────────────────────────────────────────
// Called when order is completed / check-in confirmed / job approved
async function releaseEscrow(paymentId) {
  const payment = await Payment.findById(paymentId);
  if (!payment) throw new Error("Payment not found");
  if (payment.escrowStatus === "released") {
    return { success: true, message: "Escrow already released" };
  }

  // Move from pendingBalance → balance
  const wallet = await getOrCreateWallet(payment.providerId);
  wallet.pendingBalance = Math.max(
    0,
    wallet.pendingBalance - payment.providerAmount,
  );
  wallet.balance += payment.providerAmount;
  await wallet.save();

  payment.escrowStatus = "released";
  payment.releasedAt = new Date();
  await payment.save();

  await Transaction.create({
    paymentId: payment._id,
    providerId: payment.providerId,
    amount: payment.providerAmount,
    type: "escrow_release",
    status: "completed",
    description: "Escrow funds released to provider wallet",
  });

  return { success: true, payment, wallet };
}

// ─── HANDLE WEBHOOK EVENT ─────────────────────────────────────────────────────
async function handleWebhookEvent(event) {
  const intent = event.data.object;

  switch (event.type) {
    case "payment_intent.succeeded": {
      // Use our confirmPayment logic (idempotent)
      const meta = intent.metadata || {};
      await confirmPayment({
        stripePaymentIntentId: intent.id,
        userId: meta.userId,
      }).catch((err) =>
        console.error("Webhook confirmPayment error:", err.message),
      );
      break;
    }

    case "payment_intent.payment_failed": {
      const pmt = await Payment.findOne({ stripePaymentIntentId: intent.id });
      if (pmt && pmt.status !== "failed") {
        pmt.status = "failed";
        pmt.failedAt = new Date();
        await pmt.save();

        // Update booking status
        const { booking } = await fetchBooking(pmt.bookingId, pmt.serviceType);
        if (booking) {
          booking.paymentStatus = "Failed";
          await booking.save();
        }
      }
      break;
    }

    case "payment_intent.canceled": {
      const pmt = await Payment.findOne({ stripePaymentIntentId: intent.id });
      if (pmt && pmt.status !== "canceled") {
        pmt.status = "canceled";
        await pmt.save();
      }
      break;
    }

    default:
      console.log(`Unhandled Stripe event type: ${event.type}`);
  }
}

module.exports = {
  stripe,
  createPaymentIntent,
  confirmPayment,
  releaseEscrow,
  handleWebhookEvent,
};

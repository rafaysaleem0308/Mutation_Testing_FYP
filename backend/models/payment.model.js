const mongoose = require("mongoose");

// ─── Payment Model ────────────────────────────────────────────────────────────
// Represents a Stripe payment linked to a booking
const paymentSchema = new mongoose.Schema(
    {
        // Reference to the booking (polymorphic: Order or HousingBooking)
        bookingId: {
            type: mongoose.Schema.Types.ObjectId,
            required: true,
            index: true,
        },
        bookingModel: {
            type: String,
            required: true,
            enum: ["Order", "HousingBooking"],
        },

        // Stripe identifiers
        stripePaymentIntentId: {
            type: String,
            required: true,
            unique: true,
            index: true,
        },
        stripeClientSecret: {
            type: String,
        },

        // Financial breakdown (stored in PKR, Stripe receives paisa = PKR * 100)
        amount: {
            type: Number, // Total charged amount (PKR)
            required: true,
            min: 0,
        },
        commission: {
            type: Number, // Platform commission taken (PKR)
            default: 0,
            min: 0,
        },
        providerAmount: {
            type: Number, // Amount due to provider after commission (PKR)
            default: 0,
            min: 0,
        },
        commissionPercent: {
            type: Number,
            default: 10,
        },

        // Parties
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true,
        },
        providerId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            index: true,
        },

        // Service context
        serviceType: {
            type: String,
            enum: ["Meal Provider", "Laundry", "Housing", "Maintenance"],
            required: true,
        },

        // Status mirrors Stripe PaymentIntent status
        status: {
            type: String,
            enum: ["pending", "succeeded", "failed", "canceled", "refunded"],
            default: "pending",
            index: true,
        },

        // Escrow / payout status
        escrowStatus: {
            type: String,
            enum: ["held", "released", "refunded"],
            default: "held",
        },
        releasedAt: { type: Date },

        // Stripe metadata
        stripeMetadata: { type: mongoose.Schema.Types.Mixed },

        // Timestamps of Stripe events
        paidAt: { type: Date },
        failedAt: { type: Date },
    },
    {
        timestamps: true,
        collection: "payments",
    }
);

paymentSchema.index({ userId: 1, createdAt: -1 });
paymentSchema.index({ providerId: 1, status: 1 });
paymentSchema.index({ bookingId: 1, bookingModel: 1 });

const Payment = mongoose.model("Payment", paymentSchema);
module.exports = Payment;

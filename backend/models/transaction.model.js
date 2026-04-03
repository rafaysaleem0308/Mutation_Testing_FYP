const mongoose = require("mongoose");

// ─── Transaction Model ────────────────────────────────────────────────────────
// Audit trail of every financial movement in the platform
const transactionSchema = new mongoose.Schema(
    {
        paymentId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Payment",
            index: true,
        },
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            index: true,
        },
        providerId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            index: true,
        },
        amount: {
            type: Number,
            required: true,
        },
        type: {
            type: String,
            enum: ["payment", "commission", "payout", "refund", "escrow_hold", "escrow_release"],
            required: true,
        },
        status: {
            type: String,
            enum: ["pending", "completed", "failed"],
            default: "completed",
        },
        description: { type: String },
        metadata: { type: mongoose.Schema.Types.Mixed },
    },
    {
        timestamps: true,
        collection: "transactions",
    }
);

transactionSchema.index({ userId: 1, createdAt: -1 });
transactionSchema.index({ providerId: 1, type: 1 });

const Transaction = mongoose.model("Transaction", transactionSchema);
module.exports = Transaction;

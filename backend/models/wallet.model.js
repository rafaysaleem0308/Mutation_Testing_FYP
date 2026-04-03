const mongoose = require("mongoose");

// ─── Wallet Model ─────────────────────────────────────────────────────────────
// One wallet per user (provider). Tracks balance & pending (in escrow) amount.
const walletSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            unique: true,
            index: true,
        },
        balance: {
            type: Number, // Available / released balance (PKR)
            default: 0,
            min: 0,
        },
        pendingBalance: {
            type: Number, // Funds in escrow (PKR)
            default: 0,
            min: 0,
        },
        totalEarned: {
            type: Number, // Lifetime earnings after commission (PKR)
            default: 0,
        },
        totalCommissionPaid: {
            type: Number, // Lifetime commission paid to platform (PKR)
            default: 0,
        },
    },
    {
        timestamps: true,
        collection: "wallets",
    }
);

const Wallet = mongoose.model("Wallet", walletSchema);
module.exports = Wallet;

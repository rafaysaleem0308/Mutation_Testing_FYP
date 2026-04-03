const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true,
        },
        title: {
            type: String,
            required: true,
        },
        body: {
            type: String,
            required: true,
        },
        type: {
            type: String,
            enum: [
                "order_placed",
                "order_accepted",
                "order_ready",
                "order_delivered",
                "order_cancelled",
                "new_message",
                "new_review",
                "promo",
                "system",
                "welcome",
            ],
            default: "system",
        },
        // Optional reference to related data
        referenceId: {
            type: String,
            default: null,
        },
        referenceType: {
            type: String,
            enum: ["order", "chat", "service", "review", null],
            default: null,
        },
        isRead: {
            type: Boolean,
            default: false,
        },
        icon: {
            type: String,
            default: "notifications",
        },
    },
    {
        timestamps: true,
    }
);

// Index for efficient querying
notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, isRead: 1 });

module.exports = mongoose.model("Notification", notificationSchema);

const mongoose = require("mongoose");

const housingVisitSchema = new mongoose.Schema(
    {
        // ─── References ───────────────────────────────────────────────────
        propertyId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "HousingProperty",
            required: true,
            index: true,
        },
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true,
        },
        ownerId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "ServiceProvider",
            required: true,
            index: true,
        },

        // ─── Schedule Details ─────────────────────────────────────────────
        visitDate: { type: Date, required: true },
        visitTime: { type: String, required: true },
        rescheduledDate: { type: Date },
        rescheduledTime: { type: String },

        // ─── Status ───────────────────────────────────────────────────────
        status: {
            type: String,
            enum: ["Pending", "Accepted", "Rejected", "Rescheduled", "Completed", "Cancelled"],
            default: "Pending",
            index: true,
        },

        // ─── Notes ────────────────────────────────────────────────────────
        userMessage: { type: String },
        ownerNotes: { type: String },

        // ─── Denormalized Info ────────────────────────────────────────────
        userName: { type: String },
        userPhone: { type: String },
        ownerName: { type: String },
        propertyTitle: { type: String },
        propertyAddress: { type: String },
    },
    {
        collection: "housing_visits",
        timestamps: true,
    }
);

// ─── Indexes ──────────────────────────────────────────────────────────────────
housingVisitSchema.index({ userId: 1, createdAt: -1 });
housingVisitSchema.index({ ownerId: 1, status: 1 });

const HousingVisit = mongoose.model("HousingVisit", housingVisitSchema);

module.exports = HousingVisit;

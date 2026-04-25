const mongoose = require("mongoose");

const housingBookingSchema = new mongoose.Schema(
    {
        // ─── Booking Number ───────────────────────────────────────────────
        bookingNumber: {
            type: String,
            unique: true,
            index: true,
        },

        // ─── References ───────────────────────────────────────────────────
        propertyId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "HousingProperty",
            required: true,
            index: true,
        },
        tenantId: {
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

        // ─── Booking Details ──────────────────────────────────────────────
        moveInDate: { type: Date, required: true },
        moveOutDate: { type: Date },
        duration: { type: String, default: "1 Month" },

        // ─── Financial ────────────────────────────────────────────────────
        monthlyRent: { type: Number, required: true },
        securityDeposit: { type: Number, default: 0 },
        advanceRent: { type: Number, default: 0 },
        totalAmount: { type: Number, required: true },
        platformCommission: { type: Number, default: 0 },
        ownerEarnings: { type: Number, default: 0 },

        // ─── Payment ──────────────────────────────────────────────────────
        paymentMethod: {
            type: String,
            enum: ["Cash on Delivery", "Credit Card", "Mobile Payment", "Bank Transfer"],
            default: "Cash on Delivery",
        },
        paymentStatus: {
            type: String,
            enum: ["Pending", "Completed", "Failed", "Refunded"],
            default: "Pending",
        },
        paymentId: { type: String },

        // ─── Status ───────────────────────────────────────────────────────
        status: {
            type: String,
            enum: ["Pending", "Accepted", "Rejected", "Confirmed", "Completed", "Cancelled"],
            default: "Pending",
            index: true,
        },
        statusHistory: [
            {
                status: String,
                timestamp: { type: Date, default: Date.now },
                notes: String,
                changedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
            },
        ],

        // ─── Cancellation ─────────────────────────────────────────────────
        cancellationReason: { type: String },
        cancelledBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
        cancellationDate: { type: Date },

        // ─── Tenant Info (denormalized) ───────────────────────────────────
        tenantName: { type: String },
        tenantEmail: { type: String },
        tenantPhone: { type: String },

        // ─── Owner Info (denormalized) ────────────────────────────────────
        ownerName: { type: String },

        // ─── Property Info (denormalized) ─────────────────────────────────
        propertyTitle: { type: String },
        propertyType: { type: String },
        propertyAddress: { type: String },

        // ─── Notes ────────────────────────────────────────────────────────
        notes: { type: String },
    },
    {
        collection: "housing_bookings",
        timestamps: true,
        toJSON: { virtuals: true },
        toObject: { virtuals: true },
    }
);

// ─── Pre-save: Generate booking number ────────────────────────────────────────
housingBookingSchema.pre("save", function () {
    if (!this.bookingNumber) {
        const ts = Date.now().toString().slice(-10);
        const rand = Math.floor(Math.random() * 10000).toString().padStart(4, "0");
        this.bookingNumber = `HB${ts}${rand}`;
    }
});

// ─── Indexes ──────────────────────────────────────────────────────────────────
housingBookingSchema.index({ tenantId: 1, createdAt: -1 });
housingBookingSchema.index({ ownerId: 1, status: 1 });

const HousingBooking = mongoose.model("HousingBooking", housingBookingSchema);

module.exports = HousingBooking;

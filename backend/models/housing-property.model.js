const mongoose = require("mongoose");

const housingPropertySchema = new mongoose.Schema(
    {
        // ─── Basic Information ────────────────────────────────────────────
        title: { type: String, required: true, trim: true },
        description: { type: String, required: true, trim: true },
        propertyType: {
            type: String,
            required: true,
            enum: ["Room", "Flat", "Hostel", "Apartment", "Shared Room", "Portion"],
        },

        // ─── Owner Reference ──────────────────────────────────────────────
        ownerId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "ServiceProvider",
            required: true,
            index: true,
        },
        ownerUserId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            index: true,
        },

        // ─── Pricing ──────────────────────────────────────────────────────
        monthlyRent: { type: Number, required: true, min: 0 },
        securityDeposit: { type: Number, default: 0, min: 0 },
        advanceRent: { type: Number, default: 0, min: 0 },

        // ─── Images ───────────────────────────────────────────────────────
        images: [{ type: String }],
        thumbnailImage: { type: String },

        // ─── Location ─────────────────────────────────────────────────────
        address: { type: String, required: true },
        city: { type: String, required: true, index: true },
        area: { type: String },
        location: {
            type: { type: String, enum: ["Point"], default: "Point" },
            coordinates: { type: [Number], default: [0, 0] }, // [lng, lat]
        },

        // ─── Facilities ───────────────────────────────────────────────────
        facilities: {
            wifi: { type: Boolean, default: false },
            electricity: { type: Boolean, default: true },
            gas: { type: Boolean, default: false },
            water: { type: Boolean, default: true },
            ac: { type: Boolean, default: false },
            furniture: { type: Boolean, default: false },
            kitchen: { type: Boolean, default: false },
            parking: { type: Boolean, default: false },
            laundry: { type: Boolean, default: false },
            security: { type: Boolean, default: false },
            cctv: { type: Boolean, default: false },
            generator: { type: Boolean, default: false },
        },

        // ─── Property Details ─────────────────────────────────────────────
        bedrooms: { type: Number, default: 1, min: 0 },
        bathrooms: { type: Number, default: 1, min: 0 },
        area_sqft: { type: Number, default: 0 },
        floor: { type: String },
        furnished: {
            type: String,
            enum: ["Furnished", "Semi-Furnished", "Unfurnished"],
            default: "Unfurnished",
        },

        // ─── Occupancy ────────────────────────────────────────────────────
        genderPreference: {
            type: String,
            enum: ["Male", "Female", "Family", "Any"],
            default: "Any",
        },
        roomType: {
            type: String,
            enum: ["Private", "Shared"],
            default: "Private",
        },
        maxOccupants: { type: Number, default: 1, min: 1 },
        currentOccupants: { type: Number, default: 0, min: 0 },

        // ─── Availability ─────────────────────────────────────────────────
        availableFrom: { type: Date, default: Date.now },
        isAvailable: { type: Boolean, default: true },

        // ─── House Rules ──────────────────────────────────────────────────
        houseRules: [{ type: String }],

        // ─── Approval & Status ────────────────────────────────────────────
        status: {
            type: String,
            enum: ["pending_approval", "approved", "rejected", "suspended"],
            default: "pending_approval",
            index: true,
        },
        rejectionReason: { type: String },
        approvedBy: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
        approvedAt: { type: Date },

        // ─── Stats ────────────────────────────────────────────────────────
        rating: { type: Number, default: 0 },
        totalReviews: { type: Number, default: 0 },
        totalBookings: { type: Number, default: 0 },
        viewsCount: { type: Number, default: 0 },
        favoritesCount: { type: Number, default: 0 },
    },
    {
        collection: "housing_properties",
        timestamps: true,
        toJSON: { virtuals: true },
        toObject: { virtuals: true },
    }
);

// ─── Indexes ──────────────────────────────────────────────────────────────────
housingPropertySchema.index({ location: "2dsphere" });
housingPropertySchema.index({ status: 1, city: 1 });
housingPropertySchema.index({ ownerId: 1, status: 1 });
housingPropertySchema.index({ propertyType: 1, status: 1 });
housingPropertySchema.index({ monthlyRent: 1 });
housingPropertySchema.index({ createdAt: -1 });

const HousingProperty = mongoose.model("HousingProperty", housingPropertySchema);

module.exports = HousingProperty;

const mongoose = require("mongoose");

const serviceSchema = new mongoose.Schema(
  {
    // ─── Basic Information ──────────────────────────────────────────────────────
    serviceName: { type: String, required: true },
    description: { type: String },
    price: { type: Number, required: true },
    unit: { type: String, required: true },
    serviceType: {
      type: String,
      required: true,
      enum: ["Meal Provider", "Hostel/Flat Accommodation", "Laundry", "Maintenance"],
    },

    // ─── Service Provider Reference ─────────────────────────────────────────────
    serviceProviderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "ServiceProvider",
      required: true,
    },
    serviceProviderRole: { type: String, required: true },
    serviceProviderName: { type: String },
    serviceProviderEmail: { type: String },
    serviceProviderPhone: { type: String },
    serviceProviderCity: { type: String },
    serviceProviderAddress: { type: String },

    // ─── Meal Provider Fields ───────────────────────────────────────────────────
    mealType: { type: String },
    cuisineType: { type: String },
    isVegetarian: { type: Boolean, default: false },
    isSpicy: { type: Boolean, default: false },
    hasDairy: { type: Boolean, default: false },
    hasGluten: { type: Boolean, default: false },
    preparationTime: { type: String },
    deliveryTime: { type: String },
    deliveryAvailable: { type: Boolean, default: true },
    pickupAvailable: { type: Boolean, default: true },

    // ─── Meal Details ───────────────────────────────────────────────────────────
    ingredients: [{ type: String }],
    allergens: [{ type: String }],
    nutritionInfo: {
      calories: { type: Number },
      protein: { type: Number },
      carbs: { type: Number },
      fat: { type: Number },
    },

    // ─── Images ─────────────────────────────────────────────────────────────────
    imageUrl: { type: String },
    additionalImages: [{ type: String }],

    // ─── Laundry Fields ─────────────────────────────────────────────────────────
    laundryType: { type: String },

    // ─── Accommodation Fields ───────────────────────────────────────────────────
    accommodationType: { type: String },
    address: { type: String },
    contactNumber: { type: String },
    availableRooms: { type: Number },
    roomFeatures: [{ type: String }],
    isShared: { type: Boolean, default: false },
    currentOccupants: { type: Number, default: 0 },
    maxOccupants: { type: Number, default: 1 },
    location: {
      type: { type: String, enum: ["Point"], default: "Point" },
      coordinates: { type: [Number], default: [0, 0] },
    },

    // ─── Maintenance Fields ─────────────────────────────────────────────────────
    expertise: { type: String },
    servicesOffered: [{ type: String }],
    experience: { type: String },

    // ─── Rating & Reviews ───────────────────────────────────────────────────────
    rating: { type: Number, default: 0 },
    totalReviews: { type: Number, default: 0 },
    totalOrders: { type: Number, default: 0 },

    // ─── Availability ───────────────────────────────────────────────────────────
    availableDays: [{
      type: String,
      enum: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
    }],
    availableTimeSlots: [{
      startTime: { type: String },
      endTime: { type: String },
    }],

    // ─── Status ─────────────────────────────────────────────────────────────────
    status: {
      type: String,
      enum: ["Active", "Inactive", "Out of Stock", "Pending"],
      default: "Active",
    },

    // ─── Metadata ───────────────────────────────────────────────────────────────
    featured: { type: Boolean, default: false },
    discountPercentage: { type: Number, default: 0 },
    tags: [{ type: String }],
  },
  {
    collection: "services",
    timestamps: true,
  }
);

// ─── Indexes ──────────────────────────────────────────────────────────────────
serviceSchema.index({ serviceType: 1, status: 1 });
serviceSchema.index({ serviceProviderId: 1 });
serviceSchema.index({ "nutritionInfo.calories": 1 });
serviceSchema.index({ tags: 1 });
serviceSchema.index({ location: "2dsphere" });

const Service = mongoose.model("Service", serviceSchema);

module.exports = Service;

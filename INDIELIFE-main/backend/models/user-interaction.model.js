const mongoose = require("mongoose");

const userInteractionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    interactionType: {
      type: String,
      enum: ["view", "click", "cart_add", "cart_remove", "favorite", "review"],
      required: true,
    },
    serviceId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Service",
    },
    serviceType: String, // "Hostel", "Laundry", "Maintenance", "Meal"
    providerId: mongoose.Schema.Types.ObjectId, // For tracking provider
    rating: Number, // For review interactions
    metadata: {
      timeSpent: Number, // Seconds
      scrollDepth: Number, // Percentage
      source: String, // "search", "featured", "top-rated", "recommendation"
    },
    createdAt: {
      type: Date,
      default: Date.now,
      index: true,
    },
  },
  { timestamps: true },
);

// Indexes for efficient querying
userInteractionSchema.index({ userId: 1, createdAt: -1 });
userInteractionSchema.index({ userId: 1, interactionType: 1 });
userInteractionSchema.index({ userId: 1, serviceType: 1 });
userInteractionSchema.index({ userId: 1, serviceId: 1 });

const UserInteraction = mongoose.model(
  "UserInteraction",
  userInteractionSchema,
);

module.exports = UserInteraction;

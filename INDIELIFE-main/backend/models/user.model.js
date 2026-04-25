const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    role: {
      type: String,
      required: true,
      enum: ["user", "service_provider", "admin"],
    },

    // Authentication
    username: { type: String, required: true, unique: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },

    // Personal Information
    firstName: { type: String, required: true },
    lastName: { type: String, required: true },
    phone: { type: String, required: true },
    city: { type: String, required: true },
    address: { type: String },

    // Profile
    profileImage: { type: String },
    bio: { type: String },
    rating: { type: Number, default: 0 },

    // For users
    familyName: { type: String },
    familyPhone: { type: String },
    roommateName: { type: String },
    roommatePhone: { type: String },

    // For service providers
    spSubRole: {
      type: String,
      enum: [
        "Meal Provider",
        "Laundry",
        "Hostel/Flat Accommodation",
        "Maintenance",
        null,
      ],
    },
    spName: { type: String },
    spEmail: { type: String },
    spPhone: { type: String },
    spId: { type: mongoose.Schema.Types.ObjectId, ref: "ServiceProvider" }, // Reference to ServiceProvider
    districtName: { type: String },
    districtNazim: { type: String },
    isVerified: { type: Boolean, default: false },

    // Stats
    points: { type: Number, default: 0 },
    activeOrders: { type: Number, default: 0 },
    totalOrders: { type: Number, default: 0 },

    // Preferences
    preferences: {
      notifications: { type: Boolean, default: true },
      emailNotifications: { type: Boolean, default: true },
    },

    // Timestamps
    lastLogin: { type: Date },
    accountStatus: {
      type: String,
      enum: ["active", "suspended", "deactivated"],
      default: "active",
    },
  },
  {
    collection: "User_data",
    timestamps: true,
  },
);

// Add indexes for better query performance
userSchema.index({ role: 1, spSubRole: 1 });
userSchema.index({ city: 1 });

const User = mongoose.model("User", userSchema);

module.exports = User;

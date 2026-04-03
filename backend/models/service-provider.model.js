const mongoose = require("mongoose");

const spSchema = new mongoose.Schema(
  {
    // Personal Information
    firstName: { type: String, required: true },
    lastName: { type: String, required: true },

    // Contact Information
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    phone: { type: String, required: true, unique: true },

    // Location Information
    city: { type: String, required: true },
    address: { type: String, required: true },
    location: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
      },
      coordinates: {
        type: [Number],
        default: [0, 0], // [longitude, latitude]
      },
    },

    // NEW FIELD: District Name
    districtName: { type: String, required: true },

    // NEW FIELD: District Nazim Name
    districtNazim: { type: String, required: true },

    // Service Information
    spSubRole: {
      type: String,
      required: true,
      enum: [
        "Meal Provider",
        "Hostel/Flat Accommodation",
        "Laundry",
        "Maintenance",
      ],
    },

    // Service Details
    serviceName: { type: String },
    description: { type: String },
    bio: { type: String }, // Professional Bio
    profileImage: { type: String },
    gallery: [{ type: String }], // Work photos

    // Professional Info
    experienceYears: { type: Number, default: 0 },
    certifications: [{ type: String }], // List of cert names/images
    languages: [{ type: String }], // e.g., English, Urdu
    skills: [{ type: String }], // Specific skills e.g., "Pipe Fitting", "Wiring"
    servicesOffered: [{ type: String }], // High level services e.g., "Kitchen Plumbing", "Switchboard Repair"

    // Additional fields
    ismnAddress: { type: String },

    // Verification status
    isVerified: { type: Boolean, default: false },
    isActive: { type: Boolean, default: true },
    status: {
      type: String,
      enum: ["pending", "approved", "rejected", "suspended"],
      default: "pending",
    },

    // Stats for quick access
    totalOrders: { type: Number, default: 0 },
    totalEarnings: { type: Number, default: 0 },
    rating: { type: Number, default: 0 },
    reviewsCount: { type: Number, default: 0 },

    // Availability
    isAvailable: { type: Boolean, default: true },
    pickupAvailable: { type: Boolean, default: true },
    deliveryAvailable: { type: Boolean, default: true },
    openingHours: {
      from: { type: String, default: "09:00" },
      to: { type: String, default: "22:00" },
    },
  },
  {
    collection: "Service_provider_data",
    timestamps: true,
  },
);

// Add index for better performance
spSchema.index({ spSubRole: 1 });
spSchema.index({ city: 1 });
spSchema.index({ isVerified: 1 });
spSchema.index({ isActive: 1 });
spSchema.index({ location: "2dsphere" });

// Virtual for full name
spSchema.virtual("fullName").get(function () {
  return `${this.firstName} ${this.lastName}`;
});

const ServiceProvider = mongoose.model("ServiceProvider", spSchema);

module.exports = ServiceProvider;

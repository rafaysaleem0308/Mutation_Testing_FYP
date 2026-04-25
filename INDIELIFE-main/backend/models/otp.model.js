const mongoose = require("mongoose");

const OtpSchema = new mongoose.Schema(
  {
    identifier: { type: String, required: true, unique: true, index: true }, // email
    otp: { type: String, required: true },
    role: { type: String, required: true }, // 'User' or 'Service Provider'
    type: { type: String, default: "signup" }, // 'signup', 'reset', etc.
    verified: { type: Boolean, default: false },
    expiresAt: { type: Date, required: true, index: { expires: 0 } }, // TTL index - auto-delete after expiry
    createdAt: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

// Create TTL index for automatic deletion of expired OTPs
OtpSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model("Otp", OtpSchema);

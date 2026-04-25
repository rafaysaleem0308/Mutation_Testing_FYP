const mongoose = require("mongoose");

const refreshTokenSchema = new mongoose.Schema({
    token: {
        type: String,
        required: true,
        unique: true,
        index: true,
    },
    userId: {
        type: String,
        required: true,
        index: true,
    },
    role: {
        type: String,
        required: true,
        enum: ["user", "service_provider", "admin", "super_admin"],
    },
    // Which collection the user belongs to
    userModel: {
        type: String,
        required: true,
        enum: ["User", "ServiceProvider"],
    },
    deviceInfo: {
        type: String,
        default: "unknown",
    },
    expiresAt: {
        type: Date,
        required: true,
        index: { expireAfterSeconds: 0 }, // TTL index — MongoDB auto-deletes expired docs
    },
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

module.exports = mongoose.model("RefreshToken", refreshTokenSchema);

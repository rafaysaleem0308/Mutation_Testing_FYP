const mongoose = require("mongoose");

const OtpSchema = new mongoose.Schema({
  identifier: { type: String, required: true }, // phone or email
  otp: { type: String, required: true },
  expiry: { type: Date, required: true },
});

module.exports = mongoose.model("Otp", OtpSchema);

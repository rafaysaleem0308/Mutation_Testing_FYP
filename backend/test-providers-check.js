require("dotenv").config();
const mongoose = require("mongoose");
const { connectDatabase } = require("./config/database");

(async () => {
  try {
    await connectDatabase();

    const ServiceProvider = require("./models/service-provider.model");

    // Get Manahil Pakeeza provider
    const manahil = await ServiceProvider.findById(
      "69d29f3909ce95127ee91e35",
    ).lean();

    if (manahil) {
      console.log("✓ Manahil Pakeeza found:");
      console.log("  ID:", manahil._id);
      console.log("  First Name:", manahil.firstName);
      console.log("  Last Name:", manahil.lastName);
      console.log("  Email:", manahil.email);
      console.log("  Phone:", manahil.phone);
      console.log("  Status:", manahil.status);
      console.log("  Verified:", manahil.isVerified);
    } else {
      console.log("❌ Manahil Pakeeza not found");
    }

    // Get all providers
    const all = await ServiceProvider.find()
      .select("firstName lastName email status")
      .lean();
    console.log("\nAll providers:");
    all.forEach((p, i) => {
      console.log(
        `  ${i + 1}. ${p.firstName || "N/A"} ${p.lastName || "N/A"} - ${p.email} (${p.status})`,
      );
    });

    process.exit(0);
  } catch (err) {
    console.error("Error:", err.message);
    process.exit(1);
  }
})();

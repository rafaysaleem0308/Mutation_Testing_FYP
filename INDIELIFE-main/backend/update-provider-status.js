require("dotenv").config();
const mongoose = require("mongoose");
const { connectDatabase } = require("./config/database");

(async () => {
  try {
    await connectDatabase();

    const ServiceProvider = require("./models/service-provider.model");

    // Update all providers without a status to "approved"
    const result = await ServiceProvider.updateMany(
      { status: { $exists: false } },
      { status: "approved", isVerified: true, isActive: true },
    );

    console.log("✓ Updated providers");
    console.log(`  Matched: ${result.matchedCount}`);
    console.log(`  Modified: ${result.modifiedCount}`);

    // Verify the update
    const updated = await ServiceProvider.find({ status: "approved" })
      .select("firstName lastName email")
      .lean();
    console.log(`\n✓ Total approved providers now: ${updated.length}`);
    updated.forEach((p, i) => {
      console.log(`  ${i + 1}. ${p.firstName} ${p.lastName} - ${p.email}`);
    });

    process.exit(0);
  } catch (err) {
    console.error("Error:", err.message);
    process.exit(1);
  }
})();

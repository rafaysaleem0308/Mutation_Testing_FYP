require("dotenv").config();
const mongoose = require("mongoose");
const { connectDatabase } = require("./config/database");

(async () => {
  try {
    await connectDatabase();
    const ServiceProvider = require("./models/service-provider.model");

    const statuses = ["pending", "approved", "suspended", "rejected"];
    console.log("Providers by status:");

    for (const status of statuses) {
      const count = await ServiceProvider.countDocuments({ status });
      console.log(`  ${status}: ${count}`);
    }

    // Also check how many don't have status field at all
    const noStatus = await ServiceProvider.countDocuments({
      status: { $exists: false },
    });
    console.log(`  (no status field): ${noStatus}`);

    process.exit(0);
  } catch (err) {
    console.error("Error:", err.message);
    process.exit(1);
  }
})();

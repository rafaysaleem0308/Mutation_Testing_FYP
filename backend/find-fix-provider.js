require("dotenv").config();
const mongoose = require("mongoose");
const { connectDatabase } = require("./config/database");

(async () => {
  try {
    await connectDatabase();

    const ServiceProvider = require("./models/service-provider.model");

    // Find provider with undefined firstName
    const provider = await ServiceProvider.findOne({ firstName: undefined });

    if (provider) {
      console.log("Found provider:", provider.email);
      console.log("Updating with names...");

      provider.firstName = "Talha";
      provider.lastName = "Khan";
      await provider.save();

      console.log("✓ Updated provider");
      console.log("New name:", provider.firstName, provider.lastName);
    } else {
      console.log("No provider with undefined firstName found");

      // List all providers
      const all = await ServiceProvider.find()
        .select("firstName lastName email")
        .lean();
      console.log("\nAll providers:");
      all.forEach((p, i) => {
        console.log(
          `  ${i + 1}. ${p.firstName || "(undefined)"} ${p.lastName || "(undefined)"} - ${p.email}`,
        );
      });
    }

    process.exit(0);
  } catch (err) {
    console.error("Error:", err.message);
    process.exit(1);
  }
})();

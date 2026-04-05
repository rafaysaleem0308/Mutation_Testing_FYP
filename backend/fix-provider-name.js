require("dotenv").config();
const mongoose = require("mongoose");
const { connectDatabase } = require("./config/database");

(async () => {
  try {
    await connectDatabase();

    const ServiceProvider = require("./models/service-provider.model");

    // Find provider with undefined firstName
    const provider = await ServiceProvider.findOne({
      email: "talha123@gmail.com",
    });

    if (provider) {
      console.log("Found provider:", provider.email);
      console.log("Current firstName:", provider.firstName);
      console.log("Current lastName:", provider.lastName);

      // Update with default names extracted from email or assign generic names
      provider.firstName = provider.firstName || "Talha";
      provider.lastName = provider.lastName || "User";
      await provider.save();

      console.log("\n✓ Updated provider");
      console.log("New name:", provider.firstName, provider.lastName);
    } else {
      console.log("Provider not found");
    }

    process.exit(0);
  } catch (err) {
    console.error("Error:", err.message);
    process.exit(1);
  }
})();

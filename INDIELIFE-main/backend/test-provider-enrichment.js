require("dotenv").config();
const mongoose = require("mongoose");
const { connectDatabase } = require("./config/database");

(async () => {
  try {
    await connectDatabase();
    console.log("Connected to DB\n");

    const Service = require("./models/service.model");

    // Test the populate logic with actual housing services
    const services = await Service.find({
      serviceType: "Hostel/Flat Accommodation",
    })
      .populate("serviceProviderId", "firstName lastName email phone city")
      .lean()
      .limit(2);

    console.log("Testing provider enrichment for housing services:\n");
    services.forEach((s, i) => {
      console.log(`Service ${i + 1}: ${s.serviceName}`);
      console.log(
        "  serviceProviderId object:",
        JSON.stringify(s.serviceProviderId, null, 2),
      );
      console.log("  serviceProviderName from DB:", s.serviceProviderName);

      // Simulate the enrichment logic from admin.routes.js
      const provider = s.serviceProviderId;
      let providerName = "N/A";

      if (provider && (provider.firstName || provider.lastName)) {
        providerName =
          `${provider.firstName || ""} ${provider.lastName || ""}`.trim();
      } else if (s.serviceProviderName) {
        providerName = s.serviceProviderName;
      }

      console.log("  ✓ ENRICHED providerName:", providerName);
      console.log("");
    });

    process.exit(0);
  } catch (err) {
    console.error("Error:", err.message);
    process.exit(1);
  }
})();

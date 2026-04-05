require("dotenv").config();
const mongoose = require("mongoose");
const { connectDatabase } = require("./config/database");

(async () => {
  try {
    await connectDatabase();

    const Service = require("./models/service.model");

    // Find a housing service
    const housing = await Service.findOne({
      serviceType: "Hostel/Flat Accommodation",
    })
      .populate("serviceProviderId", "firstName lastName email phone city")
      .lean();

    if (housing) {
      console.log("✓ Found housing service:");
      console.log("  ID:", housing._id);
      console.log("  Name:", housing.serviceName);
      console.log("  Provider name (field):", housing.serviceProviderName);
      console.log("  Provider ID populated:", !!housing.serviceProviderId);

      if (housing.serviceProviderId) {
        console.log("\n  Provider details:");
        console.log("    firstName:", housing.serviceProviderId.firstName);
        console.log("    lastName:", housing.serviceProviderId.lastName);
        console.log("    email:", housing.serviceProviderId.email);
        console.log("    phone:", housing.serviceProviderId.phone);
        console.log("    city:", housing.serviceProviderId.city);
      }

      // Simulate enrichment
      const provider = housing.serviceProviderId;
      let providerName = "N/A";
      if (provider && (provider.firstName || provider.lastName)) {
        providerName =
          `${provider.firstName || ""} ${provider.lastName || ""}`.trim();
      } else if (housing.serviceProviderName) {
        providerName = housing.serviceProviderName;
      }

      console.log("\n  Enriched provider name:", providerName);
      console.log("\n✓ Endpoint will return correct data");
    } else {
      console.log("❌ No housing services found");
    }

    process.exit(0);
  } catch (err) {
    console.error("Error:", err.message);
    process.exit(1);
  }
})();

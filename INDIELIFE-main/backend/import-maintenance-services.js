const mongoose = require("mongoose");
const fs = require("fs");
const path = require("path");
const Service = require("./models/service.model");

const MONGODB_URI = "mongodb://localhost:27017/IndieLife";

async function importServices() {
  try {
    console.log("🔄 Connecting to MongoDB...");
    await mongoose.connect(MONGODB_URI);
    console.log("✅ Connected to MongoDB");

    // Read the JSON file
    const filePath = path.join(
      __dirname,
      "../areeb-akbar-maintenance-services.json",
    );
    const jsonData = fs.readFileSync(filePath, "utf-8");
    const services = JSON.parse(jsonData);

    console.log(`📦 Found ${services.length} maintenance services to import`);

    // Insert services
    const result = await Service.insertMany(services);
    console.log(
      `✅ Successfully imported ${result.length} maintenance services`,
    );

    // Verify the import
    const count = await Service.countDocuments({ serviceType: "Maintenance" });
    console.log(`📊 Total Maintenance services in DB: ${count}`);

    await mongoose.connection.close();
    console.log("✅ Done!");
  } catch (error) {
    console.error("❌ Error importing services:", error);
    process.exit(1);
  }
}

importServices();

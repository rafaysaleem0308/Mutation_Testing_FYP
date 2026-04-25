const mongoose = require("mongoose");
const Service = require("./models/service.model");

mongoose
  .connect("mongodb://localhost:27017/IndieLife")
  .then(async () => {
    // Mark all maintenance services as featured
    const result = await Service.updateMany(
      { serviceType: "Maintenance" },
      { $set: { featured: true, rating: 4.5 } },
    );

    console.log("✅ Updated", result.modifiedCount, "maintenance services");
    console.log("   - marked as featured: true");
    console.log("   - set rating to 4.5");

    process.exit(0);
  })
  .catch((err) => {
    console.error("❌ Error:", err.message);
    process.exit(1);
  });

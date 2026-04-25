const mongoose = require("mongoose");
const Service = require("./models/service.model");

mongoose
  .connect("mongodb://localhost:27017/IndieLife")
  .then(async () => {
    // Check featured maintenance services
    const featured = await Service.countDocuments({
      serviceType: "Maintenance",
      status: "Active",
      featured: true,
    });
    console.log("✅ Featured Maintenance services:", featured);

    // Check featured services across all types
    const allFeatured = await Service.countDocuments({
      status: "Active",
      featured: true,
    });
    console.log("✅ Total Featured services:", allFeatured);

    // Check top-rated maintenance services (rating >= 3.5)
    const topRated = await Service.countDocuments({
      serviceType: "Maintenance",
      status: "Active",
      rating: { $gte: 3.5 },
    });
    console.log("✅ Top-rated Maintenance services (rating >= 3.5):", topRated);

    // Check maintenance services with rating > 0
    const withRating = await Service.countDocuments({
      serviceType: "Maintenance",
      status: "Active",
      rating: { $gt: 0 },
    });
    console.log("✅ Maintenance services with rating > 0:", withRating);

    process.exit(0);
  })
  .catch((err) => {
    console.error("❌ Error:", err.message);
    process.exit(1);
  });

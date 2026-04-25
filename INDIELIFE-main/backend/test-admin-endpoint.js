const axios = require("axios");

(async () => {
  try {
    // First login as admin
    const loginRes = await axios.post("http://localhost:3000/api/admin/login", {
      email: "admin@indielife.com",
      password: "Admin@123",
    });

    const token = loginRes.data.accessToken;
    console.log("✓ Admin logged in successfully\n");

    // Now call the services endpoint
    const servicesRes = await axios.get(
      "http://localhost:3000/api/admin/services",
      {
        headers: { Authorization: `Bearer ${token}` },
      },
    );

    console.log("✓ Admin services endpoint response:");
    const services = servicesRes.data.services;
    console.log(`  Total services: ${services.length}\n`);

    // Show housing services
    const housingServices = services.filter(
      (s) => s.serviceType === "Hostel/Flat Accommodation",
    );
    console.log(`Housing Services (${housingServices.length}):`);
    housingServices.slice(0, 3).forEach((s, i) => {
      console.log(`\n  Service ${i + 1}: ${s.serviceName}`);
      console.log(`    providerName: "${s.providerName}"`);
      console.log(`    providerCity: "${s.providerCity}"`);
      console.log(`    serviceType: "${s.serviceType}"`);
    });

    process.exit(0);
  } catch (err) {
    console.error("❌ Error:", err.response?.data?.message || err.message);
    process.exit(1);
  }
})();

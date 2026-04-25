const axios = require("axios");

(async () => {
  try {
    // First login as admin
    const loginRes = await axios.post("http://localhost:3000/api/admin/login", {
      email: "admin@indielife.com",
      password: "Admin@123",
    });

    const token = loginRes.data.accessToken;
    console.log("✓ Admin logged in\n");

    // Get housing services to find one
    const servicesRes = await axios.get(
      "http://localhost:3000/api/admin/services",
      {
        headers: { Authorization: `Bearer ${token}` },
      },
    );

    const housingServices = servicesRes.data.services.filter(
      (s) => s.serviceType === "Hostel/Flat Accommodation",
    );

    if (housingServices.length > 0) {
      const serviceId = housingServices[0]._id;
      console.log(`✓ Found housing service: ${housingServices[0].serviceName}`);
      console.log(`  ID: ${serviceId}\n`);

      // Now test the GET single service endpoint
      const detailRes = await axios.get(
        `http://localhost:3000/api/admin/services/${serviceId}`,
        { headers: { Authorization: `Bearer ${token}` } },
      );

      console.log("✓ Successfully fetched service details:");
      const service = detailRes.data.service;
      console.log(`  Name: ${service.serviceName}`);
      console.log(`  Provider: ${service.providerName}`);
      console.log(`  Price: Rs ${service.price}/${service.unit}`);
      console.log(`  Type: ${service.accommodationType}`);
      console.log(`  City: ${service.providerCity}`);
    } else {
      console.log("❌ No housing services found");
    }

    process.exit(0);
  } catch (err) {
    console.error("❌ Error:", err.response?.data?.message || err.message);
    process.exit(1);
  }
})();

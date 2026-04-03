const mongoose = require("mongoose");
require("dotenv").config();
const HousingProperty = require("./models/housing-property.model");
const Service = require("./models/service.model");

async function check() {
    try {
        await mongoose.connect(process.env.MONGO_URI || "mongodb://127.0.0.1:27017/IndieLife");
        console.log("Connected to MongoDB");

        const housingProps = await HousingProperty.find();
        console.log(`\n--- HousingProperty Collection (${housingProps.length} items) ---`);
        housingProps.forEach(p => {
            console.log(`Title: ${p.title} | Type: ${p.propertyType} | Status: ${p.status} | ID: ${p._id}`);
        });

        const hostelServices = await Service.find({ serviceType: /Hostel/i });
        console.log(`\n--- Services Collection (serviceType: Hostel) (${hostelServices.length} items) ---`);
        hostelServices.forEach(s => {
            console.log(`Name: ${s.serviceName || s.title} | Type: ${s.serviceType} | ID: ${s._id}`);
        });

        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

check();

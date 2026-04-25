const mongoose = require("mongoose");

const MONGO_URI = process.env.MONGO_URI || "mongodb://127.0.0.1:27017/IndieLife";

const connectDatabase = async () => {
    try {
        await mongoose.connect(MONGO_URI);
        console.log("MongoDB connected");
        mongoose.set("strictPopulate", false);
    } catch (err) {
        console.error("MongoDB connection error:", err.message);
        process.exit(1);
    }
};

module.exports = { connectDatabase, MONGO_URI };

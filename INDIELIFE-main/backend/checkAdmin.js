require('dotenv').config();
const { connectDatabase } = require('./config/database');
const User = require('./models/user.model');
const bcrypt = require('bcrypt');

async function ensureAdmin() {
    await connectDatabase();
    const adminEmail = "admin@indielife.com";
    let admin = await User.findOne({ email: adminEmail, role: "admin" });

    if (!admin) {
        console.log("No admin found. Creating one...");
        const hashedPassword = await bcrypt.hash("password123", 10);
        admin = await User.create({
            firstName: "Super",
            lastName: "Admin",
            email: adminEmail,
            password: hashedPassword,
            role: "admin",
            isVerified: true
        });
        console.log("Admin created: ", adminEmail, "password: password123");
    } else {
        console.log("Admin exists: ", adminEmail);
    }
    process.exit();
}

ensureAdmin();

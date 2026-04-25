const mongoose = require("mongoose");

const settingsSchema = new mongoose.Schema(
    {
        platformName: {
            type: String,
            default: "IndieLife",
        },
        commissionPercentage: {
            type: Number,
            default: 10,
        },
        supportEmail: {
            type: String,
            default: "support@indielife.com",
        },
        supportPhone: {
            type: String,
            default: "+92 300 0000000",
        },
        appVersion: {
            type: String,
            default: "1.0.0",
        },
        isMaintenanceMode: {
            type: Boolean,
            default: false,
        },
    },
    {
        timestamps: true,
    }
);

const Settings = mongoose.model("Settings", settingsSchema);

module.exports = Settings;

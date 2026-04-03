const mongoose = require("mongoose");

const housingFavoriteSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true,
        },
        propertyId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "HousingProperty",
            required: true,
            index: true,
        },
    },
    {
        collection: "housing_favorites",
        timestamps: true,
    }
);

// Compound unique index: a user can favorite a property only once
housingFavoriteSchema.index({ userId: 1, propertyId: 1 }, { unique: true });

const HousingFavorite = mongoose.model("HousingFavorite", housingFavoriteSchema);

module.exports = HousingFavorite;

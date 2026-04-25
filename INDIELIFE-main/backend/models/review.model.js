const mongoose = require("mongoose");

const reviewSchema = new mongoose.Schema(
    {
        orderId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Order",
            required: true,
            unique: true // One review per order
        },
        customerId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },
        serviceProviderId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "ServiceProvider",
            required: true
        },
        serviceId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Service",
            required: true
        },
        rating: {
            type: Number,
            required: true,
            min: 1,
            max: 5
        },
        comment: {
            type: String,
            trim: true
        },
        customerName: String,
        customerImage: String,
    },
    { timestamps: true }
);

// Indexes
reviewSchema.index({ serviceProviderId: 1 });
reviewSchema.index({ serviceId: 1 });

const Review = mongoose.model("Review", reviewSchema);
module.exports = Review;

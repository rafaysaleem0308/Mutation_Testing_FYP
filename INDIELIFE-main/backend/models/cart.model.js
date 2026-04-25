const mongoose = require("mongoose");

const cartItemSchema = new mongoose.Schema({
    serviceId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Service",
        required: true,
    },
    name: {
        type: String,
        required: true,
    },
    price: {
        type: Number,
        required: true,
        min: 0,
    },
    quantity: {
        type: Number,
        required: true,
        min: 1,
        default: 1,
    },
    image: {
        type: String,
    },
    instructions: {
        type: String,
        default: "",
    },
    // For laundry or other specific options
    selectedOptions: {
        type: Map,
        of: String,
        default: {},
    },
});

const cartSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            unique: true, // One cart per user
        },
        // The provider whose items are in the cart.
        // We enforce a single provider per cart.
        providerId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User", // or ServiceProvider, usually User ID of provider
            required: true,
        },
        providerName: {
            type: String,
        },
        // The type of service (e.g., 'Meal Provider', 'Laundry').
        // We enforce a single service type per cart.
        serviceType: {
            type: String,
            required: true,
            enum: ["Meal Provider", "Laundry"],
        },
        items: [cartItemSchema],
        subtotal: {
            type: Number,
            default: 0,
        },
        deliveryFee: {
            type: Number,
            default: 0,
        },
        platformFee: {
            type: Number,
            default: 0,
        },
        totalAmount: {
            type: Number,
            default: 0,
        },
    },
    {
        timestamps: true,
    }
);

// Calculate totals before saving
cartSchema.pre("save", function () {
    if (this.items) {
        this.subtotal = this.items.reduce(
            (sum, item) => sum + item.price * item.quantity,
            0
        );

        // Simple logic for fees, can be enhanced
        // this.deliveryFee = ... (calculated elsewhere or fixed)
        // this.platformFee = ...

        this.totalAmount = this.subtotal + (this.deliveryFee || 0) + (this.platformFee || 0);
    }
});

const Cart = mongoose.model("Cart", cartSchema);

module.exports = Cart;

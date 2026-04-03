const mongoose = require("mongoose");

const orderSchema = new mongoose.Schema(
  {
    orderNumber: {
      type: String,
      required: true,
      unique: true,
      index: true,
    },

    // Customer Information - Reference to User
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    firstName: {
      type: String,
      required: true,
    },
    lastName: {
      type: String,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    email: {
      type: String,
      required: true,
    },
    phone: {
      type: String,
      required: true,
    },
    address: {
      type: String,
    },
    city: {
      type: String,
    },

    // Service Provider Information - Reference to User (service_provider role)
    serviceProviderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    // Also store ServiceProvider ID separately for easy access
    serviceProviderSpId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "ServiceProvider",
      index: true,
    },
    providerFirstName: {
      type: String,
    },
    providerLastName: {
      type: String,
    },
    providerName: {
      type: String,
    },
    providerEmail: {
      type: String,
    },
    providerPhone: {
      type: String,
    },
    providerCity: {
      type: String,
    },
    providerServiceName: {
      type: String,
    },

    // Order Items
    items: [
      {
        serviceId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "Service",
          required: true,
        },
        serviceName: {
          type: String,
          required: true,
        },
        serviceType: {
          type: String,
        },
        quantity: {
          type: Number,
          default: 1,
          min: 1,
        },
        unitPrice: {
          type: Number,
          default: 0, // Allow 0 for hire requests
          min: 0,
        },
        totalPrice: {
          type: Number,
          default: 0, // Allow 0 for hire requests
          min: 0,
        },
        specialInstructions: {
          type: String,
        },
        mealDetails: {
          cuisineType: String,
          isVegetarian: Boolean,
          preparationTime: String,
          imageUrl: String,
        },
      },
    ],

    // Order Summary
    subtotal: {
      type: Number,
      required: true,
      default: 0,
      min: 0,
    },
    deliveryFee: {
      type: Number,
      default: 0,
      min: 0,
    },
    tax: {
      type: Number,
      default: 0,
      min: 0,
    },
    discount: {
      type: Number,
      default: 0,
      min: 0,
    },
    totalAmount: {
      type: Number,
      required: true,
      default: 0,
      min: 0,
    },
    platformCommission: {
      type: Number,
      default: 0,
      min: 0,
    },
    providerEarnings: {
      type: Number,
      default: 0,
      min: 0,
    },

    // Delivery Information
    deliveryAddress: {
      type: String,
      required: true,
    },
    deliveryInstructions: {
      type: String,
    },
    deliveryTime: {
      type: String,
    },
    estimatedDeliveryTime: {
      type: String,
      default: "30-45 minutes",
    },
    actualDeliveryTime: {
      type: Date,
    },
    deliveryCoordinates: {
      lat: Number,
      lng: Number,
    },
    // Laundry Specific
    pickupDate: {
      type: Date,
    },
    pickupTime: {
      type: String,
    },
    deliveryDate: {
      type: Date,
    },
    // Overrides deliveryTime string if specific date needed
    // Provider Service Name (for reference)
    providerServiceName: {
      type: String,
    },

    // Payment Information
    paymentMethod: {
      type: String,
      required: true,
      enum: [
        "Cash on Delivery",
        "Credit Card",
        "Mobile Payment",
        "Bank Transfer",
      ],
      default: "Cash on Delivery",
    },
    paymentStatus: {
      type: String,
      enum: [
        "Pending",
        "Completed",
        "Failed",
        "Refunded",
        "Partially Refunded",
      ],
      default: "Pending",
    },
    paymentId: {
      type: String,
    },
    paymentDate: {
      type: Date,
    },

    // Order Status
    status: {
      type: String,
      enum: [
        "Pending",
        "Confirmed",
        "Picked Up",
        "Preparing",
        "Ready for Delivery",
        "Out for Delivery",
        "Delivered",
        "Cancelled",
        "Rejected",
        "On Hold",
        // Maintenance Specific
        "Scheduled",
        "On the Way",
        "In Progress",
        "Completed"
      ],
      default: "Pending",
      index: true,
    },
    statusHistory: [
      {
        status: String,
        timestamp: {
          type: Date,
          default: Date.now,
        },
        notes: String,
        changedBy: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "User",
        },
      },
    ],

    // Additional Information
    specialInstructions: {
      type: String,
    },
    notes: {
      type: String,
    },
    cancellationReason: {
      type: String,
    },
    cancelledBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
    cancellationDate: {
      type: Date,
    },

    // Rating and Review
    rating: {
      type: Number,
      min: 1,
      max: 5,
    },
    review: {
      type: String,
    },
    reviewDate: {
      type: Date,
    },

    // Messages/Chat
    messages: [
      {
        senderId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "User",
          required: true,
        },
        senderName: String,
        senderRole: String,
        message: {
          type: String,
          required: true,
        },
        timestamp: {
          type: Date,
          default: Date.now,
        },
        isRead: {
          type: Boolean,
          default: false,
        },
        readBy: [
          {
            userId: mongoose.Schema.Types.ObjectId,
            timestamp: Date,
          },
        ],
      },
    ],

    // Order metadata
    orderType: {
      type: String,
      enum: ["standard", "hire_request"],
      default: "standard",
    },
    orderSource: {
      type: String,
      enum: ["web", "mobile", "admin"],
      default: "mobile",
    },
    ipAddress: String,
    userAgent: String,

    // Flags
    isUrgent: {
      type: Boolean,
      default: false,
    },
    isScheduled: {
      type: Boolean,
      default: false,
    },
    scheduledDate: Date,
    scheduledTime: String,

    // Maintenance Specific
    images: [{ type: String }], // Photos of the issue

    // Audit trail
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
    updatedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
    },
  },
  {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true },
  },
);

// Virtual for customer full name
orderSchema.virtual("customerFullName").get(function () {
  return `${this.firstName} ${this.lastName}`;
});

// Virtual for provider full name
orderSchema.virtual("providerFullName").get(function () {
  return `${this.providerFirstName} ${this.providerLastName}`;
});

// Indexes for better query performance
orderSchema.index({ createdAt: -1 });
orderSchema.index({ updatedAt: -1 });
orderSchema.index({ status: 1, createdAt: -1 });
orderSchema.index({ customerId: 1, createdAt: -1 });
orderSchema.index({ serviceProviderId: 1, createdAt: -1 });
orderSchema.index({ serviceProviderSpId: 1, createdAt: -1 });
orderSchema.index({ paymentStatus: 1 });
orderSchema.index({ "items.serviceId": 1 });
orderSchema.index({ city: 1 });
orderSchema.index({ totalAmount: 1 });

// Pre-save middleware to generate order number and calculate totals
orderSchema.pre("save", async function () {
  try {
    // Generate order number if not exists
    if (!this.orderNumber) {
      const timestamp = Date.now().toString().slice(-8);
      const random = Math.floor(Math.random() * 1000)
        .toString()
        .padStart(3, "0");
      this.orderNumber = `ORD${timestamp}${random}`;
    }

    // Ensure name fields are set
    if (!this.name && this.firstName && this.lastName) {
      this.name = `${this.firstName} ${this.lastName}`;
    }

    if (!this.providerName && this.providerFirstName && this.providerLastName) {
      this.providerName = `${this.providerFirstName} ${this.providerLastName}`;
    }

    // Calculate totals if modified
    if (
      this.isModified("items") ||
      this.isModified("subtotal") ||
      this.isModified("deliveryFee") ||
      this.isModified("tax") ||
      this.isModified("discount")
    ) {
      // Calculate subtotal from items if not provided
      if (
        this.items &&
        this.items.length > 0 &&
        (!this.subtotal || this.isModified("items"))
      ) {
        this.subtotal = this.items.reduce(
          (sum, item) => sum + (item.totalPrice || 0),
          0,
        );
      }

      // Calculate total amount
      this.totalAmount =
        (this.subtotal || 0) +
        (this.deliveryFee || 0) +
        (this.tax || 0) -
        (this.discount || 0);
    }

    // No need to call next() in async pre-save hooks
  } catch (error) {
    console.error("Error in pre-save hook:", error);
    throw error; // Throw error instead of calling next(error)
  }
});

const Order = mongoose.model("Order", orderSchema);

module.exports = Order;

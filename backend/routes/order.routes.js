const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");
const Order = require("../models/order.model");
const Service = require("../models/service.model");
const ServiceProvider = require("../models/service-provider.model");
const User = require("../models/user.model");
const { verifyToken } = require("../middleware/auth");

// ─── VALIDATION & SANITIZATION ────────────────────────────────────────────
const {
  validateQuantity,
  validatePrice,
  sanitizeString,
} = require("../utils/validators");

// ================================
// POST /api/orders - Create new order
// ================================
router.post("/", verifyToken, async (req, res) => {
  try {
    const {
      serviceProviderId, // Can be SP doc ID or User ID
      items,
      deliveryAddress,
      deliveryInstructions,
      paymentMethod,
      specialInstructions,
      phone,
      totalAmount,
      subtotal,
      deliveryFee,
      tax,
      userId, // Customer user ID
      // Laundry fields
      pickupDate,
      pickupTime,
      deliveryDate,
      deliveryTime,
    } = req.body;

    if (!userId)
      return res
        .status(400)
        .json({ success: false, message: "Customer user ID is required" });

    const currentUser = await User.findById(userId);
    if (!currentUser)
      return res
        .status(404)
        .json({ success: false, message: "Customer not found" });

    // Find Service Provider
    let serviceProvider = await ServiceProvider.findOne({
      $or: [
        {
          _id: mongoose.isValidObjectId(serviceProviderId)
            ? serviceProviderId
            : null,
        },
        {
          userId: mongoose.isValidObjectId(serviceProviderId)
            ? serviceProviderId
            : null,
        },
      ],
    });

    if (!serviceProvider)
      return res
        .status(404)
        .json({ success: false, message: "Service provider not found" });

    // Validate Items
    const serviceIds = items.map((item) => item.serviceId);
    const services = await Service.find({ _id: { $in: serviceIds } });
    const servicesMap = new Map(services.map((s) => [s._id.toString(), s]));

    const orderItems = [];
    let serverCalculatedTotal = 0;

    for (const item of items) {
      const service = servicesMap.get(item.serviceId);
      if (!service)
        return res
          .status(404)
          .json({
            success: false,
            message: `Service ${item.serviceId} not found`,
          });

      // ─── VALIDATE QUANTITY ────────────────────────────────────────────────
      if (!validateQuantity(item.quantity)) {
        return res.status(400).json({
          success: false,
          message: `Quantity must be between 1 and 1000. Received: ${item.quantity}`,
        });
      }

      // Recalculate price from DB (never trust client)
      const lineTotal = service.price * item.quantity;
      serverCalculatedTotal += lineTotal;

      orderItems.push({
        serviceId: service._id,
        serviceName: service.serviceName || "Service",
        serviceType: service.serviceType,
        quantity: item.quantity,
        unitPrice: service.price,
        totalPrice: lineTotal,
        specialInstructions: item.specialInstructions
          ? sanitizeString(item.specialInstructions)
          : "",
        mealDetails: {
          cuisineType: service.cuisineType,
          isVegetarian: service.isVegetarian,
          preparationTime: service.preparationTime,
        },
      });
    }

    // ─── VALIDATE TOTAL AMOUNT ────────────────────────────────────────────
    if (!validatePrice(totalAmount, 100, 500000)) {
      return res.status(400).json({
        success: false,
        message: "Total amount must be between 100 and 500,000 PKR",
      });
    }

    // Verify server-calculated total matches client total (allow small variance for tax)
    if (Math.abs(serverCalculatedTotal - (subtotal || 0)) > 100) {
      return res.status(400).json({
        success: false,
        message: "Order total mismatch - possible tampering detected",
      });
    }

    const orderNumber = "ORD" + Date.now() + Math.floor(Math.random() * 1000);

    const order = new Order({
      orderNumber,
      customerId: currentUser._id,
      firstName: currentUser.firstName || "Customer",
      lastName: currentUser.lastName || "User",
      name: `${currentUser.firstName || "Customer"} ${currentUser.lastName || "User"}`.trim(),
      email: currentUser.email,
      phone: phone || currentUser.phone || "N/A",
      address: deliveryAddress || currentUser.address,
      city: currentUser.city || "",
      serviceProviderId: serviceProvider.userId || serviceProvider._id, // User ID for ref
      serviceProviderSpId: serviceProvider._id,
      providerFirstName: serviceProvider.firstName,
      providerLastName: serviceProvider.lastName,
      providerName:
        serviceProvider.serviceName ||
        `${serviceProvider.firstName} ${serviceProvider.lastName}`,
      providerEmail: serviceProvider.email,
      providerPhone: serviceProvider.phone,
      providerCity: serviceProvider.city || "",
      providerServiceName: serviceProvider.serviceName || "",
      items: orderItems,
      subtotal: subtotal || 0,
      deliveryFee: deliveryFee || 0,
      tax: tax || 0,
      totalAmount: totalAmount || 0,
      deliveryAddress: sanitizeString(deliveryAddress || ""),
      deliveryInstructions: deliveryInstructions
        ? sanitizeString(deliveryInstructions)
        : "",
      pickupDate,
      pickupTime,
      deliveryDate,
      deliveryTime,
      paymentMethod: paymentMethod || "Cash on Delivery",
      paymentStatus: "Pending",
      status: "Pending",
      statusHistory: [
        { status: "Pending", timestamp: new Date(), notes: "Order created" },
      ],
    });

    await order.save();

    // Emit socket
    const io = req.app.get("io");
    if (io) {
      const providerRoomId = (
        serviceProvider.userId || serviceProvider._id
      ).toString();
      io.to(providerRoomId).emit("new_order", order);
    }

    res
      .status(201)
      .json({ success: true, message: "Order placed successfully", order });
  } catch (error) {
    console.error("Create order error:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error: " + error.message });
  }
});

// ================================
// POST /api/orders/hire - Create hire request
// ================================
router.post("/hire", verifyToken, async (req, res) => {
  try {
    const {
      serviceProviderId,
      phone,
      deliveryAddress,
      description,
      date,
      time,
      userId,
      images,
    } = req.body;

    if (!userId || !serviceProviderId)
      return res
        .status(400)
        .json({ success: false, message: "User ID and Provider ID required" });

    const currentUser = await User.findById(userId);
    if (!currentUser)
      return res
        .status(404)
        .json({ success: false, message: "Customer not found" });

    const serviceProvider = await ServiceProvider.findOne({
      $or: [
        {
          _id: mongoose.isValidObjectId(serviceProviderId)
            ? serviceProviderId
            : null,
        },
        {
          userId: mongoose.isValidObjectId(serviceProviderId)
            ? serviceProviderId
            : null,
        },
      ],
    });
    if (!serviceProvider)
      return res
        .status(404)
        .json({ success: false, message: "Provider not found" });

    const orderNumber = "HIRE" + Date.now() + Math.floor(Math.random() * 1000);

    const order = new Order({
      orderNumber,
      orderType: "hire_request",
      customerId: currentUser._id,
      firstName: currentUser.firstName || "Customer",
      lastName: currentUser.lastName || "User",
      name: `${currentUser.firstName || "Customer"} ${currentUser.lastName || "User"}`.trim(),
      email: currentUser.email,
      phone: phone || currentUser.phone,
      address: deliveryAddress || currentUser.address,
      city: currentUser.city || "",
      serviceProviderId: serviceProvider.userId || serviceProvider._id,
      serviceProviderSpId: serviceProvider._id,
      providerName:
        serviceProvider.serviceName ||
        `${serviceProvider.firstName} ${serviceProvider.lastName}`,
      providerFirstName: serviceProvider.firstName,
      providerLastName: serviceProvider.lastName,
      providerEmail: serviceProvider.email,
      providerPhone: serviceProvider.phone,
      providerCity: serviceProvider.city,
      providerServiceName: serviceProvider.serviceName || "Maintenance Service",
      items: [
        {
          serviceId: new mongoose.Types.ObjectId(),
          serviceName: "Maintenance Hire Request",
          serviceType: serviceProvider.spSubRole || "Maintenance",
          quantity: 1,
          unitPrice: 0,
          totalPrice: 0,
          specialInstructions: description + ` (Requested: ${date} at ${time})`,
        },
      ],
      subtotal: 0,
      deliveryFee: 0,
      tax: 0,
      totalAmount: 0,
      paymentMethod: "Cash on Delivery",
      paymentStatus: "Pending",
      deliveryAddress: deliveryAddress || currentUser.address,
      deliveryInstructions: `Requested Date: ${date}, Time: ${time}`,
      specialInstructions: description,
      status: "Pending",
      images: images || [],
      scheduledDate: new Date(date),
      scheduledTime: time,
      statusHistory: [
        {
          status: "Pending",
          timestamp: new Date(),
          notes: `Hire request created: ${description}`,
        },
      ],
    });

    await order.save();

    const io = req.app.get("io");
    if (io) {
      const providerRoomId = (
        serviceProvider.userId || serviceProvider._id
      ).toString();
      io.to(providerRoomId).emit("new_order", order);
    }

    res
      .status(201)
      .json({
        success: true,
        message: "Hire request sent successfully",
        order,
      });
  } catch (error) {
    console.error("Create hire error:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error: " + error.message });
  }
});

// ================================
// GET /api/orders/provider - Get provider orders
// ================================
router.get("/provider", verifyToken, async (req, res) => {
  try {
    const { status, limit = 20, page = 1 } = req.query;
    const skip = (page - 1) * limit;

    const spId = req.user.spId || req.user.userId;
    const providerDoc = await ServiceProvider.findOne({
      $or: [
        { _id: mongoose.isValidObjectId(spId) ? spId : null },
        { userId: mongoose.isValidObjectId(spId) ? spId : null },
      ],
    });

    let providerIds = [spId];
    if (providerDoc) {
      providerIds.push(providerDoc._id.toString());
      if (providerDoc.userId) providerIds.push(providerDoc.userId.toString());
    }
    // Deduplicate
    providerIds = [...new Set(providerIds)];

    // Convert to both ObjectId and string for matching (MongoDB may store as either)
    const providerObjectIds = providerIds
      .filter((id) => mongoose.isValidObjectId(id))
      .map((id) => new mongoose.Types.ObjectId(id));
    const allProviderMatches = [...providerObjectIds, ...providerIds];

    let query = {
      $or: [
        { serviceProviderId: { $in: allProviderMatches } },
        { serviceProviderSpId: { $in: allProviderMatches } },
      ],
    };

    if (status && status !== "all" && status !== "All") {
      query.status = status;
    }

    const orders = await Order.find(query)
      .populate("customerId", "firstName lastName email phone city")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    const total = await Order.countDocuments(query);

    res.status(200).json({
      success: true,
      orders: orders.map((o) => ({
        ...o,
        customerName:
          o.name ||
          (o.customerId
            ? `${o.customerId.firstName} ${o.customerId.lastName}`
            : "Customer"),
      })),
      total,
      page: parseInt(page),
      totalPages: Math.ceil(total / limit),
    });
  } catch (error) {
    console.error("Get provider orders error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ================================
// GET /api/orders/customer - Get customer orders
// ================================
router.get("/customer", verifyToken, async (req, res) => {
  try {
    const { status, limit = 20, page = 1 } = req.query;
    const skip = (page - 1) * limit;
    let query = { customerId: req.user.userId };
    if (status && status !== "all" && status !== "All") query.status = status;

    const orders = await Order.find(query)
      .populate("serviceProviderId", "firstName lastName email phone city")
      .populate(
        "serviceProviderSpId",
        "firstName lastName email phone city serviceName",
      )
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    const total = await Order.countDocuments(query);
    res
      .status(200)
      .json({
        success: true,
        orders,
        total,
        page: parseInt(page),
        totalPages: Math.ceil(total / limit),
      });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ================================
// GET /api/orders/stats/provider - Stats
// ================================
router.get("/stats/provider", verifyToken, async (req, res) => {
  try {
    const spId = req.user.spId || req.user.userId;
    const providerDoc = await ServiceProvider.findOne({
      $or: [
        { _id: mongoose.isValidObjectId(spId) ? spId : null },
        { userId: mongoose.isValidObjectId(spId) ? spId : null },
      ],
    });

    let pid = providerDoc ? providerDoc.userId || providerDoc._id : spId;
    const providerObjectId = new mongoose.Types.ObjectId(pid.toString());
    const spDocObjectId = providerDoc ? providerDoc._id : providerObjectId;

    // Match both serviceProviderId and serviceProviderSpId for consistency
    const providerMatchCondition = {
      $or: [
        { serviceProviderId: providerObjectId },
        { serviceProviderId: spDocObjectId },
        { serviceProviderSpId: providerObjectId },
        { serviceProviderSpId: spDocObjectId },
      ],
    };

    const stats = await Order.aggregate([
      { $match: providerMatchCondition },
      {
        $group: {
          _id: null,
          totalOrders: { $sum: 1 },
          deliveredOrders: {
            $sum: { $cond: [{ $eq: ["$status", "Delivered"] }, 1, 0] },
          },
          pendingOrders: {
            $sum: { $cond: [{ $eq: ["$status", "Pending"] }, 1, 0] },
          },
          activeOrders: {
            $sum: {
              $cond: [
                {
                  $in: [
                    "$status",
                    [
                      "Confirmed",
                      "Preparing",
                      "Ready for Delivery",
                      "Out for Delivery",
                      "Scheduled",
                      "On the Way",
                      "In Progress",
                    ],
                  ],
                },
                1,
                0,
              ],
            },
          },
          cancelledOrders: {
            $sum: {
              $cond: [{ $in: ["$status", ["Cancelled", "Rejected"]] }, 1, 0],
            },
          },
          totalEarnings: {
            $sum: {
              $cond: [{ $eq: ["$status", "Delivered"] }, "$totalAmount", 0],
            },
          },
        },
      },
    ]);

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayStats = await Order.aggregate([
      { $match: { ...providerMatchCondition, createdAt: { $gte: today } } },
      {
        $group: {
          _id: null,
          todayOrders: { $sum: 1 },
          todayEarnings: {
            $sum: {
              $cond: [{ $eq: ["$status", "Delivered"] }, "$totalAmount", 0],
            },
          },
        },
      },
    ]);

    const result = stats[0] || {
      totalOrders: 0,
      deliveredOrders: 0,
      pendingOrders: 0,
      activeOrders: 0,
      cancelledOrders: 0,
      totalEarnings: 0,
    };
    const todayResult = todayStats[0] || { todayOrders: 0, todayEarnings: 0 };

    res.status(200).json({
      success: true,
      stats: {
        ...result,
        ...todayResult,
        completionRate:
          result.totalOrders > 0
            ? result.deliveredOrders / result.totalOrders
            : 0,
        averageRating: providerDoc?.rating || 0,
      },
    });
  } catch (error) {
    console.error("Stats error:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

// ================================
// PUT /api/orders/:id/status - Update Status
// ================================
router.put("/:id/status", verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;
    const order = await Order.findById(id);
    if (!order)
      return res
        .status(404)
        .json({ success: false, message: "Order not found" });

    const prev = order.status;
    order.status = status;
    order.statusHistory.push({
      status,
      notes: notes || `Changed from ${prev} to ${status}`,
      timestamp: new Date(),
    });

    if (status === "Delivered") {
      order.actualDeliveryTime = new Date();
      order.paymentStatus = "Completed";
    }

    await order.save();

    // Sockets
    const io = req.app.get("io");
    if (io) {
      io.to(order.customerId.toString()).emit("order_update", {
        orderId: order._id,
        status,
        message: `Order #${order.orderNumber} is ${status}`,
      });
      io.to(order.serviceProviderId.toString()).emit("order_update", {
        orderId: order._id,
        status,
      });
    }

    res
      .status(200)
      .json({ success: true, message: `Status: ${status}`, order });
  } catch (error) {
    console.error("Status Update Error:", error);
    res
      .status(500)
      .json({ success: false, message: error.message || "Server error" });
  }
});

// ================================
// GET /api/orders/:id - Details
// ================================
router.get("/:id", verifyToken, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate("customerId", "firstName lastName email phone city address")
      .populate(
        "serviceProviderId",
        "firstName lastName email phone city address",
      )
      .populate("items.serviceId");

    if (!order)
      return res
        .status(404)
        .json({ success: false, message: "Order not found" });
    res.status(200).json({ success: true, order });
  } catch (error) {
    res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;

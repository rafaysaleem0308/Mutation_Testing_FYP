const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");
const { verifyToken } = require("../middleware/auth");
const HousingProperty = require("../models/housing-property.model");
const HousingBooking = require("../models/housing-booking.model");
const HousingVisit = require("../models/housing-visit.model");
const HousingFavorite = require("../models/housing-favorite.model");
const ServiceProvider = require("../models/service-provider.model");
const User = require("../models/user.model");
const Notification = require("../models/notification.model");
const Service = require("../models/service.model");

// ─── VALIDATION & SANITIZATION ────────────────────────────────────────────
const {
  validateFutureDate,
  validatePrice,
  sanitizeString,
} = require("../utils/validators");

// ════════════════════════════════════════════════════════════════════════════════
// 1. SPECIFIC NAMED ROUTES (Must come before /:id)
// ════════════════════════════════════════════════════════════════════════════════

// ─── Owner Routes ─────────────────────────────────────────────────────────────

// GET /api/housing/owner/my-properties
router.get("/owner/my-properties", verifyToken, async (req, res) => {
  try {
    const spId = req.user.spId || req.user.userId;
    const properties = await HousingProperty.find({ ownerId: spId })
      .sort({ createdAt: -1 })
      .lean();
    res.json({ success: true, properties, total: properties.length });
  } catch (error) {
    console.error("My properties error:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// GET /api/housing/owner/stats
router.get("/owner/stats", verifyToken, async (req, res) => {
  try {
    const spId = req.user.spId || req.user.userId;

    const [
      totalProperties,
      approvedProperties,
      pendingProperties,
      totalBookings,
      pendingBookings,
      activeBookings,
      totalVisits,
      pendingVisits,
    ] = await Promise.all([
      HousingProperty.countDocuments({ ownerId: spId }),
      HousingProperty.countDocuments({ ownerId: spId, status: "approved" }),
      HousingProperty.countDocuments({
        ownerId: spId,
        status: "pending_approval",
      }),
      HousingBooking.countDocuments({ ownerId: spId }),
      HousingBooking.countDocuments({ ownerId: spId, status: "Pending" }),
      HousingBooking.countDocuments({
        ownerId: spId,
        status: { $in: ["Accepted", "Confirmed"] },
      }),
      HousingVisit.countDocuments({ ownerId: spId }),
      HousingVisit.countDocuments({ ownerId: spId, status: "Pending" }),
    ]);

    // Calculate total earnings
    let totalEarnings = 0;
    try {
      const earningsAgg = await HousingBooking.aggregate([
        {
          $match: {
            ownerId: new mongoose.Types.ObjectId(spId),
            paymentStatus: "Completed",
          },
        },
        { $group: { _id: null, total: { $sum: "$ownerEarnings" } } },
      ]);
      totalEarnings = earningsAgg[0]?.total || 0;
    } catch (e) {
      /* ignore aggregation errors */
    }

    res.json({
      success: true,
      stats: {
        totalProperties,
        approvedProperties,
        pendingProperties,
        totalBookings,
        pendingBookings,
        activeBookings,
        totalVisits,
        pendingVisits,
        totalEarnings,
      },
    });
  } catch (error) {
    console.error("Owner stats error:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// ─── Booking Routes ───────────────────────────────────────────────────────────

// POST /api/housing/booking
router.post("/booking", verifyToken, async (req, res) => {
  try {
    const userId = req.user.userId || req.user._id;
    const user = await User.findById(userId);
    if (!user)
      return res
        .status(404)
        .json({ success: false, message: "User not found" });

    const { propertyId, moveInDate, duration, paymentMethod, notes } = req.body;
    if (!propertyId || !moveInDate) {
      return res
        .status(400)
        .json({
          success: false,
          message: "Property and move-in date are required",
        });
    }

    // ─── VALIDATE MOVE-IN DATE ────────────────────────────────────────
    if (!validateFutureDate(moveInDate)) {
      return res.status(400).json({
        success: false,
        message: "Move-in date must be in the future",
      });
    }

    // ─── VALIDATE DURATION ────────────────────────────────────────────
    if (!duration) {
      return res.status(400).json({
        success: false,
        message: "Duration is required",
      });
    }

    const durationNum = parseInt(duration);
    if (isNaN(durationNum) || durationNum < 1 || durationNum > 60) {
      return res.status(400).json({
        success: false,
        message: "Duration must be between 1 and 60 months",
      });
    }

    let property = await HousingProperty.findById(propertyId).populate(
      "ownerId",
      "firstName lastName",
    );

    // Handle legacy hostels from the Service collection
    if (!property) {
      const legacyOwner = await User.findById(req.body.ownerId); // We might not know owner immediately, but let's query the service
      const legacy =
        await Service.findById(propertyId).populate("serviceProviderId");
      if (legacy && legacy.serviceType === "Hostel/Flat Accommodation") {
        property = {
          _id: legacy._id,
          title: legacy.serviceName || legacy.title,
          propertyType: "Hostel",
          monthlyRent: legacy.price,
          securityDeposit: 0,
          advanceRent: 0,
          address: legacy.address,
          ownerId: legacy.serviceProviderId,
          status: "approved",
          isAvailable: true,
        };
      }
    }

    if (!property)
      return res
        .status(404)
        .json({ success: false, message: "Property not found" });
    if (property.status !== "approved" || !property.isAvailable) {
      return res
        .status(400)
        .json({ success: false, message: "Property is not available" });
    }

    // ─── VALIDATE RENT PRICE ──────────────────────────────────────────
    if (!validatePrice(property.monthlyRent, 5000, 500000)) {
      return res.status(400).json({
        success: false,
        message: "Invalid property rent amount (must be 5,000-500,000 PKR)",
      });
    }

    const commissionRate = 0.05;
    const totalAmount =
      property.monthlyRent +
      (property.securityDeposit || 0) +
      (property.advanceRent || 0);
    const platformCommission = Math.round(
      property.monthlyRent * commissionRate,
    );
    const ownerEarnings = totalAmount - platformCommission;

    const booking = new HousingBooking({
      propertyId,
      tenantId: userId,
      ownerId: property.ownerId._id || property.ownerId,
      moveInDate: new Date(moveInDate),
      duration: durationNum + " Month" + (durationNum > 1 ? "s" : ""),
      monthlyRent: property.monthlyRent,
      securityDeposit: property.securityDeposit,
      advanceRent: property.advanceRent,
      totalAmount,
      platformCommission,
      ownerEarnings,
      paymentMethod: paymentMethod || "Cash on Delivery",
      tenantName: `${user.firstName} ${user.lastName}`,
      tenantEmail: user.email,
      tenantPhone: user.phone,
      ownerName: property.ownerId.firstName
        ? `${property.ownerId.firstName} ${property.ownerId.lastName}`
        : "Owner",
      propertyTitle: property.title,
      propertyType: property.propertyType,
      propertyAddress: property.address,
      notes: notes ? sanitizeString(notes) : "",
      statusHistory: [
        {
          status: "Pending",
          timestamp: new Date(),
          notes: "Booking request created",
        },
      ],
    });

    await booking.save();
    await HousingProperty.findByIdAndUpdate(propertyId, {
      $inc: { totalBookings: 1 },
    });

    // Notify owner
    const io = req.app.get("io");
    if (io) {
      io.to((property.ownerId._id || property.ownerId).toString()).emit(
        "new_housing_booking",
        {
          bookingId: booking._id,
          propertyTitle: property.title,
          tenantName: booking.tenantName,
        },
      );
    }

    const ownerUser = await User.findOne({
      spId: property.ownerId._id || property.ownerId,
    });
    if (ownerUser) {
      await Notification.create({
        userId: ownerUser._id,
        title: "New Booking Request",
        body: `${booking.tenantName} wants to book "${property.title}"`,
        type: "order_placed",
        referenceId: booking._id.toString(),
        referenceType: "order",
      });
    }

    res
      .status(201)
      .json({ success: true, message: "Booking request sent!", booking });
  } catch (error) {
    console.error("Create booking error:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// GET /api/housing/booking/my-bookings
router.get("/booking/my-bookings", verifyToken, async (req, res) => {
  try {
    const userId = req.user.userId || req.user._id;
    const bookings = await HousingBooking.find({ tenantId: userId })
      .populate(
        "propertyId",
        "title images thumbnailImage city address monthlyRent propertyType",
      )
      .sort({ createdAt: -1 })
      .lean();
    res.json({ success: true, bookings, total: bookings.length });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// GET /api/housing/booking/owner-bookings
router.get("/booking/owner-bookings", verifyToken, async (req, res) => {
  try {
    const spId = req.user.spId || req.user.userId;
    const bookings = await HousingBooking.find({ ownerId: spId })
      .populate(
        "propertyId",
        "title images thumbnailImage city address monthlyRent propertyType",
      )
      .populate("tenantId", "firstName lastName email phone profileImage")
      .sort({ createdAt: -1 })
      .lean();
    res.json({ success: true, bookings, total: bookings.length });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// PATCH /api/housing/booking/:id/status
router.patch("/booking/:id/status", verifyToken, async (req, res) => {
  try {
    const { status, notes } = req.body;
    const validStatuses = [
      "Accepted",
      "Rejected",
      "Confirmed",
      "Completed",
      "Cancelled",
    ];
    if (!validStatuses.includes(status)) {
      return res
        .status(400)
        .json({
          success: false,
          message: `Invalid status. Must be one of: ${validStatuses.join(", ")}`,
        });
    }

    const booking = await HousingBooking.findById(req.params.id);
    if (!booking)
      return res
        .status(404)
        .json({ success: false, message: "Booking not found" });

    booking.status = status;
    booking.statusHistory.push({
      status,
      timestamp: new Date(),
      notes: notes || `Status changed to ${status}`,
    });

    if (status === "Cancelled") {
      booking.cancellationDate = new Date();
      booking.cancellationReason = notes;
    }
    if (status === "Confirmed") {
      booking.paymentStatus = "Completed";
    }

    await booking.save();

    await Notification.create({
      userId: booking.tenantId,
      title: `Booking ${status}`,
      body: `Your booking for "${booking.propertyTitle}" has been ${status.toLowerCase()}.`,
      type:
        status === "Accepted"
          ? "order_accepted"
          : status === "Cancelled"
            ? "order_cancelled"
            : "system",
      referenceId: booking._id.toString(),
      referenceType: "order",
    });

    const io = req.app.get("io");
    if (io) {
      io.to(booking.tenantId.toString()).emit("housing_booking_update", {
        bookingId: booking._id,
        status,
        propertyTitle: booking.propertyTitle,
      });
    }

    res.json({
      success: true,
      message: `Booking ${status.toLowerCase()}`,
      booking,
    });
  } catch (error) {
    console.error("Update booking status error:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// ─── Visit Schedule Routes ────────────────────────────────────────────────────

// POST /api/housing/visit
router.post("/visit", verifyToken, async (req, res) => {
  try {
    const userId = req.user.userId || req.user._id;
    const user = await User.findById(userId);
    if (!user)
      return res
        .status(404)
        .json({ success: false, message: "User not found" });

    const { propertyId, visitDate, visitTime, message } = req.body;
    if (!propertyId || !visitDate || !visitTime) {
      return res
        .status(400)
        .json({
          success: false,
          message: "Property, date, and time are required",
        });
    }

    let property = await HousingProperty.findById(propertyId).populate(
      "ownerId",
      "firstName lastName",
    );

    // Handle legacy hostel fallback
    if (!property) {
      const legacy =
        await Service.findById(propertyId).populate("serviceProviderId");
      if (legacy && legacy.serviceType === "Hostel/Flat Accommodation") {
        property = {
          title: legacy.serviceName || legacy.title,
          address: legacy.address,
          ownerId: legacy.serviceProviderId || {
            firstName: "Owner",
            lastName: "",
          },
        };
      }
    }

    if (!property)
      return res
        .status(404)
        .json({ success: false, message: "Property not found" });

    const visit = new HousingVisit({
      propertyId,
      userId,
      ownerId: property.ownerId._id || property.ownerId,
      visitDate: new Date(visitDate),
      visitTime,
      userMessage: message || "",
      userName: `${user.firstName} ${user.lastName}`,
      userPhone: user.phone,
      ownerName: property.ownerId.firstName
        ? `${property.ownerId.firstName} ${property.ownerId.lastName}`
        : "Owner",
      propertyTitle: property.title,
      propertyAddress: property.address,
    });

    await visit.save();

    const ownerUser = await User.findOne({
      spId: property.ownerId._id || property.ownerId,
    });
    if (ownerUser) {
      await Notification.create({
        userId: ownerUser._id,
        title: "Visit Request",
        body: `${visit.userName} wants to visit "${property.title}" on ${visitDate}`,
        type: "system",
        referenceId: visit._id.toString(),
      });
    }

    const io = req.app.get("io");
    if (io) {
      io.to((property.ownerId._id || property.ownerId).toString()).emit(
        "new_visit_request",
        {
          visitId: visit._id,
          propertyTitle: property.title,
          visitorName: visit.userName,
        },
      );
    }

    res.status(201).json({ success: true, message: "Visit scheduled!", visit });
  } catch (error) {
    console.error("Schedule visit error:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// GET /api/housing/visit/my-visits
router.get("/visit/my-visits", verifyToken, async (req, res) => {
  try {
    const userId = req.user.userId || req.user._id;
    const visits = await HousingVisit.find({ userId })
      .populate("propertyId", "title images thumbnailImage city")
      .sort({ createdAt: -1 })
      .lean();
    res.json({ success: true, visits, total: visits.length });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// GET /api/housing/visit/owner-visits
router.get("/visit/owner-visits", verifyToken, async (req, res) => {
  try {
    const spId = req.user.spId || req.user.userId;
    const visits = await HousingVisit.find({ ownerId: spId })
      .populate("propertyId", "title images thumbnailImage city")
      .populate("userId", "firstName lastName email phone profileImage")
      .sort({ createdAt: -1 })
      .lean();
    res.json({ success: true, visits, total: visits.length });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// PATCH /api/housing/visit/:id/status
router.patch("/visit/:id/status", verifyToken, async (req, res) => {
  try {
    const { status, rescheduledDate, rescheduledTime, notes } = req.body;
    const validStatuses = [
      "Accepted",
      "Rejected",
      "Rescheduled",
      "Completed",
      "Cancelled",
    ];
    if (!validStatuses.includes(status)) {
      return res
        .status(400)
        .json({ success: false, message: "Invalid status" });
    }

    const visit = await HousingVisit.findById(req.params.id);
    if (!visit)
      return res
        .status(404)
        .json({ success: false, message: "Visit not found" });

    visit.status = status;
    if (status === "Rescheduled") {
      visit.rescheduledDate = rescheduledDate
        ? new Date(rescheduledDate)
        : visit.visitDate;
      visit.rescheduledTime = rescheduledTime || visit.visitTime;
    }
    visit.ownerNotes = notes || "";
    await visit.save();

    await Notification.create({
      userId: visit.userId,
      title: `Visit ${status}`,
      body: `Your visit to "${visit.propertyTitle}" has been ${status.toLowerCase()}.`,
      type: "system",
      referenceId: visit._id.toString(),
    });

    res.json({
      success: true,
      message: `Visit ${status.toLowerCase()}`,
      visit,
    });
  } catch (error) {
    console.error("Update visit status error:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// ─── Favorites Routes ─────────────────────────────────────────────────────────

// POST /api/housing/favorite
router.post("/favorite", verifyToken, async (req, res) => {
  try {
    const userId = req.user.userId || req.user._id;
    const { propertyId } = req.body;
    if (!propertyId)
      return res
        .status(400)
        .json({ success: false, message: "Property ID required" });

    const existing = await HousingFavorite.findOne({ userId, propertyId });
    if (existing) {
      await HousingFavorite.deleteOne({ _id: existing._id });
      await HousingProperty.findByIdAndUpdate(propertyId, {
        $inc: { favoritesCount: -1 },
      });
      return res.json({
        success: true,
        isFavorited: false,
        message: "Removed from favorites",
      });
    }

    await HousingFavorite.create({ userId, propertyId });
    await HousingProperty.findByIdAndUpdate(propertyId, {
      $inc: { favoritesCount: 1 },
    });
    res.json({
      success: true,
      isFavorited: true,
      message: "Added to favorites",
    });
  } catch (error) {
    console.error("Toggle favorite error:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// GET /api/housing/favorite/my-favorites
router.get("/favorite/my-favorites", verifyToken, async (req, res) => {
  try {
    const userId = req.user.userId || req.user._id;
    const favorites = await HousingFavorite.find({ userId })
      .populate({
        path: "propertyId",
        populate: {
          path: "ownerId",
          select: "firstName lastName profileImage rating",
        },
      })
      .sort({ createdAt: -1 })
      .lean();

    const properties = favorites
      .filter((f) => f.propertyId)
      .map((f) => ({
        ...f.propertyId,
        isFavorited: true,
        ownerName: f.propertyId.ownerId
          ? `${f.propertyId.ownerId.firstName} ${f.propertyId.ownerId.lastName}`
          : "Owner",
      }));

    res.json({ success: true, properties, total: properties.length });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// GET /api/housing/favorite/check/:propertyId
router.get("/favorite/check/:propertyId", verifyToken, async (req, res) => {
  try {
    const userId = req.user.userId || req.user._id;
    const existing = await HousingFavorite.findOne({
      userId,
      propertyId: req.params.propertyId,
    });
    res.json({ success: true, isFavorited: !!existing });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// ════════════════════════════════════════════════════════════════════════════════
// 2. PUBLIC LISTING ROUTE
// ════════════════════════════════════════════════════════════════════════════════

// GET /api/housing — List approved properties with filters
router.get("/", async (req, res) => {
  try {
    const {
      city,
      area,
      propertyType,
      furnished,
      genderPreference,
      roomType,
      minPrice,
      maxPrice,
      availableFrom,
      search,
      sortBy = "createdAt",
      sortOrder = "desc",
      page = 1,
      limit = 20,
      lat,
      lng,
      radius = 10,
    } = req.query;

    let query = { status: "approved", isAvailable: true };

    if (city) query.city = new RegExp(city, "i");
    if (area) query.area = new RegExp(area, "i");
    if (propertyType) query.propertyType = propertyType;
    if (furnished) query.furnished = furnished;
    if (genderPreference) query.genderPreference = genderPreference;
    if (roomType) query.roomType = roomType;
    if (availableFrom) query.availableFrom = { $lte: new Date(availableFrom) };

    if (minPrice || maxPrice) {
      query.monthlyRent = {};
      if (minPrice) query.monthlyRent.$gte = parseFloat(minPrice);
      if (maxPrice) query.monthlyRent.$lte = parseFloat(maxPrice);
    }

    if (search) {
      query.$or = [
        { title: new RegExp(search, "i") },
        { description: new RegExp(search, "i") },
        { city: new RegExp(search, "i") },
        { area: new RegExp(search, "i") },
        { address: new RegExp(search, "i") },
      ];
    }

    if (lat && lng) {
      query.location = {
        $near: {
          $geometry: {
            type: "Point",
            coordinates: [parseFloat(lng), parseFloat(lat)],
          },
          $maxDistance: parseFloat(radius) * 1000,
        },
      };
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sortOptions = {};
    sortOptions[sortBy] = sortOrder === "asc" ? 1 : -1;

    const [properties, total, legacyHostels] = await Promise.all([
      HousingProperty.find(query)
        .populate(
          "ownerId",
          "firstName lastName profileImage rating phone city",
        )
        .sort(sortOptions)
        .skip(skip)
        .limit(parseInt(limit))
        .lean(),
      HousingProperty.countDocuments(query),
      // Also fetch legacy Hostels from services collection
      propertyType === "Hostel" || !propertyType
        ? Service.find({
            serviceType: "Hostel/Flat Accommodation",
            status: "Active",
          })
            .populate("serviceProviderId")
            .lean()
        : [],
    ]);

    // Transform legacy Hostels to match HousingProperty structure
    const bridgedHostels = legacyHostels.map((h) => ({
      _id: h._id,
      title: h.serviceName || h.title,
      description: h.description,
      propertyType: "Hostel",
      monthlyRent: h.price,
      images: h.imageUrl ? [h.imageUrl] : [],
      address: h.address,
      city: h.serviceProviderCity || "Local",
      bedrooms: h.availableRooms || 1,
      bathrooms: 1,
      furnished: "Semi-Furnished",
      ownerName: h.serviceProviderName || "Provider",
      ownerId: h.serviceProviderId,
      status: "approved",
      isAvailable: true,
      isLegacy: true,
    }));

    const enriched = properties.map((p) => ({
      ...p,
      ownerName: p.ownerId
        ? `${p.ownerId.firstName} ${p.ownerId.lastName}`
        : "Property Owner",
      ownerImage: p.ownerId?.profileImage || null,
      ownerRating: p.ownerId?.rating || 0,
      ownerPhone: p.ownerId?.phone || null,
    }));

    // Combine lists
    const allProperties = [...enriched, ...bridgedHostels];

    res.json({
      success: true,
      providers: allProperties,
      properties: allProperties,
      total: total + bridgedHostels.length,
      page: parseInt(page),
      totalPages: Math.ceil((total + bridgedHostels.length) / parseInt(limit)),
      hasMore: skip + properties.length < total,
    });
  } catch (error) {
    console.error("Housing list error:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// ════════════════════════════════════════════════════════════════════════════════
// 3. CREATE & GENERIC ROUTES
// ════════════════════════════════════════════════════════════════════════════════

// POST /api/housing — Create property (owner only)
router.post("/", verifyToken, async (req, res) => {
  try {
    const spId = req.user.spId || req.user.userId;
    if (!spId) {
      return res
        .status(400)
        .json({
          success: false,
          message: "Service provider ID not found in token",
        });
    }

    const sp = await ServiceProvider.findById(spId);
    if (!sp) {
      return res
        .status(404)
        .json({ success: false, message: "Service provider not found" });
    }

    if (sp.spSubRole !== "Hostel/Flat Accommodation") {
      return res
        .status(403)
        .json({
          success: false,
          message: "Only housing providers can create properties",
        });
    }

    const {
      title,
      description,
      propertyType,
      monthlyRent,
      securityDeposit,
      advanceRent,
      images,
      address,
      city,
      area,
      lat,
      lng,
      facilities,
      bedrooms,
      bathrooms,
      area_sqft,
      floor,
      furnished,
      genderPreference,
      roomType,
      maxOccupants,
      currentOccupants,
      availableFrom,
      houseRules,
    } = req.body;

    if (
      !title ||
      !description ||
      !propertyType ||
      !monthlyRent ||
      !address ||
      !city
    ) {
      return res
        .status(400)
        .json({ success: false, message: "Missing required fields" });
    }

    // ─── VALIDATION & SANITIZATION ────────────────────────────────────────
    // Validate title length
    if (title.length < 5 || title.length > 200) {
      return res.status(400).json({
        success: false,
        message: "Property title must be 5-200 characters",
      });
    }

    // Validate description length
    if (description.length < 20 || description.length > 2000) {
      return res.status(400).json({
        success: false,
        message: "Property description must be 20-2000 characters",
      });
    }

    // Validate prices
    if (!validatePrice(monthlyRent, 1000, 1000000)) {
      return res.status(400).json({
        success: false,
        message: "Monthly rent must be between 1,000 and 1,000,000 PKR",
      });
    }

    if (securityDeposit && !validatePrice(securityDeposit, 1000, 1000000)) {
      return res.status(400).json({
        success: false,
        message: "Security deposit must be between 1,000 and 1,000,000 PKR",
      });
    }

    if (advanceRent && !validatePrice(advanceRent, 1000, 1000000)) {
      return res.status(400).json({
        success: false,
        message: "Advance rent must be between 1,000 and 1,000,000 PKR",
      });
    }

    // Validate numeric fields
    if (bedrooms && (bedrooms < 1 || bedrooms > 50)) {
      return res.status(400).json({
        success: false,
        message: "Bedrooms must be between 1 and 50",
      });
    }

    if (bathrooms && (bathrooms < 1 || bathrooms > 50)) {
      return res.status(400).json({
        success: false,
        message: "Bathrooms must be between 1 and 50",
      });
    }

    if (maxOccupants && (maxOccupants < 1 || maxOccupants > 100)) {
      return res.status(400).json({
        success: false,
        message: "Max occupants must be between 1 and 100",
      });
    }

    // Sanitize string fields
    const sanitizedTitle = sanitizeString(title);
    const sanitizedDescription = sanitizeString(description);
    const sanitizedAddress = sanitizeString(address);
    const sanitizedCity = sanitizeString(city);
    const sanitizedArea = sanitizeString(area);
    const sanitizedFloor = sanitizeString(floor);
    const sanitizedRoomType = sanitizeString(roomType);
    const sanitizedPropertyType = sanitizeString(propertyType);
    const sanitizedFurnished = sanitizeString(furnished);
    const sanitizedGenderPreference = sanitizeString(genderPreference);
    const sanitizedHouseRules = Array.isArray(houseRules)
      ? houseRules.map((r) => sanitizeString(r))
      : [];

    const property = new HousingProperty({
      title: sanitizedTitle,
      description: sanitizedDescription,
      propertyType: sanitizedPropertyType,
      ownerId: spId,
      monthlyRent,
      securityDeposit: securityDeposit || 0,
      advanceRent: advanceRent || 0,
      images: images || [],
      thumbnailImage: (images && images[0]) || "",
      address: sanitizedAddress,
      city: sanitizedCity,
      area: sanitizedArea || "",
      location:
        lat && lng
          ? { type: "Point", coordinates: [parseFloat(lng), parseFloat(lat)] }
          : undefined,
      facilities: facilities || {},
      bedrooms: bedrooms || 1,
      bathrooms: bathrooms || 1,
      area_sqft: area_sqft || 0,
      floor: sanitizedFloor || "",
      furnished: sanitizedFurnished || "Unfurnished",
      genderPreference: sanitizedGenderPreference || "Any",
      roomType: sanitizedRoomType || "Private",
      maxOccupants: maxOccupants || 1,
      currentOccupants: currentOccupants || 0,
      availableFrom: availableFrom || new Date(),
      houseRules: sanitizedHouseRules || [],
      status: "pending_approval",
    });

    await property.save();

    res.status(201).json({
      success: true,
      message: "Property created! Awaiting admin approval.",
      property,
    });
  } catch (error) {
    console.error("Create property error:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// PUT /api/housing/:id
router.put("/:id", verifyToken, async (req, res) => {
  try {
    const spId = req.user.spId || req.user.userId;
    const property = await HousingProperty.findById(req.params.id);
    if (!property)
      return res
        .status(404)
        .json({ success: false, message: "Property not found" });
    if (property.ownerId.toString() !== spId) {
      return res
        .status(403)
        .json({ success: false, message: "Not authorized" });
    }

    let updateData = req.body;

    // ─── VALIDATION & SANITIZATION ────────────────────────────────────────
    // Validate title if provided
    if (updateData.title) {
      if (updateData.title.length < 5 || updateData.title.length > 200) {
        return res.status(400).json({
          success: false,
          message: "Property title must be 5-200 characters",
        });
      }
      updateData.title = sanitizeString(updateData.title);
    }

    // Validate description if provided
    if (updateData.description) {
      if (
        updateData.description.length < 20 ||
        updateData.description.length > 2000
      ) {
        return res.status(400).json({
          success: false,
          message: "Property description must be 20-2000 characters",
        });
      }
      updateData.description = sanitizeString(updateData.description);
    }

    // Validate prices if provided
    if (updateData.monthlyRent) {
      if (!validatePrice(updateData.monthlyRent, 1000, 1000000)) {
        return res.status(400).json({
          success: false,
          message: "Monthly rent must be between 1,000 and 1,000,000 PKR",
        });
      }
      updateData.monthlyRent = Number(updateData.monthlyRent);
    }

    if (updateData.securityDeposit) {
      if (!validatePrice(updateData.securityDeposit, 1000, 1000000)) {
        return res.status(400).json({
          success: false,
          message: "Security deposit must be between 1,000 and 1,000,000 PKR",
        });
      }
      updateData.securityDeposit = Number(updateData.securityDeposit);
    }

    if (updateData.advanceRent) {
      if (!validatePrice(updateData.advanceRent, 1000, 1000000)) {
        return res.status(400).json({
          success: false,
          message: "Advance rent must be between 1,000 and 1,000,000 PKR",
        });
      }
      updateData.advanceRent = Number(updateData.advanceRent);
    }

    // Validate numeric fields
    if (
      updateData.bedrooms &&
      (updateData.bedrooms < 1 || updateData.bedrooms > 50)
    ) {
      return res.status(400).json({
        success: false,
        message: "Bedrooms must be between 1 and 50",
      });
    }

    if (
      updateData.bathrooms &&
      (updateData.bathrooms < 1 || updateData.bathrooms > 50)
    ) {
      return res.status(400).json({
        success: false,
        message: "Bathrooms must be between 1 and 50",
      });
    }

    if (
      updateData.maxOccupants &&
      (updateData.maxOccupants < 1 || updateData.maxOccupants > 100)
    ) {
      return res.status(400).json({
        success: false,
        message: "Max occupants must be between 1 and 100",
      });
    }

    // Sanitize string fields
    if (updateData.address) {
      updateData.address = sanitizeString(updateData.address);
    }
    if (updateData.city) {
      updateData.city = sanitizeString(updateData.city);
    }
    if (updateData.area) {
      updateData.area = sanitizeString(updateData.area);
    }
    if (updateData.floor) {
      updateData.floor = sanitizeString(updateData.floor);
    }
    if (updateData.propertyType) {
      updateData.propertyType = sanitizeString(updateData.propertyType);
    }
    if (updateData.furnished) {
      updateData.furnished = sanitizeString(updateData.furnished);
    }
    if (updateData.roomType) {
      updateData.roomType = sanitizeString(updateData.roomType);
    }
    if (updateData.genderPreference) {
      updateData.genderPreference = sanitizeString(updateData.genderPreference);
    }
    if (updateData.houseRules && Array.isArray(updateData.houseRules)) {
      updateData.houseRules = updateData.houseRules.map((r) =>
        sanitizeString(r),
      );
    }

    const updated = await HousingProperty.findByIdAndUpdate(
      req.params.id,
      { ...updateData, updatedAt: Date.now() },
      { new: true, runValidators: true },
    );
    res.json({ success: true, message: "Property updated", property: updated });
  } catch (error) {
    console.error("Update property error:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// DELETE /api/housing/:id
router.delete("/:id", verifyToken, async (req, res) => {
  try {
    const spId = req.user.spId || req.user.userId;
    let property = await HousingProperty.findById(req.params.id);

    let isLegacy = false;
    if (!property) {
      property = await Service.findById(req.params.id);
      if (property && property.serviceType === "Hostel/Flat Accommodation") {
        isLegacy = true;
        if (property.serviceProviderId.toString() !== spId)
          return res
            .status(403)
            .json({ success: false, message: "Not authorized" });
      } else {
        return res
          .status(404)
          .json({ success: false, message: "Property not found" });
      }
    }

    if (!isLegacy && property.ownerId.toString() !== spId) {
      return res
        .status(403)
        .json({ success: false, message: "Not authorized" });
    }

    if (isLegacy) {
      await Service.findByIdAndDelete(req.params.id);
    } else {
      await HousingProperty.findByIdAndDelete(req.params.id);
    }

    await HousingFavorite.deleteMany({ propertyId: req.params.id });

    res.json({ success: true, message: "Property deleted" });
  } catch (error) {
    console.error("Delete property error:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error", error: error.message });
  }
});

// ════════════════════════════════════════════════════════════════════════════════
// 4. GENERIC ID ROUTE (MUST BE LAST)
// ════════════════════════════════════════════════════════════════════════════════

// GET /api/housing/:id — Property detail
router.get("/:id", async (req, res) => {
  try {
    // Validate that id is a valid ObjectId to avoid matching random paths
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res
        .status(400)
        .json({ success: false, message: "Invalid property ID" });
    }

    let property = await HousingProperty.findById(req.params.id)
      .populate(
        "ownerId",
        "firstName lastName profileImage rating phone email city address bio experienceYears createdAt",
      )
      .lean();

    if (!property) {
      // Try fetching from legacy services
      const legacy = await Service.findById(req.params.id)
        .populate("serviceProviderId")
        .lean();
      if (legacy && legacy.serviceType === "Hostel/Flat Accommodation") {
        property = {
          _id: legacy._id,
          title: legacy.serviceName || legacy.title,
          description: legacy.description,
          propertyType: "Hostel",
          monthlyRent: legacy.price,
          images: legacy.imageUrl ? [legacy.imageUrl] : [],
          address: legacy.address,
          city: legacy.serviceProviderCity || "Local",
          bedrooms: legacy.availableRooms || 1,
          bathrooms: 1,
          furnished: "Semi-Furnished",
          ownerId: legacy.serviceProviderId,
          status: "approved",
          isAvailable: true,
          isLegacy: true,
          facilities: { wifi: true, water: true, electricity: true }, // Mock facilities for legacy
        };
      } else {
        return res
          .status(404)
          .json({ success: false, message: "Property not found" });
      }
    } else {
      // Increment view count for new properties
      await HousingProperty.findByIdAndUpdate(req.params.id, {
        $inc: { viewsCount: 1 },
      });
    }

    const enriched = {
      ...property,
      ownerName: property.ownerId
        ? `${property.ownerId.firstName} ${property.ownerId.lastName}`
        : "Owner",
      ownerImage: property.ownerId?.profileImage || null,
      ownerRating: property.ownerId?.rating || 0,
      ownerPhone: property.ownerId?.phone || null,
      ownerEmail: property.ownerId?.email || null,
      ownerBio: property.ownerId?.bio || null,
      ownerJoined: property.ownerId?.createdAt || null,
    };

    res.json({ success: true, property: enriched });
  } catch (error) {
    console.error("Housing detail error for ID " + req.params.id + ":", error);
    res
      .status(500)
      .json({ success: false, message: "Server error: " + error.message });
  }
});

module.exports = router;

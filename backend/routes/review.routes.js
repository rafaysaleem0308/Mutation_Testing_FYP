const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");
const Review = require("../models/review.model");
const Order = require("../models/order.model");
const ServiceProvider = require("../models/service-provider.model");
const Service = require("../models/service.model");
const User = require("../models/user.model");
const { verifyToken } = require("../middleware/auth");

// ─── VALIDATION & SANITIZATION ────────────────────────────────────────────
const { validateRating, sanitizeHtmlContent } = require("../utils/validators");

// Create a review
router.post("/submit", verifyToken, async (req, res) => {
  try {
    const { orderId, rating, comment } = req.body;
    const customerId = req.user.userId;

    // ─── VALIDATION ────────────────────────────────────────────────────────
    if (!orderId || rating === undefined) {
      return res.status(400).json({
        success: false,
        message: "Order ID and rating are required",
      });
    }

    // Validate rating bounds (1-5)
    if (!validateRating(rating)) {
      return res.status(400).json({
        success: false,
        message: "Rating must be between 1 and 5",
      });
    }

    // Validate and sanitize comment
    let sanitizedComment = "";
    if (comment) {
      sanitizedComment = sanitizeHtmlContent(comment);
      if (sanitizedComment.length > 1000) {
        return res.status(400).json({
          success: false,
          message: "Comment must not exceed 1000 characters",
        });
      }
    }

    // Check if order exists and belongs to user
    const order = await Order.findById(orderId);
    if (!order) {
      return res
        .status(404)
        .json({ success: false, message: "Order not found" });
    }

    if (order.customerId.toString() !== customerId.toString()) {
      return res.status(403).json({ success: false, message: "Unauthorized" });
    }

    // Check if already reviewed
    const existingReview = await Review.findOne({ orderId });
    if (existingReview) {
      return res
        .status(400)
        .json({ success: false, message: "Order already reviewed" });
    }

    // Get customer details
    const user = await User.findById(customerId);

    // Create review
    const review = new Review({
      orderId,
      customerId,
      serviceProviderId: order.serviceProviderSpId || order.serviceProviderId,
      serviceId: order.items[0]?.serviceId,
      rating,
      comment: sanitizedComment,
      customerName: user ? `${user.firstName} ${user.lastName}` : "Customer",
      customerImage: user?.profileImage || "",
    });

    await review.save();

    // Update Order to mark as reviewed
    order.rating = rating;
    order.review = comment;
    order.reviewDate = new Date();
    await order.save();

    // Update ServiceProvider Stats
    const spResult = await ServiceProvider.findById(review.serviceProviderId);
    if (spResult) {
      const newReviewsCount = (spResult.reviewsCount || 0) + 1;
      const currentTotalRating =
        (spResult.rating || 0) * (spResult.reviewsCount || 0);
      const newAverageRating = (currentTotalRating + rating) / newReviewsCount;

      spResult.rating = newAverageRating;
      spResult.reviewsCount = newReviewsCount;
      await spResult.save();
    }

    // Update Service Stats
    if (review.serviceId) {
      const service = await Service.findById(review.serviceId);
      if (service) {
        const newTotalReviews = (service.totalReviews || 0) + 1;
        const currentTotalServiceRating =
          (service.rating || 0) * (service.totalReviews || 0);
        const newServiceAverageRating =
          (currentTotalServiceRating + rating) / newTotalReviews;

        service.rating = newServiceAverageRating;
        service.totalReviews = newTotalReviews;
        await service.save();
      }
    }

    res
      .status(201)
      .json({
        success: true,
        message: "Review submitted successfully",
        review,
      });
  } catch (error) {
    console.error("Review error:", error);
    res
      .status(500)
      .json({ success: false, message: "Server error: " + error.message });
  }
});

// Get reviews for a provider
router.get("/provider/:spId", async (req, res) => {
  try {
    const reviews = await Review.find({ serviceProviderId: req.params.spId })
      .sort({ createdAt: -1 })
      .limit(50);
    res.status(200).json({ success: true, reviews });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// Get reviews for a specific service
router.get("/service/:serviceId", async (req, res) => {
  try {
    const reviews = await Review.find({ serviceId: req.params.serviceId })
      .sort({ createdAt: -1 })
      .limit(50);
    res.status(200).json({ success: true, reviews });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

module.exports = router;

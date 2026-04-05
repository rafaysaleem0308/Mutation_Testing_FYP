const express = require("express");
const router = express.Router();
const { verifyToken } = require("../middleware/auth");
const RecommendationEngine = require("../utils/recommendation-engine");

// ════════════════════════════════════════════════════════════════════════════
// GET PERSONALIZED RECOMMENDATIONS
// ════════════════════════════════════════════════════════════════════════════
router.get("/personalized", verifyToken, async (req, res) => {
  try {
    const { limit = 10 } = req.query;
    const userId = req.user.userId;

    const recommendations =
      await RecommendationEngine.getPersonalizedRecommendations(
        userId,
        parseInt(limit),
      );

    res.status(200).json({
      success: true,
      recommendations,
      count: recommendations.length,
    });
  } catch (error) {
    console.error("Get personalized recommendations error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to generate personalized recommendations",
    });
  }
});

// ════════════════════════════════════════════════════════════════════════════
// TRACK INTERACTION
// ════════════════════════════════════════════════════════════════════════════
router.post("/track", verifyToken, async (req, res) => {
  try {
    const { interactionType, serviceId, serviceType, metadata } = req.body;
    const userId = req.user.userId;

    // Validate required fields
    if (!interactionType) {
      return res.status(400).json({
        success: false,
        message: "interactionType is required",
      });
    }

    const interactionData = {
      interactionType,
      serviceId: serviceId || null,
      serviceType: serviceType || null,
      metadata: metadata || {},
    };

    const result = await RecommendationEngine.trackInteraction(
      userId,
      interactionData,
    );

    res.status(201).json({
      success: true,
      message: "Interaction tracked",
      interaction: result,
    });
  } catch (error) {
    console.error("Track interaction error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to track interaction",
    });
  }
});

// ════════════════════════════════════════════════════════════════════════════
// GET GENERIC FEATURED RECOMMENDATIONS (PUBLIC)
// ════════════════════════════════════════════════════════════════════════════
router.get("/featured", async (req, res) => {
  try {
    const { limit = 10, type } = req.query;
    const Service = require("../models/service.model");
    let query = { status: "Active", featured: true };

    if (type) query.serviceType = type;

    const services = await Service.find(query)
      .sort({ rating: -1, createdAt: -1 })
      .limit(parseInt(limit))
      .lean();

    res.status(200).json({
      success: true,
      services,
      total: services.length,
    });
  } catch (error) {
    console.error("Get featured services error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
    });
  }
});

// ════════════════════════════════════════════════════════════════════════════
// GET GENERIC TOP-RATED RECOMMENDATIONS (PUBLIC)
// ════════════════════════════════════════════════════════════════════════════
router.get("/top-rated", async (req, res) => {
  try {
    const { limit = 8, type } = req.query;
    const Service = require("../models/service.model");
    let query = { status: "Active", rating: { $gte: 3.5 } };

    if (type) query.serviceType = type;

    const services = await Service.find(query)
      .sort({ rating: -1, totalReviews: -1, createdAt: -1 })
      .limit(parseInt(limit))
      .lean();

    res.status(200).json({
      success: true,
      services,
      total: services.length,
    });
  } catch (error) {
    console.error("Get top rated services error:", error);
    res.status(500).json({
      success: false,
      message: "Server error",
    });
  }
});

module.exports = router;

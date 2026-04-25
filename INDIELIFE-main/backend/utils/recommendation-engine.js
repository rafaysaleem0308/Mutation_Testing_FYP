const Service = require("../models/service.model");
const Order = require("../models/order.model");
const Review = require("../models/review.model");
const HousingFavorite = require("../models/housing-favorite.model");
const UserInteraction = require("../models/user-interaction.model");

class RecommendationEngine {
  /**
   * Generate personalized recommendations for a user
   * @param {String} userId - User ID
   * @param {Number} limit - Number of recommendations
   * @returns {Array} Recommended services
   */
  static async getPersonalizedRecommendations(userId, limit = 10) {
    try {
      // Fetch user's interaction patterns
      const userInteractions = await this._getUserInteractionPatterns(userId);
      const userOrders = await this._getUserOrderPatterns(userId);
      const userReviews = await this._getUserReviewPatterns(userId);
      const housingPreferences = await this._getUserHousingPreferences(userId);

      // Generate recommendations based on multiple factors
      let recommendations = new Map();

      // 1. Services similar to what user has already liked/purchased (content-based)
      const contentBasedRecs = await this._getContentBasedRecommendations(
        userOrders,
        userReviews,
      );
      contentBasedRecs.forEach((service) => {
        recommendations.set(service._id.toString(), {
          ...service,
          score: 0,
          reasons: [],
        });
      });

      // 2. Trending services in user's preferred categories (collaborative)
      const trendingRecs =
        await this._getTrendingServicesByUserType(userOrders);
      trendingRecs.forEach((service) => {
        const key = service._id.toString();
        if (recommendations.has(key)) {
          recommendations.get(key).score += 2;
          recommendations.get(key).reasons.push("Trending in your category");
        } else {
          recommendations.set(key, {
            ...service,
            score: 2,
            reasons: ["Trending in your category"],
          });
        }
      });

      // 3. Highly-rated services user hasn't interacted with
      const discoveryRecs = await this._getDiscoveryRecommendations(
        userId,
        userOrders,
      );
      discoveryRecs.forEach((service) => {
        const key = service._id.toString();
        if (recommendations.has(key)) {
          recommendations.get(key).score += 1.5;
          recommendations.get(key).reasons.push("Highly-rated discovery");
        } else {
          recommendations.set(key, {
            ...service,
            score: 1.5,
            reasons: ["Highly-rated discovery"],
          });
        }
      });

      // 4. Similar to housing preferences (if user is looking for accommodations)
      if (housingPreferences.length > 0) {
        const housingRelatedServices =
          await this._getHousingRelatedServices(housingPreferences);
        housingRelatedServices.forEach((service) => {
          const key = service._id.toString();
          if (recommendations.has(key)) {
            recommendations.get(key).score += 1;
            recommendations
              .get(key)
              .reasons.push("Related to your accommodations");
          } else {
            recommendations.set(key, {
              ...service,
              score: 1,
              reasons: ["Related to your accommodations"],
            });
          }
        });
      }

      // Sort by score and return top N
      const sorted = Array.from(recommendations.values())
        .filter((r) => r.score > 0)
        .sort((a, b) => b.score - a.score)
        .slice(0, limit)
        .map((r) => {
          const { score, reasons, ...service } = r;
          return {
            ...service,
            personalizationScore: score,
            personalizationReasons: reasons,
          };
        });

      return sorted;
    } catch (error) {
      console.error("Recommendation generation error:", error);
      throw error;
    }
  }

  /**
   * Track user interaction (view, click, cart add, etc.)
   */
  static async trackInteraction(userId, interactionData) {
    try {
      const interaction = new UserInteraction({
        userId,
        ...interactionData,
      });
      await interaction.save();
      return interaction;
    } catch (error) {
      console.error("Track interaction error:", error);
      // Don't throw - tracking failures shouldn't break the app
      return null;
    }
  }

  /**
   * Get user's interaction patterns
   */
  static async _getUserInteractionPatterns(userId) {
    try {
      const patterns = await UserInteraction.aggregate([
        { $match: { userId: this._toObjectId(userId) } },
        {
          $group: {
            _id: "$serviceType",
            count: { $sum: 1 },
            types: { $push: "$interactionType" },
          },
        },
        { $sort: { count: -1 } },
      ]);
      return patterns;
    } catch (error) {
      console.error("Get interaction patterns error:", error);
      return [];
    }
  }

  /**
   * Get user's order patterns by service type
   */
  static async _getUserOrderPatterns(userId) {
    try {
      const orders = await Order.aggregate([
        { $match: { userId: this._toObjectId(userId) } },
        {
          $group: {
            _id: "$serviceType",
            count: { $sum: 1 },
            avgRating: { $avg: "$rating" },
            services: { $push: "$serviceId" },
          },
        },
        { $sort: { count: -1 } },
      ]);
      return orders;
    } catch (error) {
      console.error("Get order patterns error:", error);
      return [];
    }
  }

  /**
   * Get user's review patterns
   */
  static async _getUserReviewPatterns(userId) {
    try {
      const reviews = await Review.aggregate([
        { $match: { userId: this._toObjectId(userId) } },
        {
          $group: {
            _id: "$serviceType",
            avgRating: { $avg: "$rating" },
            count: { $sum: 1 },
          },
        },
        { $sort: { count: -1 } },
      ]);
      return reviews;
    } catch (error) {
      console.error("Get review patterns error:", error);
      return [];
    }
  }

  /**
   * Get user's housing preferences from favorites
   */
  static async _getUserHousingPreferences(userId) {
    try {
      // Get properties user has favorited
      const favorites = await HousingFavorite.find({
        userId: this._toObjectId(userId),
      })
        .populate("propertyId", "city propertyType budget genderPreference")
        .lean();

      // Extract common patterns
      const preferences = {};
      favorites.forEach((fav) => {
        if (fav.propertyId) {
          preferences.cities = preferences.cities || [];
          preferences.types = preferences.types || [];
          preferences.budgetRange = preferences.budgetRange || [];

          if (fav.propertyId.city) preferences.cities.push(fav.propertyId.city);
          if (fav.propertyId.propertyType)
            preferences.types.push(fav.propertyId.propertyType);
          if (fav.propertyId.budget)
            preferences.budgetRange.push(fav.propertyId.budget);
        }
      });

      return Object.keys(preferences).length > 0 ? [preferences] : [];
    } catch (error) {
      console.error("Get housing preferences error:", error);
      return [];
    }
  }

  /**
   * Content-based: Find services similar to user's past orders
   */
  static async _getContentBasedRecommendations(orderPatterns, reviewPatterns) {
    try {
      // Get service types user is interested in
      const preferredTypes = orderPatterns
        .slice(0, 3)
        .map((p) => p._id)
        .filter((t) => t);

      if (preferredTypes.length === 0) return [];

      const services = await Service.find({
        serviceType: { $in: preferredTypes },
        status: "Active",
        rating: { $gte: 3.0 },
      })
        .sort({ rating: -1, totalReviews: -1 })
        .limit(15)
        .lean();

      return services;
    } catch (error) {
      console.error("Get content-based recommendations error:", error);
      return [];
    }
  }

  /**
   * Collaborative-based: Trending services in user's preferred categories
   */
  static async _getTrendingServicesByUserType(orderPatterns) {
    try {
      const preferredTypes = orderPatterns
        .slice(0, 2)
        .map((p) => p._id)
        .filter((t) => t);

      if (preferredTypes.length === 0) return [];

      const services = await Service.find({
        serviceType: { $in: preferredTypes },
        status: "Active",
        rating: { $gte: 3.5 },
      })
        .sort({ featured: -1, rating: -1, totalReviews: -1 })
        .limit(10)
        .lean();

      return services;
    } catch (error) {
      console.error("Get trending services error:", error);
      return [];
    }
  }

  /**
   * Discovery: High-rated services user hasn't seen yet
   */
  static async _getDiscoveryRecommendations(userId, orderPatterns) {
    try {
      // Get all service types user has ordered
      const viewedServiceTypes = orderPatterns
        .map((p) => p._id)
        .filter((t) => t);

      // Get services from different categories
      const allTypes = ["Hostel", "Laundry", "Maintenance", "Meal"];
      const unexploredTypes = allTypes.filter(
        (t) => !viewedServiceTypes.includes(t),
      );

      if (unexploredTypes.length === 0) {
        // If user explored all types, get other highly-rated services
        return await Service.find({
          status: "Active",
          rating: { $gte: 4.0 },
        })
          .sort({ rating: -1, totalReviews: -1 })
          .limit(8)
          .lean();
      }

      const services = await Service.find({
        serviceType: { $in: unexploredTypes },
        status: "Active",
        rating: { $gte: 3.5 },
      })
        .sort({ rating: -1, totalReviews: -1 })
        .limit(10)
        .lean();

      return services;
    } catch (error) {
      console.error("Get discovery recommendations error:", error);
      return [];
    }
  }

  /**
   * Get housing-related services
   */
  static async _getHousingRelatedServices(housingPreferences) {
    try {
      // Find complementary services for housing (maintenance, meal plans, laundry)
      const complementaryTypes = ["Maintenance", "Meal", "Laundry"];

      const services = await Service.find({
        serviceType: { $in: complementaryTypes },
        status: "Active",
        rating: { $gte: 3.0 },
      })
        .sort({ rating: -1 })
        .limit(8)
        .lean();

      return services;
    } catch (error) {
      console.error("Get housing-related services error:", error);
      return [];
    }
  }

  /**
   * Helper: Convert to ObjectId
   */
  static _toObjectId(id) {
    if (typeof id === "string") {
      return require("mongoose").Types.ObjectId(id);
    }
    return id;
  }
}

module.exports = RecommendationEngine;

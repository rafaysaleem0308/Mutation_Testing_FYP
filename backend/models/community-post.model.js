const mongoose = require("mongoose");

const communityPostSchema = new mongoose.Schema(
  {
    // Post author
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    userName: {
      type: String,
      required: true,
    },
    userEmail: {
      type: String,
      required: true,
    },
    userRole: {
      type: String,
      enum: ["User", "Service Provider", "Admin"],
      default: "User",
    },
    userProfileImage: {
      type: String,
      default: null,
    },

    // Post content
    content: {
      type: String,
      required: true,
      trim: true,
      maxlength: 5000,
    },
    category: {
      type: String,
      enum: ["News", "Offers", "Social", "Buy/Sell"],
      default: "Social",
    },

    // Engagement
    likes: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],
    comments: [
      {
        _id: mongoose.Schema.Types.ObjectId,
        userId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "User",
          required: true,
        },
        userName: String,
        userProfileImage: String,
        content: {
          type: String,
          required: true,
          maxlength: 1000,
        },
        createdAt: {
          type: Date,
          default: Date.now,
        },
      },
    ],

    // Moderation
    isActive: {
      type: Boolean,
      default: true,
    },
    isFlagged: {
      type: Boolean,
      default: false,
    },
    flagReason: String,

    // Metadata
    viewCount: {
      type: Number,
      default: 0,
    },
  },
  {
    timestamps: true,
  },
);

// Index for better query performance
communityPostSchema.index({ category: 1, createdAt: -1 });
communityPostSchema.index({ userId: 1, createdAt: -1 });
communityPostSchema.index({ isActive: 1, createdAt: -1 });

module.exports = mongoose.model("CommunityPost", communityPostSchema);

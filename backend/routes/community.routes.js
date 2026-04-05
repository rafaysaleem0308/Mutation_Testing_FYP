const express = require("express");
const router = express.Router();
const CommunityPost = require("../models/community-post.model");
const User = require("../models/user.model");
const { verifyToken } = require("../middleware/auth");
const mongoose = require("mongoose");

// ════════════════════════════════════════════════════════════════════════════
// GET COMMUNITY POSTS
// ════════════════════════════════════════════════════════════════════════════
router.get("/posts", async (req, res) => {
  try {
    const { page = 1, limit = 20, category } = req.query;
    const skip = (page - 1) * limit;

    // Build query
    let query = { isActive: true };
    if (category && category !== "All") {
      query.category = category;
    }

    // Fetch posts
    const posts = await CommunityPost.find(query)
      .populate("userId", "firstName lastName")
      .populate("comments.userId", "firstName lastName")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    // Get total count
    const total = await CommunityPost.countDocuments(query);

    // Format response
    const formattedPosts = posts.map((post) => ({
      ...post,
      likes: post.likes.length,
      comments: post.comments.length,
    }));

    res.status(200).json({
      success: true,
      posts: formattedPosts,
      total,
      page: parseInt(page),
      totalPages: Math.ceil(total / limit),
      hasMore: skip + formattedPosts.length < total,
    });
  } catch (error) {
    console.error("Get community posts error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to fetch community posts",
    });
  }
});

// ════════════════════════════════════════════════════════════════════════════
// CREATE COMMUNITY POST
// ════════════════════════════════════════════════════════════════════════════
router.post("/posts", verifyToken, async (req, res) => {
  try {
    const { content, category } = req.body;

    // Validation
    if (!content || content.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: "Post content is required",
      });
    }

    if (content.trim().length > 5000) {
      return res.status(400).json({
        success: false,
        message: "Post content cannot exceed 5000 characters",
      });
    }

    // Get user info
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // Create post
    const newPost = new CommunityPost({
      userId: req.user.userId,
      userName: `${user.firstName} ${user.lastName}`,
      userEmail: user.email,
      userRole: user.role,
      userProfileImage: user.profileImage,
      content: content.trim(),
      category: category || "Social",
      likes: [],
      comments: [],
    });

    await newPost.save();

    // Populate user data
    await newPost.populate("userId", "firstName lastName");

    res.status(201).json({
      success: true,
      message: "Post created successfully",
      post: {
        ...newPost.toObject(),
        likes: 0,
        comments: 0,
      },
    });
  } catch (error) {
    console.error("Create post error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to create post",
    });
  }
});

// ════════════════════════════════════════════════════════════════════════════
// LIKE/UNLIKE POST
// ════════════════════════════════════════════════════════════════════════════
router.post("/posts/:id/like", verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

    // Validate ID
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid post ID",
      });
    }

    const post = await CommunityPost.findById(id);
    if (!post) {
      return res.status(404).json({
        success: false,
        message: "Post not found",
      });
    }

    // Toggle like
    const userIdStr = userId.toString();
    const likeIndex = post.likes.findIndex((id) => id.toString() === userIdStr);

    if (likeIndex > -1) {
      // Unlike
      post.likes.splice(likeIndex, 1);
    } else {
      // Like
      post.likes.push(userId);
    }

    await post.save();

    res.status(200).json({
      success: true,
      liked: likeIndex === -1,
      likeCount: post.likes.length,
      message: likeIndex === -1 ? "Post liked" : "Post unliked",
    });
  } catch (error) {
    console.error("Like post error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to toggle like",
    });
  }
});

// ════════════════════════════════════════════════════════════════════════════
// ADD COMMENT TO POST
// ════════════════════════════════════════════════════════════════════════════
router.post("/posts/:id/comments", verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { comment } = req.body;
    const userId = req.user.userId;

    // Validation
    if (!comment || comment.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: "Comment content is required",
      });
    }

    if (comment.trim().length > 1000) {
      return res.status(400).json({
        success: false,
        message: "Comment cannot exceed 1000 characters",
      });
    }

    // Validate ID
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid post ID",
      });
    }

    // Get user info
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    const post = await CommunityPost.findById(id);
    if (!post) {
      return res.status(404).json({
        success: false,
        message: "Post not found",
      });
    }

    // Add comment
    const newComment = {
      _id: new mongoose.Types.ObjectId(),
      userId: userId,
      userName: `${user.firstName} ${user.lastName}`,
      userProfileImage: user.profileImage,
      content: comment.trim(),
      createdAt: new Date(),
    };

    post.comments.push(newComment);
    await post.save();

    res.status(201).json({
      success: true,
      message: "Comment added successfully",
      comment: newComment,
      commentCount: post.comments.length,
    });
  } catch (error) {
    console.error("Add comment error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to add comment",
    });
  }
});

// ════════════════════════════════════════════════════════════════════════════
// DELETE POST (Author or Admin only)
// ════════════════════════════════════════════════════════════════════════════
router.delete("/posts/:id", verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

    // Validate ID
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid post ID",
      });
    }

    const post = await CommunityPost.findById(id);
    if (!post) {
      return res.status(404).json({
        success: false,
        message: "Post not found",
      });
    }

    // Check authorization
    if (post.userId.toString() !== userId.toString()) {
      // Check if user is admin
      const user = await User.findById(userId);
      if (user.role !== "Admin") {
        return res.status(403).json({
          success: false,
          message: "Not authorized to delete this post",
        });
      }
    }

    await CommunityPost.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: "Post deleted successfully",
    });
  } catch (error) {
    console.error("Delete post error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to delete post",
    });
  }
});

// ════════════════════════════════════════════════════════════════════════════
// DELETE COMMENT (Author or Admin only)
// ════════════════════════════════════════════════════════════════════════════
router.delete(
  "/posts/:postId/comments/:commentId",
  verifyToken,
  async (req, res) => {
    try {
      const { postId, commentId } = req.params;
      const userId = req.user.userId;

      // Validate IDs
      if (!mongoose.Types.ObjectId.isValid(postId)) {
        return res.status(400).json({
          success: false,
          message: "Invalid post ID",
        });
      }

      if (!mongoose.Types.ObjectId.isValid(commentId)) {
        return res.status(400).json({
          success: false,
          message: "Invalid comment ID",
        });
      }

      const post = await CommunityPost.findById(postId);
      if (!post) {
        return res.status(404).json({
          success: false,
          message: "Post not found",
        });
      }

      // Find comment
      const comment = post.comments.find((c) => c._id.toString() === commentId);
      if (!comment) {
        return res.status(404).json({
          success: false,
          message: "Comment not found",
        });
      }

      // Check authorization
      if (comment.userId.toString() !== userId.toString()) {
        const user = await User.findById(userId);
        if (
          user.role !== "Admin" &&
          post.userId.toString() !== userId.toString()
        ) {
          return res.status(403).json({
            success: false,
            message: "Not authorized to delete this comment",
          });
        }
      }

      // Remove comment
      post.comments = post.comments.filter(
        (c) => c._id.toString() !== commentId,
      );
      await post.save();

      res.status(200).json({
        success: true,
        message: "Comment deleted successfully",
        commentCount: post.comments.length,
      });
    } catch (error) {
      console.error("Delete comment error:", error);
      res.status(500).json({
        success: false,
        message: "Failed to delete comment",
      });
    }
  },
);

// ════════════════════════════════════════════════════════════════════════════
// FLAG POST (Moderation)
// ════════════════════════════════════════════════════════════════════════════
router.post("/posts/:id/flag", verifyToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;

    if (!reason) {
      return res.status(400).json({
        success: false,
        message: "Flag reason is required",
      });
    }

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: "Invalid post ID",
      });
    }

    const post = await CommunityPost.findById(id);
    if (!post) {
      return res.status(404).json({
        success: false,
        message: "Post not found",
      });
    }

    post.isFlagged = true;
    post.flagReason = reason;
    await post.save();

    res.status(200).json({
      success: true,
      message: "Post flagged for review",
    });
  } catch (error) {
    console.error("Flag post error:", error);
    res.status(500).json({
      success: false,
      message: "Failed to flag post",
    });
  }
});

module.exports = router;

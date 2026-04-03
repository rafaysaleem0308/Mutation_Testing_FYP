const express = require("express");
const router = express.Router();
const Notification = require("../models/notification.model");
const { verifyToken } = require("../middleware/auth");

// Adapter: set req.userId from req.user for backward compatibility
const authMiddleware = [verifyToken, (req, res, next) => {
    req.userId = req.user.userId || req.user.spId || req.user.id;
    next();
}];

// ── GET /api/notifications ── Fetch user notifications ──
router.get("/", authMiddleware, async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 30;
        const skip = (page - 1) * limit;

        const notifications = await Notification.find({ userId: req.userId })
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit)
            .lean();

        const unreadCount = await Notification.countDocuments({
            userId: req.userId,
            isRead: false,
        });

        const total = await Notification.countDocuments({ userId: req.userId });

        res.json({
            success: true,
            notifications,
            unreadCount,
            total,
            page,
            totalPages: Math.ceil(total / limit),
        });
    } catch (err) {
        console.error("Error fetching notifications:", err);
        res.status(500).json({ success: false, message: "Server error" });
    }
});

// ── GET /api/notifications/unread-count ── Quick badge count ──
router.get("/unread-count", authMiddleware, async (req, res) => {
    try {
        const count = await Notification.countDocuments({
            userId: req.userId,
            isRead: false,
        });
        res.json({ success: true, count });
    } catch (err) {
        res.status(500).json({ success: false, message: "Server error" });
    }
});

// ── PUT /api/notifications/mark-read ── Mark one or all as read ──
router.put("/mark-read", authMiddleware, async (req, res) => {
    try {
        const { notificationId } = req.body;

        if (notificationId) {
            // Mark single
            await Notification.findOneAndUpdate(
                { _id: notificationId, userId: req.userId },
                { isRead: true }
            );
        } else {
            // Mark all
            await Notification.updateMany(
                { userId: req.userId, isRead: false },
                { isRead: true }
            );
        }

        const unreadCount = await Notification.countDocuments({
            userId: req.userId,
            isRead: false,
        });

        res.json({ success: true, unreadCount });
    } catch (err) {
        res.status(500).json({ success: false, message: "Server error" });
    }
});

// ── DELETE /api/notifications/:id ── Delete a single notification ──
router.delete("/:id", authMiddleware, async (req, res) => {
    try {
        await Notification.findOneAndDelete({
            _id: req.params.id,
            userId: req.userId,
        });
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ success: false, message: "Server error" });
    }
});

// ── DELETE /api/notifications ── Clear all notifications ──
router.delete("/", authMiddleware, async (req, res) => {
    try {
        await Notification.deleteMany({ userId: req.userId });
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ success: false, message: "Server error" });
    }
});

// ── POST /api/notifications/create ── Create a notification (internal use) ──
router.post("/create", authMiddleware, async (req, res) => {
    try {
        const { targetUserId, title, body, type, referenceId, referenceType, icon } =
            req.body;

        const notification = await Notification.create({
            userId: targetUserId || req.userId,
            title,
            body,
            type: type || "system",
            referenceId: referenceId || null,
            referenceType: referenceType || null,
            icon: icon || "notifications",
        });

        // Emit via Socket.io if available
        const io = req.app.get("io");
        if (io) {
            io.to(targetUserId || req.userId).emit("new_notification", notification);
        }

        res.status(201).json({ success: true, notification });
    } catch (err) {
        console.error("Error creating notification:", err);
        res.status(500).json({ success: false, message: "Server error" });
    }
});

module.exports = router;

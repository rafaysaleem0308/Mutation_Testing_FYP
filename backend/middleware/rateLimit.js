/**
 * ─── Rate Limiting & Security Middleware ────────────────────────────────
 * Prevents brute force attacks, OTP spam, and API abuse
 */

const rateLimit = require("express-rate-limit");

// ─── GLOBAL RATE LIMITER (15 requests per 15 minutes) ──────────────────
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per window
  message: {
    success: false,
    message: "Too many requests, please try again later",
  },
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    // Skip rate limiting for health check endpoints
    return req.path === "/health" || req.path === "/status";
  },
});

// ─── AUTH RATE LIMITER (5 failed attempts, then 15-minute lockout) ──────
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per window
  message: {
    success: false,
    message: "Too many login attempts, account locked for 15 minutes",
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.body.email || req.ip, // Track by email or IP
  skip: (req) => req.method !== "POST", // Only rate limit POST requests
});

// ─── OTP RATE LIMITER (10 attempts per hour per email) ─────────────────
const otpLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10, // 10 OTP attempts per hour
  message: {
    success: false,
    message: "Too many OTP attempts, try again after 1 hour",
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.body.email || req.ip, // Track by email
});

// ─── PAYMENT RATE LIMITER (20 payment requests per hour) ───────────────
const paymentLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 20, // 20 payment requests per hour
  message: {
    success: false,
    message: "Too many payment attempts, try again later",
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.user?.userId || req.ip, // Track by user ID
});

// ─── SIGNUP RATE LIMITER (3 signups per hour per IP) ───────────────────
const signupLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 3, // 3 signups per hour
  message: {
    success: false,
    message: "Too many signup attempts, try again after 1 hour",
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.ip, // Track by IP
});

module.exports = {
  globalLimiter,
  authLimiter,
  otpLimiter,
  paymentLimiter,
  signupLimiter,
};

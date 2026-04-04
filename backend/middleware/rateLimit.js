/**
 * ─── Rate Limiting & Security Middleware ────────────────────────────────
 * Prevents brute force attacks, OTP spam, and API abuse
 */

const rateLimit = require("express-rate-limit");
const { ipKeyGenerator } = require("express-rate-limit");

// ─── GLOBAL RATE LIMITER (1000 requests per 15 minutes - generous limit) ──────────────────
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // 1000 requests per window (reasonable for normal app usage)
  message: {
    success: false,
    message: "Too many requests, please try again later",
  },
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    // Skip rate limiting for health checks, GET requests (data fetching), and status endpoints
    return (
      req.path === "/health" || req.path === "/status" || req.method === "GET" // Allow unlimited GET requests for data fetching
    );
  },
});

// ─── AUTH RATE LIMITER (20 failed login attempts per 15 minutes) ──────
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 20, // 20 login attempts per window (allows for accidental wrong password attempts)
  message: {
    success: false,
    message: "Too many login attempts, please try again later",
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.body.email || ipKeyGenerator(req), // Track by email or IP
  skip: (req) => req.method !== "POST", // Only rate limit POST requests
});

// ─── OTP RATE LIMITER (30 attempts per hour per email) ─────────────────
const otpLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 30, // 30 OTP attempts per hour (allows retries)
  message: {
    success: false,
    message: "Too many OTP attempts, try again after 1 hour",
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.body.email || ipKeyGenerator(req), // Track by email
});

// ─── PAYMENT RATE LIMITER (50 payment requests per hour) ───────────────
const paymentLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 50, // 50 payment requests per hour (allows multiple transactions)
  message: {
    success: false,
    message: "Too many payment attempts, try again later",
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.user?.userId || ipKeyGenerator(req), // Track by user ID
});

// ─── SIGNUP RATE LIMITER (10 signups per hour per IP) ───────────────────
const signupLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10, // 10 signups per hour (reasonable limit to prevent abuse)
  message: {
    success: false,
    message: "Too many signup attempts, try again after 1 hour",
  },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => ipKeyGenerator(req), // Track by IP
});

module.exports = {
  globalLimiter,
  authLimiter,
  otpLimiter,
  paymentLimiter,
  signupLimiter,
};

/**
 * ─── Custom Validators and Sanitizers ───────────────────────────────────
 * Centralized validation logic for the application
 */

const sanitizeHtml = require("sanitize-html");

// ─── EMAIL VALIDATION (RFC5322 Simplified) ──────────────────────────────
const validateEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

// ─── PASSWORD VALIDATION (Min 8 chars, 1 uppercase, 1 lowercase, 1 digit, 1 special) ───────
const validatePassword = (password) => {
  const passwordRegex =
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
  return passwordRegex.test(password);
};

// ─── PHONE VALIDATION (Pakistani Format: +92 or 03 followed by 9-10 digits) ────
const validatePhone = (phone) => {
  // Accept formats: +923001234567, 03001234567, 923001234567
  const phoneRegex = /^(\+92|0|92)3\d{2}\d{7}$/;
  return phoneRegex.test(phone.replace(/\s+/g, ""));
};

// ─── STRING SANITIZATION ─────────────────────────────────────────────────
const sanitizeString = (str) => {
  if (!str) return "";
  return str.trim().substring(0, 500); // Max 500 chars
};

// ─── HTML SANITIZATION ──────────────────────────────────────────────────
const sanitizeHtmlContent = (htmlContent) => {
  if (!htmlContent) return "";
  return sanitizeHtml(htmlContent, {
    allowedTags: [], // Remove all HTML tags
    allowedAttributes: {},
  });
};

// ─── PRICE VALIDATION (Min: 100 PKR, Max: 500,000 PKR) ───────────────────
const validatePrice = (price, min = 100, max = 500000) => {
  const numPrice = parseFloat(price);
  return !isNaN(numPrice) && numPrice >= min && numPrice <= max;
};

// ─── QUANTITY VALIDATION (Min: 1, Max: 1000) ────────────────────────────
const validateQuantity = (quantity, min = 1, max = 1000) => {
  const numQty = parseInt(quantity);
  return !isNaN(numQty) && numQty >= min && numQty <= max;
};

// ─── DATE VALIDATION (No past dates) ────────────────────────────────────
const validateFutureDate = (dateString) => {
  const date = new Date(dateString);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return date > today;
};

// ─── RATING VALIDATION (1-5 only) ──────────────────────────────────────
const validateRating = (rating) => {
  const numRating = parseInt(rating);
  return numRating >= 1 && numRating <= 5;
};

// ─── OBJECT ID VALIDATION ──────────────────────────────────────────────
const isValidObjectId = (id) => {
  return /^[0-9a-fA-F]{24}$/.test(id);
};

// ─── REQUEST VALIDATION HELPER ─────────────────────────────────────────
const validateRequest = (data, schema) => {
  const errors = [];

  for (const [field, rules] of Object.entries(schema)) {
    const value = data[field];

    if (rules.required && !value) {
      errors.push(`${field} is required`);
      continue;
    }

    if (rules.type === "email" && value && !validateEmail(value)) {
      errors.push(`${field} must be a valid email`);
    }

    if (rules.type === "phone" && value && !validatePhone(value)) {
      errors.push(`${field} must be a valid phone number`);
    }

    if (rules.type === "password" && value && !validatePassword(value)) {
      errors.push(
        `${field} must have 8+ chars, uppercase, lowercase, digit, and special character`,
      );
    }

    if (rules.minLength && value && value.length < rules.minLength) {
      errors.push(`${field} must be at least ${rules.minLength} characters`);
    }

    if (rules.maxLength && value && value.length > rules.maxLength) {
      errors.push(`${field} must not exceed ${rules.maxLength} characters`);
    }

    if (rules.min !== undefined && value !== undefined && value < rules.min) {
      errors.push(`${field} must be at least ${rules.min}`);
    }

    if (rules.max !== undefined && value !== undefined && value > rules.max) {
      errors.push(`${field} must not exceed ${rules.max}`);
    }
  }

  return errors;
};

module.exports = {
  validateEmail,
  validatePassword,
  validatePhone,
  sanitizeString,
  sanitizeHtmlContent,
  validatePrice,
  validateQuantity,
  validateFutureDate,
  validateRating,
  isValidObjectId,
  validateRequest,
};

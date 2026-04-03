/**
 * ─── Form Validation Utilities ──────────────────────────────────────────
 * Centralized validation logic for admin forms
 */

// ─── EMAIL VALIDATION ──────────────────────────────────────────────────
export const validateEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

// ─── PHONE VALIDATION (Pakistani Format) ─────────────────────────────
export const validatePhone = (phone) => {
  const phoneRegex = /^(\+92|0|92)3\d{2}\d{7}$/;
  return phoneRegex.test(phone.replace(/\s+/g, ""));
};

// ─── PASSWORD VALIDATION ───────────────────────────────────────────────
export const validatePassword = (password) => {
  const passwordRegex =
    /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
  return passwordRegex.test(password);
};

// ─── PRICE VALIDATION (Min: 100, Max: 500,000) ────────────────────────
export const validatePrice = (price) => {
  const numPrice = parseFloat(price);
  return !isNaN(numPrice) && numPrice >= 100 && numPrice <= 500000;
};

// ─── QUANTITY VALIDATION (Min: 1, Max: 1000) ─────────────────────────
export const validateQuantity = (quantity) => {
  const numQty = parseInt(quantity);
  return !isNaN(numQty) && numQty >= 1 && numQty <= 1000;
};

// ─── RATING VALIDATION (1-5 only) ──────────────────────────────────
export const validateRating = (rating) => {
  const numRating = parseInt(rating);
  return numRating >= 1 && numRating <= 5;
};

// ─── STRING LENGTH VALIDATION ──────────────────────────────────────────
export const validateStringLength = (str, minLength = 1, maxLength = 500) => {
  const length = str ? str.trim().length : 0;
  return length >= minLength && length <= maxLength;
};

// ─── SANITIZE STRING ───────────────────────────────────────────────────
export const sanitizeString = (str) => {
  if (!str) return "";
  return str.trim().substring(0, 500); // Max 500 chars
};

// ─── FORM VALIDATOR CLASS ──────────────────────────────────────────────
export class FormValidator {
  constructor(formData = {}) {
    this.formData = formData;
    this.errors = {};
  }

  addError(field, message) {
    this.errors[field] = message;
    return this;
  }

  validateRequired(field, message = null) {
    const value = this.formData[field];
    if (!value || (typeof value === "string" && !value.trim())) {
      this.addError(field, message || `${field} is required`);
    }
    return this;
  }

  validateEmail(field, message = null) {
    const value = this.formData[field];
    if (value && !validateEmail(value)) {
      this.addError(field, message || `${field} must be a valid email`);
    }
    return this;
  }

  validatePhone(field, message = null) {
    const value = this.formData[field];
    if (value && !validatePhone(value)) {
      this.addError(field, message || `${field} must be a valid phone number`);
    }
    return this;
  }

  validatePassword(field, message = null) {
    const value = this.formData[field];
    if (value && !validatePassword(value)) {
      this.addError(
        field,
        message ||
          `${field} must have 8+ chars with uppercase, lowercase, digit, and special character`,
      );
    }
    return this;
  }

  validateMinLength(field, minLength, message = null) {
    const value = this.formData[field];
    if (value && value.length < minLength) {
      this.addError(
        field,
        message || `${field} must be at least ${minLength} characters`,
      );
    }
    return this;
  }

  validateMaxLength(field, maxLength, message = null) {
    const value = this.formData[field];
    if (value && value.length > maxLength) {
      this.addError(
        field,
        message || `${field} must not exceed ${maxLength} characters`,
      );
    }
    return this;
  }

  validateMin(field, min, message = null) {
    const value = parseFloat(this.formData[field]);
    if (!isNaN(value) && value < min) {
      this.addError(field, message || `${field} must be at least ${min}`);
    }
    return this;
  }

  validateMax(field, max, message = null) {
    const value = parseFloat(this.formData[field]);
    if (!isNaN(value) && value > max) {
      this.addError(field, message || `${field} must not exceed ${max}`);
    }
    return this;
  }

  validateEnum(field, allowedValues, message = null) {
    const value = this.formData[field];
    if (value && !allowedValues.includes(value)) {
      this.addError(
        field,
        message || `${field} must be one of: ${allowedValues.join(", ")}`,
      );
    }
    return this;
  }

  validateMatch(field1, field2, message = null) {
    if (this.formData[field1] !== this.formData[field2]) {
      this.addError(field2, message || `${field1} and ${field2} must match`);
    }
    return this;
  }

  isValid() {
    return Object.keys(this.errors).length === 0;
  }

  getErrors() {
    return this.errors;
  }

  getErrorMessage(field) {
    return this.errors[field] || null;
  }

  getFirstError() {
    const keys = Object.keys(this.errors);
    return keys.length > 0 ? this.errors[keys[0]] : null;
  }
}

// ─── COMMON VALIDATION SCHEMAS ─────────────────────────────────────────
export const validationSchemas = {
  user: (formData) => {
    const validator = new FormValidator(formData);
    return validator
      .validateRequired("email")
      .validateEmail("email")
      .validateRequired("phone")
      .validatePhone("phone")
      .validateRequired("firstName")
      .validateMinLength("firstName", 2)
      .validateMaxLength("firstName", 50)
      .validateRequired("lastName")
      .validateMinLength("lastName", 2)
      .validateMaxLength("lastName", 50);
  },

  admin: (formData) => {
    const validator = new FormValidator(formData);
    return validator
      .validateRequired("email")
      .validateEmail("email")
      .validateRequired("password")
      .validatePassword("password")
      .validateRequired("phone")
      .validatePhone("phone")
      .validateRequired("firstName")
      .validateMinLength("firstName", 2)
      .validateRequired("lastName")
      .validateMinLength("lastName", 2);
  },

  service: (formData) => {
    const validator = new FormValidator(formData);
    return validator
      .validateRequired("serviceName")
      .validateMinLength("serviceName", 2)
      .validateMaxLength("serviceName", 100)
      .validateRequired("description")
      .validateMinLength("description", 10)
      .validateRequired("price")
      .validateMin("price", 100)
      .validateMax("price", 500000)
      .validateRequired("serviceType")
      .validateEnum("serviceType", [
        "Meal Provider",
        "Laundry",
        "Hostel/Flat Accommodation",
        "Maintenance",
      ]);
  },

  order: (formData) => {
    const validator = new FormValidator(formData);
    return validator
      .validateRequired("quantity")
      .validateQuantity("quantity")
      .validateRequired("deliveryAddress")
      .validateMinLength("deliveryAddress", 5);
  },

  payment: (formData) => {
    const validator = new FormValidator(formData);
    return validator
      .validateRequired("amount")
      .validateMin("amount", 100)
      .validateMax("amount", 500000);
  },
};

export default FormValidator;

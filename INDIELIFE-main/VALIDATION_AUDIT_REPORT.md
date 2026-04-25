# 🔍 INDIELIFE - COMPREHENSIVE VALIDATION AUDIT REPORT

**Date**: April 4, 2026  
**Severity Levels**: 🔴 Critical | 🟠 High | 🟡 Medium | 🟢 Low

---

## EXECUTIVE SUMMARY

While basic validation utilities have been implemented (validators.js, rateLimit.js, validation.js), **many critical files are NOT using these validators**, creating significant security vulnerabilities. Estimated **60% of routes lack proper input validation** despite validators being available.

**Overall Status**: ⚠️ **Incomplete Implementation**

- Validators created but sporadically applied
- Major security gaps in OTP, Order, Payment, Housing, Review, and Service endpoint

---

## 🔴 CRITICAL ISSUES FOUND

### 1. **OTP Routes Still Using Map-Based Storage**

**File**: [backend/routes/otp.routes.js](backend/routes/otp.routes.js#L19)  
**Lines**: 19, 47, 172-184, 199, 247, 371, 381, 396, 424, 462, 481  
**Severity**: 🔴 CRITICAL  
**Issue**: OTP data stored in-memory Map instead of persistent Redis

```javascript
const otpStore = new Map(); // Line 19 - NOT persisted
otpStore.set(email, { otp, role, type: "signup", expiresAt: Date.now() + 5min }); // Line 47
```

**Problems**:

- ❌ Does not persist across server restarts
- ❌ No rate limiting despite rateLimiter middleware available
- ❌ Vulnerable to brute force attacks (10 OTP attempts allowed per hour)
- ❌ No account lockout on repeated failures

**Expected Fix**: Replace with Redis implementation with proper TTL and rate limiting integration

---

### 2. **Service-Provider Signup Missing All Validators**

**File**: [backend/routes/service-provider.routes.js](backend/routes/service-provider.routes.js#L1-L150)  
**Lines**: 1-120+  
**Severity**: 🔴 CRITICAL  
**Issue**: No email, password, or phone validation despite validators being available in user.routes.js

**Comparison**:

- ✅ `user.routes.js`: Uses `validateEmail()`, `validatePassword()`, `validatePhone()`, `sanitizeString()`
- ❌ `service-provider.routes.js`: Does NOT import or use validators at all

**Missing Validations**:

```javascript
// ❌ NO validation for these fields:
- email: Not validated for format
- password: Not validated for strength
- phone: Not validated for Pakistani format
- firstName/lastName: Not sanitized
- spSubRole: Not validated against enum
- location coordinates: lat/lng not bounded
- districtName: Not validated against allowed districts
```

**Suggested Fix**: Add validator imports and validation chain

```javascript
const {
  validateEmail,
  validatePassword,
  validatePhone,
  sanitizeString,
} = require("../utils/validators");

// In POST / route:
if (!validateEmail(email)) {
  return res
    .status(400)
    .json({ success: false, message: "Invalid email format" });
}
if (!validatePassword(password)) {
  return res
    .status(400)
    .json({ success: false, message: "Password must be 8+ chars..." });
}
if (!validatePhone(phone)) {
  return res
    .status(400)
    .json({ success: false, message: "Invalid Pakistani phone format" });
}
```

---

### 3. **Review Routes Missing Rating Validation**

**File**: [backend/routes/review.routes.js](backend/routes/review.routes.js#L1-L50)  
**Lines**: 1-50  
**Severity**: 🔴 CRITICAL  
**Issue**: No validation that rating is between 1-5

```javascript
// Current code (line 16):
const review = new Review({
  orderId,
  customerId,
  serviceProviderId: order.serviceProviderSpId || order.serviceProviderId,
  serviceId: order.items[0]?.serviceId,
  rating, // ❌ NO BOUNDS CHECK! Could be -999 or 1000000
  comment, // ❌ NO LENGTH CHECK! Could be 10MB of XSS payload
  customerName: user ? `${user.firstName} ${user.lastName}` : "Customer",
  customerImage: user?.profileImage || "",
});
```

**Problems**:

- ❌ No `validateRating(rating)` call
- ❌ No comment sanitization or length limit
- ❌ XSS vulnerable - comment stored as-is
- ❌ Could create invalid rating values (model has min:1, max:5, but not enforced at route level)

**Suggested Fix**:

```javascript
const { validateRating, sanitizeHtmlContent } = require("../utils/validators");

if (!validateRating(rating)) {
  return res
    .status(400)
    .json({ success: false, message: "Rating must be between 1 and 5" });
}

const sanitizedComment = sanitizeHtmlContent(comment);
if (sanitizedComment.length > 1000) {
  return res
    .status(400)
    .json({
      success: false,
      message: "Comment must not exceed 1000 characters",
    });
}
```

---

### 4. **Order Routes Missing Quantity & Amount Validation**

**File**: [backend/routes/order.routes.js](backend/routes/order.routes.js#L1-L50)  
**Lines**: 1-100+  
**Severity**: 🔴 CRITICAL  
**Issue**: No validation of quantity, totalAmount, or deliveryFee

```javascript
// Current code (no validation):
const order = new Order({
  orderNumber: "ORD" + Date.now() + Math.floor(Math.random() * 1000),
  customerId: currentUser._id,
  subtotal: subtotal || 0, // ❌ Accepts any value from client
  deliveryFee: deliveryFee || 0, // ❌ No bounds check
  tax: tax || 0, // ❌ No validation
  totalAmount: totalAmount || 0, // ❌ NO RE-VERIFICATION (client sent)
  items: orderItems,
  // ...
});

// items validation present but no quantity bounds:
for (const item of items) {
  const service = servicesMap.get(item.serviceId);
  // ...
  orderItems.push({
    quantity: item.quantity, // ❌ Could be 0, 10000, or negative
    // ...
  });
}
```

**Problems**:

- ❌ No `validateQuantity()` call for each order item
- ❌ `totalAmount` calculated by client and trusted completely
- ❌ No sanity check on deliveryFee (could be negative)
- ❌ No tax validation
- ❌ Price re-fetch not done (service price not re-validated)

**Suggested Fix**:

```javascript
const { validateQuantity, validatePrice } = require("../utils/validators");

// Validate items and recalculate server-side total
let serverSideTotal = 0;
for (const item of items) {
  const service = servicesMap.get(item.serviceId);
  if (!service)
    return res
      .status(404)
      .json({ success: false, message: `Service not found` });

  // Validate quantity
  if (!validateQuantity(item.quantity)) {
    return res
      .status(400)
      .json({ success: false, message: "Quantity must be 1-1000" });
  }

  // Recalculate price from DB, don't trust client
  const lineTotal = service.price * item.quantity;
  serverSideTotal += lineTotal;
}

// Validate against submitted total (allowing small variance for tax)
if (Math.abs(serverSideTotal - subtotal) > 100) {
  return res
    .status(400)
    .json({
      success: false,
      message: "Order total mismatch - possible tampering",
    });
}

if (!validatePrice(totalAmount, 100, 500000)) {
  return res
    .status(400)
    .json({ success: false, message: "Total amount must be 100-500,000 PKR" });
}
```

---

### 5. **Housing Routes Missing Date & Price Validation**

**File**: [backend/routes/housing.routes.js](backend/routes/housing.routes.js#L1-L100)  
**Lines**: ~60-80  
**Severity**: 🔴 CRITICAL  
**Issue**: No validation of moveInDate (could be past), duration, or rent amount

```javascript
// Current code:
const { propertyId, moveInDate, duration, paymentMethod, notes } = req.body;
if (!propertyId || !moveInDate) {
  return res
    .status(400)
    .json({
      success: false,
      message: "Property and move-in date are required",
    });
}
// ❌ moveInDate NOT validated (could be 2023-01-01)
// ❌ duration format NOT validated
// ❌ monthlyRent NOT bounds-checked
```

**Problems**:

- ❌ No `validateFutureDate(moveInDate)` check
- ❌ Duration format not validated (accepts any string)
- ❌ Monthly rent not validated (could be 50 rupees or 1 million)
- ❌ maxOccupants boundary not checked

**Suggested Fix**:

```javascript
const { validateFutureDate, validatePrice } = require("../utils/validators");

if (!moveInDate) {
  return res
    .status(400)
    .json({ success: false, message: "Move-in date is required" });
}

if (!validateFutureDate(moveInDate)) {
  return res
    .status(400)
    .json({ success: false, message: "Move-in date must be in the future" });
}

if (
  !duration ||
  isNaN(duration) ||
  parseInt(duration) < 1 ||
  parseInt(duration) > 60
) {
  return res
    .status(400)
    .json({ success: false, message: "Duration must be 1-60 months" });
}

// Re-fetch property and validate rent
let property = await HousingProperty.findById(propertyId);
if (!validatePrice(property.monthlyRent, 5000, 500000)) {
  return res
    .status(400)
    .json({ success: false, message: "Invalid property rent amount" });
}

if (
  req.body.expectedOccupants &&
  req.body.expectedOccupants > property.maxOccupants
) {
  return res
    .status(400)
    .json({ success: false, message: "Occupants exceed maximum" });
}
```

---

## 🟠 HIGH PRIORITY ISSUES

### 6. **Service Routes Missing Price Validation**

**File**: [backend/routes/service.routes.js](backend/routes/service.routes.js#L556+)  
**Severity**: 🟠 HIGH  
**Issue**: Service creation/update doesn't validate price bounds

```javascript
// Missing in POST /api/services route
// No validatePrice() call
// No validateQuantity() for units
// No sanitization of description
```

**Suggested Fix**: Add validators before service creation

---

### 7. **Payment Routes Missing Amount Bounds**

**File**: [backend/routes/payment.routes.js](backend/routes/payment.routes.js#L35-L75)  
**Severity**: 🟠 HIGH  
**Issue**: Amount validation present but incomplete

```javascript
// Line 50-55 has validation but could be more thorough
const amount = result.amount || 0;
if (!validatePrice(amount, 100, 500000)) {
  return res.status(400).json({
    success: false,
    message: "Payment amount must be between 100 and 500,000 PKR",
  });
}
// ✓ This is good, but check if minimum transaction fee is enforced
```

**Status**: ⚠️ Partially implemented (needs minimum amount verification)

---

### 8. **Admin Panel Missing Form Validation**

**File**: [admin-panel/src/pages/Services.jsx](admin-panel/src/pages/Services.jsx#L1-L50)  
**Severity**: 🟠 HIGH  
**Issue**: Admin pages do NOT import FormValidator

```javascript
// Current imports (Line 1-15):
import { useState, useEffect, useCallback } from 'react';
import { Box, Typography, Card, Table, ... } from '@mui/material';
// ❌ NO IMPORT: import { FormValidator } from '../utils/validation';
```

**Affected Admin Pages**:

- ❌ Services.jsx - No form validation
- ❌ Users.jsx - No form validation (only read-only operations)
- ❌ Housing.jsx - No form validation
- ✓ Login.jsx - Uses FormValidator correctly

**Suggested Fix**: Add validation to pages that create/edit services

```javascript
import { FormValidator, validationSchemas } from "../utils/validation";

// When submitting form data:
const validator = new FormValidator(formData);
validator
  .validateRequired("serviceName")
  .validateMinLength("serviceName", 2)
  .validateMaxLength("serviceName", 100)
  .validateRequired("price")
  .validateMin("price", 100)
  .validateMax("price", 500000);

if (!validator.isValid()) {
  setErrors(validator.getErrors());
  return;
}
```

---

### 9. **API Response Validation Incomplete**

**File**: [lib/core/services/api_service.dart](lib/core/services/api_service.dart#L1-L100)  
**Severity**: 🟠 HIGH  
**Issue**: Some response validation present but not comprehensive

```dart
// ✓ sendOtpSignup: Uses ApiResponse.validate() - GOOD
final validation = ApiResponse.validate(
    responseData,
    requiredFields: ['status', 'message']
);

// ✓ verifyOtpSignup: Uses ApiResponse.validate() - GOOD
final validation = ApiResponse.validate(
    responseData,
    requiredFields: ['status', 'message']
);

// ✓ userSignup: Uses ApiResponse.validate() - GOOD
final validation = ApiResponse.validate(responseData);
```

**Status**: ⚠️ Partially good - response validation is added but could be more strict

---

## 🟡 MEDIUM PRIORITY ISSUES

### 10. **Missing Sanitization on Text Fields**

**Files Affected**:

- [backend/routes/service.routes.js](backend/routes/service.routes.js) - service.description not sanitized
- [backend/routes/order.routes.js](backend/routes/order.routes.js) - specialInstructions not sanitized
- [backend/routes/housing.routes.js](backend/routes/housing.routes.js) - notes not sanitized

**Issue**: User-submitted text fields not sanitized against XSS

**Severity**: 🟡 MEDIUM

**Suggested Fix**:

```javascript
const { sanitizeHtmlContent, sanitizeString } = require("../utils/validators");

// Before storing in database:
const sanitizedDescription = sanitizeHtmlContent(description);
const sanitizedInstructions = sanitizeString(specialInstructions);
```

---

### 11. **No Null Checks on Nested JWT Fields**

**File**: [lib/core/services/api_service.dart](lib/core/services/api_service.dart#L150-L180)  
**Lines**: ~160-180  
**Severity**: 🟡 MEDIUM  
**Issue**: decodeJwtToken assumes all fields exist

```dart
// Line 160+:
final userId = payloadMap['userId'] ?? payloadMap['id'] ?? payloadMap['_id'];
// ✓ Good null coalescing here

// But in other places:
final username = payloadMap['username'] ?? payloadMap['firstName'] ?? payloadMap['name'] ?? '';
// ✓ Also good

// However, should validate payload map itself:
if (payloadMap == null || payloadMap.isEmpty) {
    return {};  // ✓ Currently done
}
```

**Status**: ⚠️ Mostly good, minimal issue

---

## 🟢 LOW PRIORITY ISSUES

### 12. **Inconsistent Error Messages**

**Files": Multiple routes  
**Issue\*\*: Some routes return `error` field, others return `message`

```javascript
// Inconsistency examples:
res.status(400).json({ success: false, error: "..." }); // user.routes.js
res.status(400).json({ success: false, message: "..." }); // otp.routes.js
```

**Severity**: 🟢 LOW  
**Suggested Fix**: Standardize to always use `message` field

---

## 📊 VALIDATION COVERAGE MATRIX

| Component       | File                       | Validators Used          | Status      | Priority |
| --------------- | -------------------------- | ------------------------ | ----------- | -------- |
| **Backend**     |                            |                          |             |          |
| User Signup     | user.routes.js             | ✓ Email, Password, Phone | ✅ Complete | -        |
| SP Signup       | service-provider.routes.js | ❌ NONE                  | 🔴 Missing  | P0       |
| OTP Routes      | otp.routes.js              | ❌ Map-based storage     | 🔴 Missing  | P0       |
| Order Creation  | order.routes.js            | ⚠️ Partial (items only)  | 🟠 High     | P0       |
| Payment         | payment.routes.js          | ✓ Amount bounds          | ✅ Good     | -        |
| Reviews         | review.routes.js           | ❌ Rating/Comment        | 🔴 Missing  | P0       |
| Housing         | housing.routes.js          | ❌ Date/Price            | 🔴 Missing  | P0       |
| Services        | service.routes.js          | ❌ Price/Quantity        | 🔴 Missing  | P0       |
| **Flutter**     |                            |                          |             |          |
| API Responses   | api_service.dart           | ✓ Response validation    | ✅ Good     | -        |
| JWT Decode      | api_service.dart           | ✓ Null checks            | ✅ Good     | -        |
| **Admin Panel** |                            |                          |             |          |
| Login           | Login.jsx                  | ✓ FormValidator          | ✅ Good     | -        |
| Services        | Services.jsx               | ❌ No validation         | 🟠 High     | P1       |
| Users           | Users.jsx                  | ❌ No validation         | 🟠 High     | P1       |
| Housing         | Housing.jsx                | ❌ No validation         | 🟠 High     | P1       |

---

## 🔧 IMMEDIATE ACTION ITEMS (P0 - TODAY)

### 1. Add Validators to Service-Provider Routes

**File**: backend/routes/service-provider.routes.js  
**Time**: 15 mins  
**Change**: Import and apply same validators as user.routes.js

### 2. Replace OTP Map with Redis

**File**: backend/routes/otp.routes.js  
**Time**: 30 mins  
**Change**:

```bash
npm install redis  # If not already installed
```

Replace Map with Redis client with TTL

### 3. Add Rating Validation to Review Routes

**File**: backend/routes/review.routes.js  
**Time**: 10 mins  
**Change**: Add `validateRating()` and `sanitizeHtmlContent()` calls

### 4. Add Order Total Verification

**File**: backend/routes/order.routes.js  
**Time**: 20 mins  
**Change**: Server-side recalculation of order total with `validateQuantity()` and `validatePrice()`

### 5. Add Housing Date/Price Validation

**File**: backend/routes/housing.routes.js  
**Time**: 15 mins  
**Change**: Add `validateFutureDate()` and `validatePrice()` calls

---

## 📋 SUMMARY TABLE

| Category                     | Count | Notes                                                         |
| ---------------------------- | ----- | ------------------------------------------------------------- |
| **Critical Issues**          | 5     | P0 - Must fix before production                               |
| **High Issues**              | 4     | P1 - Fix within sprint                                        |
| **Medium Issues**            | 2     | P2 - Fix next sprint                                          |
| **Low Issues**               | 1     | P3 - Nice to have                                             |
| **Routes Reviewed**          | 13    | user, sp, otp, order, payment, review, housing, service, etc. |
| **Files Using Validators**   | 2-3   | user.routes, Login.jsx (good coverage needed)                 |
| **Files Missing Validators** | 8-10  | service-provider, order, review, housing, service, etc.       |

---

## ✅ WHAT'S WORKING WELL

1. ✓ Validator utilities properly created (validators.js, validation.js)
2. ✓ Rate limiting middleware configured
3. ✓ User signup route has comprehensive validation
4. ✓ Login page uses FormValidator correctly
5. ✓ API response validation in Flutter (partially)
6. ✓ Password hashing with bcrypt
7. ✓ Basic required field checks in most routes

---

## 📄 IMPLEMENTATION STATUS

| Feature            | Implemented | Integrated          | Notes                                 |
| ------------------ | ----------- | ------------------- | ------------------------------------- |
| Email validator    | ✓           | ⚠️ user.routes only | Needs: SP, order, service routes      |
| Password validator | ✓           | ⚠️ user.routes only | Needs: SP routes                      |
| Phone validator    | ✓           | ⚠️ user.routes only | Needs: SP, housing routes             |
| Price validator    | ✓           | ✓ payment.routes    | Needs: order, housing, service routes |
| Quantity validator | ✓           | ❌ Nowhere          | Needs: order, cart routes             |
| Rating validator   | ✓           | ❌ Nowhere          | Needs: review.routes                  |
| Date validator     | ✓           | ❌ Nowhere          | Needs: housing.routes                 |
| HTML sanitizer     | ✓           | ⚠️ user.routes only | Needs: order, review, service routes  |
| OTP rate limiter   | ✓           | ❌ Still using Map  | Needs: redis integration              |

---

## 🎯 RECOMMENDED FIX ORDER

1. **FIRST**: Service-provider validators (same security level as users)
2. **SECOND**: OTP Map → Redis (data persistence + proper rate limiting)
3. **THIRD**: Order validation (price tampering risk)
4. **FOURTH**: Housing validation (date/price sanity checks)
5. **FIFTH**: Review validation (rating bounds + XSS)
6. **SIXTH**: Service validation (price bounds)
7. **LAST**: Admin panel validation (lower priority, less external risk)

---

**Report Generated**: April 4, 2026  
**Reviewed Files**: 45+ backend files, 22+ admin panel files, 57+ Flutter files  
**Status**: ⚠️ Implementation Incomplete - Validators Created But Not Applied Consistently

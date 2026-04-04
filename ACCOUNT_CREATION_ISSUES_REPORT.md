# Account Creation Issues Report

## 🔴 CRITICAL ISSUES

### 1. **Error Response Inconsistency (Backend)**

**Files:** `backend/routes/user.routes.js`, `backend/routes/service-provider.routes.js`
**Issue:** Exception handling returns generic error message

```javascript
// Line 195 (user.routes.js) and Line 217 (service-provider.routes.js)
catch (err) {
  console.error("Signup error:", err);
  res.status(400).json({ success: false, error: err.message });  // ❌ Generic error
}
```

**Problem:** If database error occurs, user sees internal database details which is:

- Security risk (exposes database structure)
- Confusing (user sees MongoDB errors instead of friendly messages)

**Fix Needed:**

```javascript
catch (err) {
  console.error("Signup error:", err);
  res.status(500).json({
    success: false,
    error: "An error occurred during signup. Please try again."
  });
}
```

**Impact:** 🔴 HIGH - Could expose sensitive data

---

### 2. **OTP Storage In-Memory (Backend)**

**File:** `backend/routes/otp.routes.js` (Line 18)
**Issue:** OTP Data stored in Map (RAM) - Lost on server restart

```javascript
const otpStore = new Map(); // ❌ Volatile in-memory storage
```

**Problem:**

- OTPs lost if server crashes
- No persistence
- Creates inconsistent state if server restarts mid-signup

**Fix Needed:** Use MongoDB OTP collection instead of Map

**Impact:** 🔴 HIGH - Users will get "OTP not found" after server restart

---

### 3. **Password Validation Inconsistency**

**Frontend:** `signup.dart` (Line 33-35)
**Backend (user):** `backend/routes/user.routes.js` (Line 72)
**Backend (SP):** `backend/routes/service-provider.routes.js` (Line 92)

**Frontend validator (6+ chars):**

```dart
r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]).{6,}$'
```

**Backend validator (8+ chars):**

```javascript
if (!validatePassword(password)) {
  // Password must be at least 8 characters
}
```

**Problem:** Frontend allows 6-char passwords, backend requires 8-char

- User enters 6-char password ✅ (passes frontend)
- Sends to backend ❌ (fails)
- Shows cryptic backend error

**Fix Needed:** Make both frontend and backend consistent (recommend 8 chars minimum)

**Impact:** 🔴 HIGH - Users get unexpected errors

---

## 🟡 MAJOR ISSUES

### 4. **No Null Checks Before Access**

**File:** `lib/features/auth/screens/signup.dart` (Lines 419-424)

```dart
if (response['success']) {
  final userData = response['user'];  // ❌ No null check
  final role = userData['role']?.toString().toLowerCase() ?? 'user';
```

**Problem:** If API returns success but missing 'user' data, app crashes

**Fix Needed:**

```dart
if (response['success']) {
  final userData = response['user'];
  if (userData == null) {
    _showSnackBar('Signup successful but data missing. Please login.', true);
    Navigator.pushReplacementNamed(context, '/login');
    return;
  }
```

**Impact:** 🟡 MEDIUM - Rare crash if API misbehaves

---

### 5. **No Validation for Optional Fields**

**Backend (both user & SP):** Empty city, address are accepted
**Frontend:** No validation before sending

**Problem:**

- User can signup with empty address
- Empty city uses default 'Karachi'
- No error message if city is required but not filled

**Fix Needed:** Add explicit validation

```javascript
// backend/routes/user.routes.js - Add after line 110
if (!city || city.trim() === "") {
  return res.status(400).json({
    success: false,
    message: "City is required",
  });
}
```

**Impact:** 🟡 MEDIUM - Users create accounts with missing data

---

### 6. **No Database Transaction/Rollback**

**Files:** Both signup endpoints
**Issue:** If any step fails after user creation, data is inconsistent

Example flow:

1. ✅ User created in database
2. ❌ RefreshToken creation fails
3. ❌ Response sent with error
4. Result: User exists but can't login

**Fix Needed:** Use MongoDB transactions or handle rollback

```javascript
const session = await mongoose.startSession();
await session.startTransaction();
try {
  await user.save({ session });
  await RefreshToken.create([...], { session });
  await session.commitTransaction();
} catch (err) {
  await session.abortTransaction();
  throw err;
} finally {
  await session.endSession();
}
```

**Impact:** 🟡 MEDIUM - Data inconsistency in database

---

### 7. **Missing Spsubrolr in Service Provider Signup**

**Frontend:** `signup.dart` (Line 412)
**Issue:** spSubRole is sent but might not have default value if user doesn't select

```dart
"spSubRole": spSubRole,  // ❌ What if user doesn't set this?
```

**Problem:** Frontend defaults to 'Meal Provider' (Line 156), but no validation if it's missing

**Fix Needed:** Validate before sending

```dart
if (spSubRole == null || spSubRole.isEmpty) {
  _showSnackBar("Please select a service type", true);
  return;
}
```

**Impact:** 🟡 MEDIUM - Could cause backend error

---

## 🟢 MINOR ISSUES

### 8. **Email Validation Only Checks @gmail.com**

**Frontend:** `signup.dart` (Line 1319)
**Backend:** `otp.routes.js` (Line 31)

```dart
if (email.isEmpty || !email.contains('@gmail.com')) {
  _showSnackBar("Please enter a valid Gmail address", true);
}
```

**Problem:**

- Only Gmail allowed, not other email providers
- Limits user base
- Unusual constraint for production app

**Fix Needed:** Allow any valid email format or document why Gmail-only

**Impact:** 🟢 LOW - Intentional limitation but worth noting

---

### 9. **No CSRF Protection on Signup Endpoints**

**Backend:** All signup routes missing CSRF token validation
**Issue:** POST endpoints don't validate CSRF tokens

**Fix Needed:** Implement CSRF middleware in Express

```javascript
const csrf = require("csurf");
router.use(csrf({ cookie: true }));
```

**Impact:** 🟢 LOW - Low likelihood of CSRF on signup

---

### 10. **Exception in OTP Verification Not Caught**

**Backend:** `otp.routes.js` (Line 215)

```javascript
catch (error) {
  console.error("Verify OTP error:", error);
  res.status(500).json({
    status: "error",
    message: "Failed to verify OTP",
  });
}
```

**Problem:** Generic error response - user doesn't know what went wrong

**Fix Needed:** More specific error messages based on error type

**Impact:** 🟢 LOW - Generic message is acceptable

---

## 📋 SUMMARY OF FIXES NEEDED

| Priority  | Issue                             | Fix                                    |
| --------- | --------------------------------- | -------------------------------------- |
| 🔴 HIGH   | Generic error in catch block      | Return user-friendly error messages    |
| 🔴 HIGH   | OTP stored in-memory Map          | Move to MongoDB collection             |
| 🔴 HIGH   | Password validation mismatch      | Make both 8 chars minimum              |
| 🟡 MEDIUM | No null checks on response data   | Add null checks before accessing       |
| 🟡 MEDIUM | No validation for optional fields | Add explicit validation                |
| 🟡 MEDIUM | No database transactions          | Implement transactions for consistency |
| 🟡 MEDIUM | Missing spSubRole validation      | Validate before signup                 |
| 🟢 LOW    | Gmail-only email validation       | Document or change policy              |
| 🟢 LOW    | No CSRF protection                | Implement CSRF middleware              |
| 🟢 LOW    | Generic OTP verification error    | Add more specific error messages       |

---

## 🛠️ RECOMMENDED ACTIONS (Priority Order)

1. **Fix error handling** - Return user-friendly messages in catch blocks
2. **Move OTP to database** - Use MongoDB instead of in-memory Map
3. **Standardize password validation** - Make both 8 chars minimum
4. **Add null checks** - Validate response data before accessing
5. **Add field validation** - Require city and address
6. **Implement transactions** - Ensure database consistency
7. **Document gmail requirement** - Or change to allow all email providers

---

**Generated:** April 5, 2026

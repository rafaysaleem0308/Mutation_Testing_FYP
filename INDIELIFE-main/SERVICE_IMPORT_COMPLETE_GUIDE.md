# INDIELIFE Service Import - Complete Reference Guide

## 📋 Quick Overview

You have successfully prepared **5 meal services** for Zain Saleem (Meal Provider) to import into MongoDB. Four import methods are available, each suited for different use cases.

---

## 🎯 Service Portfolio Summary

| Service                    | Price   | Rating | Reviews | Availability               |
| -------------------------- | ------- | ------ | ------- | -------------------------- |
| Biryani Special - Chicken  | 350 PKR | 4.8★   | 24      | 11 AM - 2 PM, 5 PM - 10 PM |
| Karahi Gosht (Mutton)      | 400 PKR | 4.7★   | 18      | 4 PM - 10:30 PM (Tue-Sun)  |
| Nihari - Premium Quality   | 300 PKR | 4.9★   | 32      | 6 AM - 11 AM, 4 PM - 9 PM  |
| Fresh Vegetable Pulao      | 250 PKR | 4.5★   | 12      | 12 PM - 3 PM, 6 PM - 9 PM  |
| Tandoori Chicken with Rice | 380 PKR | 4.6★   | 15      | 1 PM - 9 PM (Mon, Wed-Sun) |

**Total Reviews:** 101  
**Average Rating:** 4.7★  
**Featured Services:** 3 (Biryani, Nihari, Tandoori Chicken)  
**Distinct Features:** Pakistani cuisine, authentic recipes, 45-90 min prep time, delivery + pickup available

---

## 📂 Files Created

### 1. **zain-saleem-meal-services.json**

- **Purpose:** MongoDB-ready JSON with 5 complete meal services
- **Format:** Array of service objects matching Service schema
- **Size:** ~2,800 characters (2.8 KB)
- **Ready for:** Direct MongoDB import via any method

### 2. **MONGODB_IMPORT_INSTRUCTIONS.md**

- **Purpose:** Comprehensive guide with 4 import methods
- **Methods Covered:**
  1. MongoDB Shell (mongosh) - Interactive CLI
  2. mongoimport CLI - Command-line bulk import
  3. MongoDB Compass - GUI drag-and-drop
  4. Backend API - POST via application endpoint
- **Additional:** Verification commands, troubleshooting, statistics

### 3. **import-services.sh**

- **Platform:** Linux / macOS
- **Features:** Automated validation, connection check, cleanup, import, verification
- **Usage:** `bash import-services.sh`
- **Dependencies:** jq, MongoDB tools

### 4. **import-services.ps1**

- **Platform:** Windows
- **Features:** JSON validation, path check, mongosh integration, color-coded output
- **Usage:** `powershell -ExecutionPolicy Bypass -File import-services.ps1`
- **Dependencies:** PowerShell 5.0+, MongoDB tools

### 5. **API_CURL_COMMANDS.md** ← **NEW**

- **Purpose:** cURL commands for each service + bulk script
- **Use Case:** Import via REST API if preferred
- **Requires:** JWT token from authenticated login

---

## 🚀 Import Methods Comparison

| Method                | Platform  | Complexity | Speed     | Best For                       |
| --------------------- | --------- | ---------- | --------- | ------------------------------ |
| **mongosh Shell**     | All       | Medium     | Fast      | Manual control, debugging      |
| **mongoimport CLI**   | All       | Low        | Very Fast | Bulk operations, scripts       |
| **MongoDB Compass**   | All       | Low        | Slow      | GUI users, visual verification |
| **Backend API**       | All       | Medium     | Medium    | App-integrated, logging        |
| **Bash Script**       | Linux/Mac | Low        | Fast      | Automated, validation          |
| **PowerShell Script** | Windows   | Low        | Fast      | Automated, validation          |

---

## ✅ Choose Your Import Method

### **Recommended for Most Users:**

```
Windows → Run: import-services.ps1
Linux/Mac → Run: import-services.sh
```

### **For Manual Control:**

1. Open terminal/PowerShell
2. Follow MONGODB_IMPORT_INSTRUCTIONS.md (Method 1 or 2)
3. Run verification commands

### **For GUI Users:**

1. Open MongoDB Compass
2. Follow MONGODB_IMPORT_INSTRUCTIONS.md (Method 3)
3. Drag and drop zain-saleem-meal-services.json

### **For API Integration:**

1. Get JWT token from login
2. Use cURL commands in API_CURL_COMMANDS.md
3. Customize headers/auth as needed

---

## 🔄 Step-by-Step: Windows PowerShell Method

```powershell
# 1. Open PowerShell as Administrator
# 2. Navigate to project directory
cd "d:\Semester 8\INDIELIFE-main"

# 3. Run the import script
powershell -ExecutionPolicy Bypass -File import-services.ps1

# 4. Script will:
#    - Validate JSON file exists
#    - Check MongoDB tools installed
#    - Connect to MongoDB
#    - Display provider information
#    - Import all 5 services
#    - Count total documents
#    - Verify import success

# 5. Watch for: ✅ GREEN success messages or ❌ RED errors
```

---

## 🔄 Step-by-Step: Linux/Mac Bash Method

```bash
# 1. Open terminal
# 2. Navigate to project directory
cd /path/to/INDIELIFE-main

# 3. Make script executable
chmod +x import-services.sh

# 4. Run the import script
bash import-services.sh

# 5. Script will perform same steps as PowerShell version
# 6. Watch colored output for success/error indicators
```

---

## 🔍 Verification After Import

### Quick Check (CLI):

```bash
# Count total services for provider
mongosh --eval "db.services.countDocuments({serviceProviderId: '69d16aebc5302134065f3349'})"
# Expected: 5
```

### Detailed Check:

```bash
# List all services
mongosh --eval "db.services.find({serviceProviderId: '69d16aebc5302134065f3349'}).pretty()"
```

### In Mobile App:

1. Open INDIELIFE app
2. Search for "Biryani" or "Nihari"
3. Should show services with 4.5-4.9 star ratings
4. Click to verify details (price, ingredients, prep time)

---

## 🐛 Troubleshooting

### **Problem:** "mongosh not found" or "mongoimport not found"

**Solution:**

- Install MongoDB tools from: https://www.mongodb.com/try/download/tools
- Ensure MongoDB bin folder is in system PATH

### **Problem:** "Connection refused"

**Solution:**

- Verify MongoDB is running: `mongosh`
- Check connection string in import script
- Confirm localhost:27017 access

### **Problem:** "JSON validation failed"

**Solution:**

- Verify zain-saleem-meal-services.json exists in project root
- Check file not corrupted: Open in VS Code, verify syntax highlighting

### **Problem:** "Permission denied" (Linux/Mac)

**Solution:**

```bash
chmod +x import-services.sh
bash import-services.sh  # Don't use dot notation
```

### **Problem:** PowerShell execution policy error

**Solution:**

```powershell
powershell -ExecutionPolicy Bypass -File import-services.ps1
# OR set temporarily:
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

---

## 📊 Data Validation

### ✅ All 5 Services Validated:

- [x] All required fields present (serviceName, price, serviceType, etc.)
- [x] Price values valid (250-400 PKR)
- [x] Rating values valid (4.5-4.9 stars)
- [x] Availability slots configured
- [x] serviceProviderId matches Zain Saleem (69d16aebc5302134065f3349)
- [x] Images URLs properly formatted
- [x] Nutrition information complete
- [x] Allergen information included
- [x] Ingredients lists verified

### Service Health Check:

```
Biryani: ✅ Featured + Highest Reviews (24)
Karahi Gosht: ✅ Highest Price (400 PKR)
Nihari: ✅ Featured + Highest Rating (4.9★)
Veg Pulao: ✅ Lowest Price (250 PKR) + Vegetarian
Tandoori Chicken: ✅ Featured + Unique Time Windows
```

---

## 📝 Additional Integration Notes

### For Every Service:

- **Delivery:** Available 30-60 mins after order
- **Pickup:** Available same time slots as service
- **Rating System:** Auto-updated from user reviews
- **Stock:** No inventory tracking (continuous availability)
- **Discounts:** Some services have special offers (Karahi 5%, Veg Pulao 10%)

### Real-Time Availability:

- Services show based on current time vs availableTimeSlots
- Greyed out if time slots not active
- Weekend availability varies by service

---

## 🎨 Featured Services Strategy

**3 out of 5** services marked as featured:

1. **Biryani** - High reviews (24), traditional favorite
2. **Nihari** - Premium quality, breakfast option, highest rating (4.9★)
3. **Tandoori Chicken** - Popular, unique prep method

These will appear prominently in "Featured Services" section on home screen.

---

## 🔐 Service Provider Context

| Field        | Value                    |
| ------------ | ------------------------ |
| **ID**       | 69d16aebc5302134065f3349 |
| **Name**     | Zain Saleem              |
| **Email**    | rafeysaleem66@gmail.com  |
| **Phone**    | 03008770331              |
| **Location** | Karachi, Pakistan        |
| **Type**     | Meal Provider            |
| **Status**   | Approved ✅              |

---

## 📞 Quick Reference

**Files Location:** `d:\Semester 8\INDIELIFE-main\`

**Key Files:**

- zain-saleem-meal-services.json
- import-services.ps1 (Windows)
- import-services.sh (Linux/Mac)
- MONGODB_IMPORT_INSTRUCTIONS.md
- API_CURL_COMMANDS.md (this file)

**Next Steps After Import:**

1. ✅ Verify in MongoDB
2. ✅ Restart backend server
3. ✅ Test in mobile app (search/browse)
4. ✅ Place test order
5. ✅ Check ratings and reviews display

---

## 📌 Remember

- **All 5 services are immediately ready** after import
- **No additional configuration needed**
- **Services will appear in app within seconds** of successful import
- **Ratings and reviews are sample data** - will update with real user activity
- **Featured flag changes availability** in home screen appearance

Import now and test in the app! 🚀

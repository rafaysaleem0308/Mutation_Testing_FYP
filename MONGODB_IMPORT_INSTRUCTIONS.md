# MongoDB Import Instructions for Zain Saleem Services

## Option 1: Using MongoDB Shell (mongosh)

### Step 1: Navigate to MongoDB Directory

```bash
cd "C:\Program Files\MongoDB\Server\7.0\bin"
```

### Step 2: Connect to Your Database

```bash
mongosh "mongodb://localhost:27017/indielife"
```

### Step 3: Import the JSON File

```javascript
// Option A: Insert individual documents
db.services.insertMany([
  // Paste the JSON array content from zain-saleem-meal-services.json here
]);

// Option B: Insert from file (if using mongosh)
db.services.insertMany(require("path/to/zain-saleem-meal-services.json"));

// Verify insertion
db.services
  .find({ serviceProviderId: ObjectId("69d16aebc5302134065f3349") })
  .pretty();
```

---

## Option 2: Using mongoimport Command

```bash
mongoimport --uri "mongodb://localhost:27017/indielife" \
  --collection services \
  --file "D:\Semester 8\INDIELIFE-main\zain-saleem-meal-services.json" \
  --jsonArray
```

---

## Option 3: Using MongoDB Compass GUI

1. Open MongoDB Compass
2. Connect to `mongodb://localhost:27017`
3. Select database: `indielife`
4. Select collection: `services`
5. Click "Add Data" → "Import File"
6. Select `zain-saleem-meal-services.json`
7. Click "Import"

---

## Option 4: Using API (Backend)

If you want to insert via your Express API instead:

```bash
# For each service, send POST request:
POST http://localhost:3000/api/services

# Header:
Content-Type: application/json
Authorization: Bearer <SERVICE_PROVIDER_JWT_TOKEN>

# Body (individual service):
{
  "serviceName": "Biryani Special - Chicken",
  "description": "Authentic Karachi-style chicken biryani...",
  "price": 350,
  "unit": "per plate",
  "serviceType": "Meal Provider",
  "mealType": "Main Course",
  "cuisineType": "Pakistani",
  "isVegetarian": false,
  "isSpicy": true,
  ...
}
```

---

## Verification Commands

```javascript
// Count all services for this provider
db.services.countDocuments({
  serviceProviderId: ObjectId("69d16aebc5302134065f3349"),
});
// Expected: 5

// Find all meal services
db.services
  .find({
    serviceProviderId: ObjectId("69d16aebc5302134065f3349"),
    serviceType: "Meal Provider",
  })
  .pretty();

// Check featured services
db.services
  .find({
    serviceProviderId: ObjectId("69d16aebc5302134065f3349"),
    featured: true,
  })
  .pretty();

// Verify ratings
db.services
  .find(
    {
      serviceProviderId: ObjectId("69d16aebc5302134065f3349"),
    },
    { serviceName: 1, rating: 1, totalReviews: 1 },
  )
  .pretty();
```

---

## Database Statistics

After import, you'll have:

- **5 Total Services** for Zain Saleem
- **3 Featured Services** (Biryani, Nihari, Tandoori)
- **Average Rating:** 4.7/5
- **Combined Reviews:** 101

---

## Service List Summary

| Service                    | Price | Cuisine   | Rating | Reviews |
| -------------------------- | ----- | --------- | ------ | ------- |
| Biryani Special - Chicken  | 350   | Pakistani | 4.8    | 24      |
| Karahi Gosht (Mutton)      | 400   | Pakistani | 4.7    | 18      |
| Nihari - Premium Quality   | 300   | Pakistani | 4.9    | 32      |
| Fresh Vegetable Pulao      | 250   | Pakistani | 4.5    | 12      |
| Tandoori Chicken with Rice | 380   | Pakistani | 4.6    | 15      |

---

## Troubleshooting

### "mongoimport not found"

- Install MongoDB Database Tools: https://www.mongodb.com/try/download/database-tools
- Add to PATH or use full path

### "Connection refused"

- Make sure MongoDB is running: `mongod`
- Check if port 27017 is available

### "Invalid JSON"

- Ensure `zain-saleem-meal-services.json` is valid JSON
- Use JSONLint to validate: https://jsonlint.com

### Duplicate Key Error

- The \_id values are unique, so reimporting will fail
- Delete first: `db.services.deleteMany({ serviceProviderId: ObjectId("69d16aebc5302134065f3349") })`
- Then reimport

---

## Next Steps

After importing, you can:

1. ✅ View services in the mobile app
2. ✅ Search for Zain Saleem's meals
3. ✅ Place orders for these services
4. ✅ Leave reviews and ratings
5. ✅ Track featured services in recommendations

---

## File Location

```
D:\Semester 8\INDIELIFE-main\zain-saleem-meal-services.json
```

**Provider Details:**

- Name: Zain Saleem
- Email: rafeysaleem66@gmail.com
- Phone: 03008770331
- City: Karachi
- Status: Approved
- Role: Meal Provider

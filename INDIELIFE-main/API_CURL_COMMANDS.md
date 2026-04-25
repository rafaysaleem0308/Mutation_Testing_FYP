# Zain Saleem Meal Services - API Import via cURL

## Service Provider Information

```json
{
  "_id": "69d16aebc5302134065f3349",
  "firstName": "Zain",
  "lastName": "Saleem",
  "email": "rafeysaleem66@gmail.com",
  "phone": "03008770331",
  "city": "Karachi",
  "address": "Street 123",
  "role": "Meal Provider",
  "status": "approved"
}
```

---

## Service 1: Biryani Special - Chicken

### cURL Command:

```bash
curl -X POST http://localhost:3000/api/services \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "serviceName": "Biryani Special - Chicken",
    "description": "Authentic Karachi-style chicken biryani with fragrant basmati rice, aromatic spices, and tender chicken pieces. Slow-cooked to perfection.",
    "price": 350,
    "unit": "per plate",
    "serviceType": "Meal Provider",
    "mealType": "Main Course",
    "cuisineType": "Pakistani",
    "isVegetarian": false,
    "isSpicy": true,
    "hasDairy": false,
    "hasGluten": true,
    "preparationTime": "45 minutes",
    "deliveryTime": "30-45 minutes",
    "deliveryAvailable": true,
    "pickupAvailable": true,
    "ingredients": ["Basmati Rice", "Chicken", "Onions", "Ginger-Garlic", "Yogurt", "Cardamom", "Cinnamon", "Bay Leaves", "Mint", "Ghee"],
    "allergens": ["Gluten (if using wheat instead of basmati)"],
    "nutritionInfo": {
      "calories": 450,
      "protein": 35,
      "carbs": 55,
      "fat": 12
    },
    "imageUrl": "meals/biryani-chicken.jpg",
    "additionalImages": ["meals/biryani-chicken-1.jpg", "meals/biryani-chicken-2.jpg"],
    "availableDays": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
    "availableTimeSlots": [
      {"startTime": "11:00 AM", "endTime": "02:00 PM"},
      {"startTime": "05:00 PM", "endTime": "10:00 PM"}
    ],
    "status": "Active",
    "featured": true,
    "discountPercentage": 0,
    "tags": ["Pakistani", "Biryani", "Lunch", "Dinner", "Spicy", "Non-Veg"]
  }'
```

---

## Service 2: Karahi Gosht (Mutton)

### cURL Command:

```bash
curl -X POST http://localhost:3000/api/services \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "serviceName": "Karahi Gosht (Mutton)",
    "description": "Traditional karahi mutton cooked with tomatoes, ginger, and aromatic spices. Best served with fresh naan bread.",
    "price": 400,
    "unit": "per plate",
    "serviceType": "Meal Provider",
    "mealType": "Main Course",
    "cuisineType": "Pakistani",
    "isVegetarian": false,
    "isSpicy": true,
    "hasDairy": false,
    "hasGluten": false,
    "preparationTime": "60 minutes",
    "deliveryTime": "45-60 minutes",
    "deliveryAvailable": true,
    "pickupAvailable": true,
    "ingredients": ["Mutton", "Tomatoes", "Onions", "Ginger", "Garlic", "Green Chili", "Cumin", "Coriander", "Salt", "Oil"],
    "allergens": [],
    "nutritionInfo": {
      "calories": 520,
      "protein": 45,
      "carbs": 20,
      "fat": 25
    },
    "imageUrl": "meals/karahi-gosht.jpg",
    "additionalImages": ["meals/karahi-gosht-1.jpg"],
    "availableDays": ["Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
    "availableTimeSlots": [
      {"startTime": "04:00 PM", "endTime": "10:30 PM"}
    ],
    "status": "Active",
    "featured": false,
    "discountPercentage": 5,
    "tags": ["Pakistani", "Mutton", "Curry", "Dinner", "Spicy", "Non-Veg"]
  }'
```

---

## Service 3: Nihari - Premium Quality

### cURL Command:

```bash
curl -X POST http://localhost:3000/api/services \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "serviceName": "Nihari - Premium Quality",
    "description": "Slow-cooked beef nihari with rich gravy and traditional spices. Served with fresh naan and pickle.",
    "price": 300,
    "unit": "per plate",
    "serviceType": "Meal Provider",
    "mealType": "Main Course",
    "cuisineType": "Pakistani",
    "isVegetarian": false,
    "isSpicy": true,
    "hasDairy": false,
    "hasGluten": false,
    "preparationTime": "90 minutes",
    "deliveryTime": "60 minutes",
    "deliveryAvailable": true,
    "pickupAvailable": true,
    "ingredients": ["Beef", "Yogurt", "Onions", "Garlic", "Ginger", "Red Chili Powder", "Coriander Powder", "Cumin", "Salt", "Oil"],
    "allergens": [],
    "nutritionInfo": {
      "calories": 480,
      "protein": 40,
      "carbs": 30,
      "fat": 20
    },
    "imageUrl": "meals/nihari-beef.jpg",
    "additionalImages": ["meals/nihari-beef-1.jpg", "meals/nihari-beef-2.jpg"],
    "availableDays": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
    "availableTimeSlots": [
      {"startTime": "06:00 AM", "endTime": "11:00 AM"},
      {"startTime": "04:00 PM", "endTime": "09:00 PM"}
    ],
    "status": "Active",
    "featured": true,
    "discountPercentage": 0,
    "tags": ["Pakistani", "Breakfast", "Nihari", "Beef", "Non-Veg", "Traditional"]
  }'
```

---

## Service 4: Fresh Vegetable Pulao

### cURL Command:

```bash
curl -X POST http://localhost:3000/api/services \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "serviceName": "Fresh Vegetable Pulao",
    "description": "Aromatic rice cooked with fresh vegetables, spices, and ghee. Perfect for vegetarians and health-conscious diners.",
    "price": 250,
    "unit": "per plate",
    "serviceType": "Meal Provider",
    "mealType": "Main Course",
    "cuisineType": "Pakistani",
    "isVegetarian": true,
    "isSpicy": false,
    "hasDairy": false,
    "hasGluten": true,
    "preparationTime": "30 minutes",
    "deliveryTime": "20-30 minutes",
    "deliveryAvailable": true,
    "pickupAvailable": true,
    "ingredients": ["Basmati Rice", "Carrots", "Peas", "Corn", "Beans", "Onions", "Cumin", "Bay Leaves", "Ghee", "Salt"],
    "allergens": ["Gluten"],
    "nutritionInfo": {
      "calories": 320,
      "protein": 12,
      "carbs": 60,
      "fat": 8
    },
    "imageUrl": "meals/veg-pulao.jpg",
    "additionalImages": [],
    "availableDays": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
    "availableTimeSlots": [
      {"startTime": "12:00 PM", "endTime": "03:00 PM"},
      {"startTime": "06:00 PM", "endTime": "09:00 PM"}
    ],
    "status": "Active",
    "featured": false,
    "discountPercentage": 10,
    "tags": ["Pakistani", "Vegetarian", "Healthy", "Rice", "Lunch", "Vegan"]
  }'
```

---

## Service 5: Tandoori Chicken with Rice

### cURL Command:

```bash
curl -X POST http://localhost:3000/api/services \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "serviceName": "Tandoori Chicken with Rice",
    "description": "Marinated and grilled chicken with smoky flavors, served with fragrant rice and yogurt sauce.",
    "price": 380,
    "unit": "per plate",
    "serviceType": "Meal Provider",
    "mealType": "Main Course",
    "cuisineType": "Pakistani",
    "isVegetarian": false,
    "isSpicy": true,
    "hasDairy": true,
    "hasGluten": false,
    "preparationTime": "50 minutes",
    "deliveryTime": "35-45 minutes",
    "deliveryAvailable": true,
    "pickupAvailable": true,
    "ingredients": ["Chicken", "Yogurt", "Ginger-Garlic Paste", "Red Chili Powder", "Turmeric", "Lemon Juice", "Salt", "Coriander", "Basmati Rice", "Ghee"],
    "allergens": ["Dairy"],
    "nutritionInfo": {
      "calories": 450,
      "protein": 38,
      "carbs": 50,
      "fat": 10
    },
    "imageUrl": "meals/tandoori-chicken.jpg",
    "additionalImages": ["meals/tandoori-chicken-1.jpg"],
    "availableDays": ["Monday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
    "availableTimeSlots": [
      {"startTime": "01:00 PM", "endTime": "09:00 PM"}
    ],
    "status": "Active",
    "featured": true,
    "discountPercentage": 0,
    "tags": ["Pakistani", "Tandoori", "Grilled", "Chicken", "Healthy", "Non-Veg"]
  }'
```

---

## Bulk Import Script (Bash)

```bash
#!/bin/bash

TOKEN="YOUR_JWT_TOKEN"
BASE_URL="http://localhost:3000/api"

# Function to create service
create_service() {
    local service_json=$1
    curl -X POST $BASE_URL/services \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $TOKEN" \
      -d "$service_json"
    echo ""
}

# Read and import each service from JSON file
jq -c '.[]' zain-saleem-meal-services.json | while read service; do
    echo "Creating service: $(echo $service | jq -r '.serviceName')"
    create_service "$service"
done

echo "✅ All services imported successfully!"
```

---

## Verification Commands

### Get all services for this provider:

```bash
curl -X GET "http://localhost:3000/api/services?providerId=69d16aebc5302134065f3349" \
  -H "Content-Type: application/json"
```

### Get specific service by name:

```bash
curl -X GET "http://localhost:3000/api/services?search=biryani" \
  -H "Content-Type: application/json"
```

### Get featured services:

```bash
curl -X GET "http://localhost:3000/api/services/recommendations/featured?limit=10" \
  -H "Content-Type: application/json"
```

---

## Response Expected:

```json
{
  "success": true,
  "message": "Service created successfully",
  "service": {
    "_id": "64a7b85f9c1234567890001a",
    "serviceName": "Biryani Special - Chicken",
    "price": 350,
    ...
  }
}
```

---

## Notes:

- Replace `YOUR_JWT_TOKEN` with actual JWT token from login
- Ensure server is running on `localhost:3000`
- Services will appear in mobile app immediately after creation
- Update availability/hours anytime with PUT request

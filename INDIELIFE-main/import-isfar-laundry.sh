#!/bin/bash

# Isfar Akbar Laundry Services - MongoDB Import Script (Linux/Mac)

echo "=========================================="
echo "Isfar Akbar Laundry Services - MongoDB Import"
echo "=========================================="
echo ""

# Check if JSON file exists
if [ ! -f "isfar-akbar-laundry-services.json" ]; then
    echo "❌ ERROR: isfar-akbar-laundry-services.json not found!"
    echo "Make sure you are in the correct directory."
    exit 1
fi

echo "📋 Validating JSON file..."
if ! jq empty isfar-akbar-laundry-services.json 2>/dev/null; then
    echo "❌ ERROR: Invalid JSON file!"
    exit 1
fi
echo "✅ JSON file valid"
echo ""

echo "🔗 Connecting to MongoDB..."
if ! mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
    echo "❌ ERROR: Cannot connect to MongoDB!"
    echo "Make sure MongoDB is running on localhost:27017"
    exit 1
fi
echo "✅ Connected to MongoDB"
echo ""

echo "📥 Importing 5 laundry services for Isfar Akbar..."
mongoimport --db indielife --collection services --file isfar-akbar-laundry-services.json --jsonArray

if [ $? -ne 0 ]; then
    echo "❌ ERROR: Import failed!"
    exit 1
fi
echo "✅ Import completed successfully!"
echo ""

echo "🔍 Verifying import..."
mongosh --eval "db.services.countDocuments({serviceProviderId: ObjectId('69d29aa209ce95127ee91ac8')})" --db indielife

echo ""
echo "=========================================="
echo "✅ Services imported for: Isfar Akbar (Laundry)"
echo "Service Provider ID: 69d29aa209ce95127ee91ac8"
echo "=========================================="
echo ""
echo "You can now search for laundry services in the app!"
echo ""

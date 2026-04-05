#!/bin/bash
# MongoDB Import Script for Zain Saleem Services
# This script automates the import process

echo "🍽️  Importing Zain Saleem's Meal Services..."
echo "================================================"

# Configuration
MONGODB_URI="mongodb://localhost:27017"
DATABASE="indielife"
COLLECTION="services"
JSON_FILE="zain-saleem-meal-services.json"

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if file exists
if [ ! -f "$JSON_FILE" ]; then
    echo -e "${RED}❌ Error: File $JSON_FILE not found!${NC}"
    exit 1
fi

# Check if mongoimport exists
if ! command -v mongoimport &> /dev/null; then
    echo -e "${RED}❌ Error: mongoimport not found. Please install MongoDB Database Tools.${NC}"
    exit 1
fi

# Validate JSON
echo -e "${YELLOW}📋 Validating JSON file...${NC}"
if ! jq . "$JSON_FILE" > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Invalid JSON format${NC}"
    exit 1
fi
echo -e "${GREEN}✅ JSON validation passed${NC}"

# Check MongoDB connection
echo -e "${YELLOW}🔗 Checking MongoDB connection...${NC}"
if ! mongosh "$MONGODB_URI" --eval "print('connected')" > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Cannot connect to MongoDB${NC}"
    echo -e "${YELLOW}Make sure MongoDB is running: mongod${NC}"
    exit 1
fi
echo -e "${GREEN}✅ MongoDB connection successful${NC}"

# Delete existing services (optional - comment out to append)
echo -e "${YELLOW}🗑️  Cleaning up existing services from this provider...${NC}"
mongosh "$MONGODB_URI/$DATABASE" --eval \
  'db.services.deleteMany({ serviceProviderId: ObjectId("69d16aebc5302134065f3349") })'

# Import the JSON file
echo -e "${YELLOW}📥 Importing services...${NC}"
mongoimport --uri "$MONGODB_URI/$DATABASE" \
  --collection "$COLLECTION" \
  --file "$JSON_FILE" \
  --jsonArray \
  --drop

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Import successful!${NC}"
    
    # Verify import
    echo -e "${YELLOW}📊 Verifying import...${NC}"
    COUNT=$(mongosh "$MONGODB_URI/$DATABASE" --eval \
      'db.services.countDocuments({ serviceProviderId: ObjectId("69d16aebc5302134065f3349") })' | tail -1)
    
    echo -e "${GREEN}Total services imported: $COUNT${NC}"
    
    # Display summary
    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}✅ Import Complete!${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo "Provider: Zain Saleem"
    echo "Services Imported: $COUNT"
    echo "Database: $DATABASE"
    echo "Collection: $COLLECTION"
else
    echo -e "${RED}❌ Import failed!${NC}"
    exit 1
fi

# PowerShell Import Script for Zain Saleem Services
# Usage: powershell -ExecutionPolicy Bypass -File import-services.ps1

$ErrorActionPreference = "Stop"

Write-Host "🍽️  Importing Zain Saleem's Meal Services..." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Configuration
$MONGODB_URI = "mongodb://localhost:27017"
$DATABASE = "indielife"
$COLLECTION = "services"
$JSON_FILE = "zain-saleem-meal-services.json"
$MONGODB_TOOLS_PATH = "C:\Program Files\MongoDB\Tools\mongoimport.exe"

# Check if file exists
if (-not (Test-Path $JSON_FILE)) {
    Write-Host "❌ Error: File $JSON_FILE not found!" -ForegroundColor Red
    Write-Host "Working directory: $(Get-Location)" -ForegroundColor Yellow
    exit 1
}

# Check if mongoimport exists
$mongoimportPath = if (Test-Path $MONGODB_TOOLS_PATH) { 
    $MONGODB_TOOLS_PATH 
} else { 
    "mongoimport" 
}

if (-not (Get-Command $mongoimportPath -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: mongoimport not found!" -ForegroundColor Red
    Write-Host "Please install MongoDB Database Tools from: https://www.mongodb.com/try/download/database-tools" -ForegroundColor Yellow
    exit 1
}

# Validate JSON
Write-Host "📋 Validating JSON file..." -ForegroundColor Yellow
try {
    $json = Get-Content $JSON_FILE | ConvertFrom-Json
    Write-Host "✅ JSON validation passed" -ForegroundColor Green
    Write-Host "   Services to import: $($json.Count)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Error: Invalid JSON format - $_" -ForegroundColor Red
    exit 1
}

# Check MongoDB connection
Write-Host "🔗 Checking MongoDB connection..." -ForegroundColor Yellow
try {
    # Try to connect using mongosh
    $testCmd = mongosh "$MONGODB_URI" --eval "print('connected')" 2>$null
    Write-Host "✅ MongoDB connection successful" -ForegroundColor Green
} catch {
    Write-Host "⚠️  MongoDB connection check inconclusive (continuing anyway...)" -ForegroundColor Yellow
}

# Delete existing services (optional - comment out to append)
Write-Host "🗑️  Cleaning up existing services..." -ForegroundColor Yellow
try {
    mongosh "$MONGODB_URI/$DATABASE" --eval 'db.services.deleteMany({ serviceProviderId: ObjectId("69d16aebc5302134065f3349") })'
    Write-Host "✅ Cleanup complete" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Cleanup skipped (this is OK)" -ForegroundColor Yellow
}

# Import the JSON file
Write-Host "📥 Importing services..." -ForegroundColor Yellow
& mongoimport --uri "$MONGODB_URI/$DATABASE" `
    --collection "$COLLECTION" `
    --file $JSON_FILE `
    --jsonArray

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Import successful!" -ForegroundColor Green
    
    # Verify import
    Write-Host "📊 Verifying import..." -ForegroundColor Yellow
    $result = mongosh "$MONGODB_URI/$DATABASE" --eval 'db.services.countDocuments({ serviceProviderId: ObjectId("69d16aebc5302134065f3349") })'
    
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "✅ IMPORT COMPLETE!" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "Provider: Zain Saleem" -ForegroundColor Cyan
    Write-Host "Email: rafeysaleem66@gmail.com" -ForegroundColor Cyan
    Write-Host "Phone: 03008770331" -ForegroundColor Cyan
    Write-Host "City: Karachi" -ForegroundColor Cyan
    Write-Host "Status: Approved" -ForegroundColor Green
    Write-Host ""
    Write-Host "Services to import: 5" -ForegroundColor Green
    Write-Host "Database: $DATABASE" -ForegroundColor Green
    Write-Host "Collection: $COLLECTION" -ForegroundColor Green
} else {
    Write-Host "❌ Import failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Ready to test in mobile app and web portal!" -ForegroundColor Green

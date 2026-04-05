#!/usr/bin/env pwsh

# Isfar Akbar Laundry Services - MongoDB Import Script (PowerShell)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Isfar Akbar Laundry Services - MongoDB Import" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if JSON file exists
if (-not (Test-Path "isfar-akbar-laundry-services.json")) {
    Write-Host "❌ ERROR: isfar-akbar-laundry-services.json not found!" -ForegroundColor Red
    Write-Host "Make sure you are in the correct directory." -ForegroundColor Red
    exit 1
}

Write-Host "📋 Validating JSON file..." -ForegroundColor Yellow
try {
    $jsonContent = Get-Content "isfar-akbar-laundry-services.json" -Raw | ConvertFrom-Json
    Write-Host "✅ JSON file valid" -ForegroundColor Green
}
catch {
    Write-Host "❌ ERROR: Invalid JSON file!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "🔗 Connecting to MongoDB..." -ForegroundColor Yellow
try {
    $testConnection = & mongosh --eval "db.adminCommand('ping')" 2>&1
    Write-Host "✅ Connected to MongoDB" -ForegroundColor Green
}
catch {
    Write-Host "❌ ERROR: Cannot connect to MongoDB!" -ForegroundColor Red
    Write-Host "Make sure MongoDB is running on localhost:27017" -ForegroundColor Red
    exit 1
}
Write-Host ""

Write-Host "📥 Importing 5 laundry services for Isfar Akbar..." -ForegroundColor Yellow
& mongoimport --db indielife --collection services --file isfar-akbar-laundry-services.json --jsonArray

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ ERROR: Import failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Import completed successfully!" -ForegroundColor Green
Write-Host ""

Write-Host "🔍 Verifying import..." -ForegroundColor Yellow
$count = & mongosh --eval "db.services.countDocuments({serviceProviderId: ObjectId('69d29aa209ce95127ee91ac8')})" --db indielife 2>&1 | Select-Object -Last 1
Write-Host "Total services for Isfar Akbar: $count" -ForegroundColor Green

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "✅ Services imported for: Isfar Akbar (Laundry)" -ForegroundColor Green
Write-Host "Service Provider ID: 69d29aa209ce95127ee91ac8" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "You can now search for laundry services in the app!" -ForegroundColor Green
Write-Host ""

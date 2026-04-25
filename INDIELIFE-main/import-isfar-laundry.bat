@echo off
REM Isfar Akbar Laundry Services - MongoDB Import Script (Windows)

setlocal enabledelayedexpansion

REM Colors for output
set RED=[91m
set GREEN=[92m
set YELLOW=[93m
set RESET=[0m

echo Isfar Akbar Laundry Services - MongoDB Import
echo ================================================
echo.

REM Check if JSON file exists
if not exist "isfar-akbar-laundry-services.json" (
    echo %RED%ERROR: isfar-akbar-laundry-services.json not found!%RESET%
    echo Make sure you are in the correct directory.
    pause
    exit /b 1
)

echo %YELLOW%Validating JSON file...%RESET%
REM Simple validation - check if file contains opening and closing brackets
find /C "[" "isfar-akbar-laundry-services.json" >nul
if errorlevel 1 (
    echo %RED%ERROR: Invalid JSON file!%RESET%
    pause
    exit /b 1
)
echo %GREEN%✓ JSON file valid%RESET%
echo.

echo %YELLOW%Connecting to MongoDB...%RESET%
REM Test connection
mongosh --eval "db.adminCommand('ping')" >nul 2>&1
if errorlevel 1 (
    echo %RED%ERROR: Cannot connect to MongoDB!%RESET%
    echo Make sure MongoDB is running on localhost:27017
    pause
    exit /b 1
)
echo %GREEN%✓ Connected to MongoDB%RESET%
echo.

echo %YELLOW%Importing 5 laundry services for Isfar Akbar...%RESET%
mongoimport --db indielife --collection services --file isfar-akbar-laundry-services.json --jsonArray

if errorlevel 1 (
    echo %RED%ERROR: Import failed!%RESET%
    pause
    exit /b 1
)
echo %GREEN%✓ Import completed successfully!%RESET%
echo.

echo %YELLOW%Verifying import...%RESET%
mongosh --eval "db.services.countDocuments({serviceProviderId: ObjectId('69d29aa209ce95127ee91ac8')})" --db indielife

echo.
echo %GREEN%================================================%RESET%
echo Services imported for: Isfar Akbar (Laundry)
echo Service Provider ID: 69d29aa209ce95127ee91ac8
echo %GREEN%================================================%RESET%
echo.
echo You can now search for laundry services in the app!
echo.
pause

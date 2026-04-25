# INDIELIFE

<p align="center">
    <strong>Flutter service marketplace + AI budget planning backend</strong><br>
    A student project combining mobile booking, provider workflows, admin tooling, and AI-powered budget guidance.
</p>

<p align="center">
    <a href="https://github.com/rafaysaleem0308/INDIELIFE"><img src="https://img.shields.io/badge/Repo-INDIELIFE-111827?style=for-the-badge&logo=github" alt="Repository badge"></a>
    <img src="https://img.shields.io/badge/Flutter-Mobile_App-02569B?style=for-the-badge&logo=flutter" alt="Flutter badge">
    <img src="https://img.shields.io/badge/Python-AI_Backend-3776AB?style=for-the-badge&logo=python" alt="Python badge">
    <img src="https://img.shields.io/badge/MongoDB-Database-47A248?style=for-the-badge&logo=mongodb" alt="MongoDB badge">
</p>

## What’s inside

INDIELIFE is organized as two top-level projects in one repository:

- [INDIELIFE-main](INDIELIFE-main) - the Flutter application, backend integration, and admin panel
- [Ai model fyp](Ai%20model%20fyp) - the Flask AI budget recommendation service, training assets, and dataset files

## Project Highlights

- Modern Flutter app for users and service providers
- Admin dashboard for operational management
- Backend APIs for authentication, bookings, community posts, and service discovery
- AI budget recommendation flow for meals, laundry, and maintenance
- Secret-safe repository setup with a root `.gitignore`

## Repository Layout

```text
.
├── Ai model fyp/
│   ├── app.py
│   ├── config.py
│   ├── model_trainer.py
│   ├── requirements.txt
│   └── trained_models/
└── INDIELIFE-main/
    ├── lib/
    ├── android/
    ├── ios/
    ├── backend/
    ├── admin-panel/
    └── assets/
```

## Tech Stack

- Flutter and Dart for the mobile app
- Python and Flask for AI budget planning
- React and Vite for the admin panel
- MongoDB for application data
- Node.js for backend utilities and dashboard tooling

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/rafaysaleem0308/INDIELIFE.git
cd INDIELIFE
```

### 2. Run the Flutter app

```bash
cd "INDIELIFE-main"
flutter pub get
flutter run
```

If you are using an Android emulator, the app reaches your local machine through `10.0.2.2`.

### 3. Run the AI backend

```bash
cd "Ai model fyp"
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

The Flask service runs on `http://localhost:5000` by default.

## AI Budget Planner

The AI assistant is available inside the Flutter app at [INDIELIFE-main/lib/features/home/screens/ai_budget_recommendation.dart](INDIELIFE-main/lib/features/home/screens/ai_budget_recommendation.dart) and communicates with the Flask backend in [Ai model fyp](Ai%20model%20fyp).

Supported planning areas:

- Meals
- Laundry
- Maintenance

Example prompt:

```text
I have 7000 PKR for 14 days for meals
```

## Admin Panel

The admin panel lives in [INDIELIFE-main/admin-panel](INDIELIFE-main/admin-panel). Install and run it separately when you need the dashboard:

```bash
cd "INDIELIFE-main/admin-panel"
npm install
npm run dev
```

## Environment Safety

This repository is configured to keep local-only files out of version control. The root `.gitignore` excludes:

- `.env` files and variants
- `.venv` folders
- `node_modules`
- build output and cache folders such as `.dart_tool`, `build`, and coverage artifacts
- other generated or machine-specific files

Keep API keys, passwords, and local database settings in private `.env` files and never commit them.

## Common Commands

### Flutter

```bash
cd "INDIELIFE-main"
flutter analyze
flutter test
flutter run
```

### Python AI service

```bash
cd "Ai model fyp"
python app.py
```

## Configuration Notes

- On Android emulator, use `10.0.2.2` instead of `127.0.0.1` for local services.
- If MongoDB is unavailable, verify that the server is running and the URI matches your environment.
- If a file should stay local, add it to `.gitignore` before staging.

## Contribution Flow

1. Create a feature branch.
2. Make the change in the relevant folder.
3. Keep secrets and generated files out of the repository.
4. Run the relevant checks before opening a pull request.

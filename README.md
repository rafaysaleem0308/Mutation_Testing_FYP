# INDIELIFE

INDIELIFE is a combined repository for a Flutter mobile service marketplace and a Python-based AI budget planning backend. The repo currently contains two top-level projects:

- [INDIELIFE-main](INDIELIFE-main) - the Flutter app and backend integration layer
- [Ai model fyp](Ai%20model%20fyp) - the Flask AI budget recommendation service and training assets

## Overview

The Flutter app provides the customer-facing experience for booking and managing services such as meals, laundry, maintenance, and housing. The Python project powers the AI budget planner that can generate recommendations based on a budget, duration, and service category.

The repository is configured to keep local-only files out of Git, including environment files, virtual environments, build artifacts, and dependency folders.

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

## Features

- Flutter mobile app for users and service providers
- Admin panel for operational management
- Backend APIs for authentication, community posts, services, and bookings
- AI budget recommendation flow for meal, laundry, and maintenance planning
- Protected local environment setup with `.gitignore` rules for secrets and generated files

## Prerequisites

- Flutter SDK
- Dart SDK
- Python 3.10+ for the AI project
- Node.js for the admin panel and backend scripts
- MongoDB for the application backend
- Git

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/rafaysaleem0308/INDIELIFE.git
cd INDIELIFE
```

### 2. Start the Flutter application

```bash
cd "INDIELIFE-main"
flutter pub get
flutter run
```

If you are running on Android emulator, the app uses `10.0.2.2` to reach services running on your host machine.

### 3. Start the AI backend

```bash
cd "Ai model fyp"
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

The Flask service runs on `http://localhost:5000` by default.

## Environment Variables

Keep secrets in local `.env` files and do not commit them.

### Flutter and Node backend

Use `.env` or platform-specific config files for:

- `MONGO_URI`
- `JWT_SECRET`
- `EMAIL_USER`
- `EMAIL_PASS`
- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `TWILIO_PHONE_NUMBER`

### Python AI project

If you add API keys or extra credentials, store them locally and keep them out of Git.

## Safety and Git Hygiene

The root `.gitignore` excludes:

- `.env` files and variants
- `.venv` directories
- `node_modules`
- build outputs such as `build`, `.dart_tool`, and coverage artifacts
- other generated or machine-specific files

If you add new local-only files, extend `.gitignore` before committing.

## AI Budget Planner

The AI workflow is exposed through the Flutter screen at `INDIELIFE-main/lib/features/home/screens/ai_budget_recommendation.dart` and communicates with the Flask service in `Ai model fyp`.

Supported categories include:

- Meals
- Laundry
- Maintenance

The AI assistant can accept a natural-language prompt such as:

```text
I have 7000 PKR for 14 days for meals
```

## Admin Panel

The admin panel is located in `INDIELIFE-main/admin-panel` and is built with Vite and React. Install its dependencies separately if you want to work on the dashboard:

```bash
cd "INDIELIFE-main/admin-panel"
npm install
npm run dev
```

## Useful Commands

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

## Troubleshooting

- If Flutter cannot reach the AI service on Android, use `10.0.2.2` instead of `127.0.0.1`.
- If the app cannot connect to MongoDB, verify that MongoDB is running and the URI matches your environment.
- If secrets appear in Git status, confirm they are covered by `.gitignore` before staging.

## Contributing

1. Create a feature branch.
2. Make the change in the relevant project folder.
3. Keep secrets and generated files out of the repository.
4. Run the relevant checks before opening a pull request.

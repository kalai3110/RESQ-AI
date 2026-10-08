# AI-Based Disaster Response Assistant

A complete, modern, professional mobile application and backend decision support system powered by **Artificial Intelligence & Machine Learning (Decision Tree Algorithm)**, **Python Flask**, **MySQL Database**, and **Flutter**.

---

## 🌟 Key Features

1. **Secure Authentication & Role-Based Access Control**:
   - Dedicated **Login Screen** as the entrypoint.
   - Email ID & Password verification with strict authentication checks.
   - **Continue with Google** integration.
   - User roles: **Citizen Reporter**, **Rescue Officer**, **Disaster Response Commander (Admin)**.

2. **Intelligent AI Decision Tree Severity & Priority Engine**:
   - Built with Python `scikit-learn` (`DecisionTreeClassifier`).
   - Analyzes real-time incident parameters:
     - Disaster Type (*Flood, Cyclone, Earthquake, Fire, Landslide, Accident, Other*)
     - Total People Affected, Injured, Missing, and Urgent Help Required
     - Damage Level (*Low, Medium, High, Critical*)
     - Infrastructure & Residential Property Damage
   - Predicts **Severity Level**: `LOW`, `MEDIUM`, `HIGH`, `CRITICAL` (95.5% accuracy).
   - Automatically assigns **Response Priority Matrix**:
     - **P1 – Critical**: Immediate Response Required (< 30 mins)
     - **P2 – High**: Very Urgent Response (< 2 hours)
     - **P3 – Medium**: Normal Response (< 6 hours)
     - **P4 – Low**: Monitor & Routine Assistance

3. **Executive Home Dashboard**:
   - 8 Real-time Summary KPI Cards:
     - *Total Disaster Reports*, *Critical P1 Cases*, *High Priority P2 Cases*, *People Affected*, *Active Rescue Teams*, *Available Shelters*, *Medical Assistance Requests*, *Relief Resources*.
   - 7 Core Navigation Modules + Emergency Dispatch Shortcuts.

4. **Incident Reporting & Image Evidence**:
   - Structured disaster reporting form.
   - Manual Landmark/District/Area location input (strictly respects privacy: **NO continuous live GPS tracking**).
   - Camera and Gallery photo evidence upload stored securely on backend.
   - **Instant AI Severity & Priority Preview modal** prior to submission.

5. **Rescue Team Lifecycle Tracker**:
   - Live tracking of deployed rescue teams (Alpha, Bravo, Charlie, Delta, Echo).
   - 5-stage status workflow: `Assigned` $\rightarrow$ `Preparing` $\rightarrow$ `On the Way` $\rightarrow$ `Reached` $\rightarrow$ `Completed`.
   - Dispatch and reassignment capabilities for commanders.

6. **Shelter Availability Directory**:
   - Capacity meters, occupancy counters, and real-time available seats.
   - Status indicators: `Available`, `Limited`, `Full`.
   - Live amenity badges: 🍲 Food, 💧 Water, 🏥 Medical Facility.

7. **Emergency Medical Assistance**:
   - Casualty triage tracking with ambulance requirements and emergency treatment flags.
   - Hospital assignment and ambulance dispatch counter.

8. **Relief Resources Inventory**:
   - Stock tracking for Food Packets, Drinking Water Bottles, Medicines, Blankets, and Rescue Equipment.
   - Restock actions and status indicators (`Available`, `Limited`, `Low`, `Out of Stock`).

9. **Interactive Disaster Map**:
   - Visual map with OpenStreetMap tiles.
   - Severity color-coded markers: 🟢 Green (Low), 🟡 Yellow (Medium), 🟠 Orange (High), 🔴 Red (Critical).
   - Interactive bottom-sheet callouts detailing people affected, assigned rescue team, and nearest shelters.

10. **My Reports History & In-App Alerts**:
    - Complete personal report history with tracking codes (`DR-1025`, `DR-1026`).
    - Event notifications for report creation, AI evaluation, rescue team milestones, shelter updates, and medical dispatches.

---

## 🏗️ Project Architecture

```
c:\Disaster\
├── backend/
│   ├── app.py                      # Flask Application Factory & Blueprints
│   ├── config.py                   # Configuration (MySQL / SQLite dual support)
│   ├── database.py                 # SQLAlchemy DB engine & automatic data seeder
│   ├── models.py                   # Relational ORM models (User, Report, Team, etc.)
│   ├── run.py                      # Server runner script
│   ├── schema.sql                  # MySQL table definitions & constraints
│   ├── seed_data.sql               # Seed data for academic demo
│   ├── requirements.txt            # Python dependencies
│   ├── ml/
│   │   ├── train_model.py          # Decision Tree training pipeline
│   │   ├── disaster_decision_tree.py # Runtime AI predictor & explainability
│   │   ├── disaster_model.pkl      # Trained Decision Tree classifier
│   │   ├── model_meta.json         # Feature importance & metadata
│   │   └── disaster_dataset.csv    # 3,000 disaster scenarios dataset
│   ├── routes/
│   │   ├── auth_routes.py          # /api/auth
│   │   ├── disaster_routes.py      # /api/disaster
│   │   ├── rescue_routes.py        # /api/rescue
│   │   ├── shelter_routes.py       # /api/shelters
│   │   ├── medical_routes.py       # /api/medical
│   │   ├── resource_routes.py      # /api/resources
│   │   ├── map_routes.py           # /api/map
│   │   ├── notification_routes.py  # /api/notifications
│   │   └── admin_routes.py         # /api/dashboard
│   └── tests/
│       ├── test_ml.py              # ML accuracy & decision tree unit tests
│       └── test_api.py             # 15 backend API integration tests
│
└── frontend/                       # Flutter Mobile Application
    ├── pubspec.yaml                # Flutter packages
    └── lib/
        ├── main.dart               # MultiProvider App Entrypoint
        ├── constants/              # AppColors, AppTheme, ApiConstants
        ├── models/                 # Dart Data Models
        ├── services/               # ApiService (HTTP Client)
        ├── providers/              # Auth, Disaster, Rescue, Shelter, Medical, Resource
        ├── widgets/                # SeverityBadge, PriorityBadge, KpiCard, CustomButton
        └── screens/                # Login, Register, Home, Report, Map, Rescue, Shelter, etc.
```

---

## 🚀 Setup & Execution Guide

### Prerequisites
- Python 3.10+
- Flutter SDK 3.0+
- (Optional) MySQL Server (XAMPP / WAMP / MySQL 8.0) — *The backend automatically includes seamless SQLite fallback so it works out of the box even without MySQL running!*

---

### Step 1: Start the Flask ML Backend

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. (Optional) Retrain Decision Tree model:
   ```bash
   python ml/train_model.py
   ```
4. Run automated test suites:
   ```bash
   python -m unittest discover -s tests -p "test_*.py"
   ```
5. Start the backend server:
   ```bash
   python run.py
   ```
   *The server will start on `http://0.0.0.0:5000` / `http://localhost:5000`.*

---

### Step 2: Run the Flutter Mobile Application

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run automated tests:
   ```bash
   flutter test
   ```
4. Launch the application:
   - **Chrome Web**: `flutter run -d chrome`
   - **Windows Desktop**: `flutter run -d windows`
   - **Android Emulator / Device**: `flutter run -d android`

---

## 🔑 Demo Login Credentials

| Role | Email ID | Password | Access Level |
|---|---|---|---|
| **Disaster Response Commander** | `admin@disaster.org` | `password123` | Full Admin & Rescue Dispatch Operations Hub |
| **Rescue Officer (Team Alpha)** | `rescue.alpha@disaster.org` | `password123` | Rescue Status Management & Triage |
| **Citizen Reporter** | `priya@gmail.com` | `password123` | Incident Reporting, Map & Shelter Directory |

---

## 📊 AI Model Evaluation Metrics

- **Algorithm**: `DecisionTreeClassifier(max_depth=6, criterion='gini')`
- **Accuracy**: **95.50%**
- **Precision / Recall / F1-Score**:
  - `CRITICAL`: Precision 0.99, Recall 0.99, F1 0.99
  - `HIGH`: Precision 0.92, Recall 0.88, F1 0.90
  - `MEDIUM`: Precision 0.74, Recall 0.87, F1 0.80
  - `LOW`: Precision 0.71, Recall 0.56, F1 0.62

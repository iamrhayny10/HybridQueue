# GRC Queue Tracking System

A mobile and web-based queue management system for **Global Reciprocal Colleges (GRC)**. Students take a queue number from a mobile app for the **Registrar**, **Cashier**, or **OSA**, follow their place in line live, and see an estimated waiting time predicted by a machine learning model. Staff call tickets from a web service window, a TV display shows who is being served, and a priority lane serves verified PWD students first.

**Main objectives:** reduce waiting time, make queues organized and transparent, and give staff and administrators real-time tools and reports.

---

## Features

* **Student mobile app (Flutter):** register with a Student ID, take a queue number, track position, get turn notifications, apply for the PWD priority lane.
* **Estimated waiting time:** Random Forest model (Python + Flask) predicts the wait from queue length, time of day, day of week, and open windows.
* **Staff service window (web):** each staff member sees their assigned window and can **Call Next**, skip, and mark tickets as served.
* **Live display (web):** TV screen showing every window's current ticket and the waiting lists per service.
* **Admin dashboard (web):** live overview, queue monitor, service windows, reports, analytics, user management, PWD verification, activity logs, and a control panel.
* **PWD priority lane:** verified PWD students are called before regular tickets.

---

## Group Members & Roles

* **Del Valle, Jobert F.** – Group Lead / Documenter / System Analyst
* **Batili, Jasper T.** – System Analyst
* **Magtoto, John Carlo T.** – Full-Stack Developer
* **Manal, Jairo Benjamin T.** – UI/UX Designer
* **Mercader, Rayn Ashley M.** – Documenter

---

## Tech Stack

* **Frontend:** Flutter (Dart) for the student mobile app; HTML, CSS, and JavaScript for the admin/staff dashboard and the TV live display.
* **Backend:** PHP 8 REST API (`backend/api`); Python 3 + Flask machine learning service (port 5001).
* **Database:** MariaDB / MySQL (managed with phpMyAdmin).
* **Tools & Version Control:** Git, GitHub, XAMPP, phpMyAdmin, Android Studio, PyCharm, Serveo (SSH tunnel for access outside the local network).

---

## Project Structure

```
.
├── queue_system/                  # Backend, web pages, ML model, database
│   ├── backend/
│   │   ├── api/                   # PHP REST endpoints (auth, tickets, windows, pwd, ...)
│   │   ├── config/                # db.php, auth_guard.php, pwd_schema.php
│   │   └── uploads/pwd/           # Uploaded PWD ID photos
│   ├── frontend/
│   │   ├── config.js              # BASE_URL (server / tunnel address)
│   │   ├── admin/                 # Admin + staff dashboard (index.html), control panel, reports
│   │   └── display/display.php    # TV live display
│   ├── ml_model/                  # model.py, rf_model.pkl, training_data.csv
│   └── database/                  # SQL file (queue_tracking_db.sql)
└── grc_queue_flutter/             # Flutter student mobile app
    ├── lib/                       # Dart source (screens, services, models, utils)
    └── pubspec.yaml
```

---

## System Requirements & Prerequisites

Before you begin, make sure you have the following installed:

* **XAMPP** with **PHP 8.2+** and **MariaDB 10.4+** (Apache and MySQL modules)
* **Python 3.9+** and `pip` (for the machine learning service)
* **Flutter SDK 3.x** (Dart `>=3.3.0 <4.0.0`) and **Android Studio** (to run or build the mobile app)
* **Git**
* An SSH client (built into Windows 10/11) to run the Serveo tunnel

---

## Installation & Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/iamrhayny10/HybridQueue.git
cd HybridQueue
```

### 2. Place the Backend in XAMPP

Copy the `queue_system` folder into XAMPP's web root so the final path is:

```
C:\xampp\htdocs\queue_system
```

The mobile app and web pages expect the API at `/queue_system/backend/api`, so keep this folder name.

### 3. Install the ML Service Dependencies

```bash
cd queue_system/ml_model
pip install flask scikit-learn pandas numpy pymysql
```

Then train the models once. This also creates `purpose_model.pkl`, which is not included in the repository:

```bash
python model.py train
```

### 4. Install the Mobile App Dependencies

```bash
cd grc_queue_flutter
flutter pub get
```

---

## Database Setup & Configuration

1. **Start your local servers:** open XAMPP and start **Apache** and **MySQL**.
2. **Open phpMyAdmin** at `http://localhost/phpmyadmin`.
3. **Create the database:** click **New**, enter the name `queue_tracking_db`, choose the collation `utf8mb4_unicode_ci`, and click **Create**. (If a database with this name already exists, delete it first so you start clean.) The SQL file does not create the database itself, so this step is required.
4. **Import the data:** click `queue_tracking_db` in the left sidebar, open the **Import** tab, choose `queue_system/database/queue_tracking_db.sql`, and press **Go**. This creates all tables, the default accounts, and the six service windows.
5. **Check the connection settings** in `queue_system/backend/config/db.php` (defaults for XAMPP):

   ```php
   define('DB_HOST', 'localhost');
   define('DB_PORT', '3306');
   define('DB_NAME', 'queue_tracking_db');
   define('DB_USER', 'root');
   define('DB_PASS', '');   // blank by default in XAMPP
   ```

6. **Verify:** open `http://localhost/queue_system/backend/api/tickets.php`. It should return JSON starting with `{"success":true`.

> The PWD priority lane columns are added automatically on the first request if they are missing.

---

## Running the Application

### 1. Start the servers
Start **Apache** and **MySQL** in XAMPP.

### 2. Start the machine learning service

```bash
cd queue_system/ml_model
python model.py
```

It runs on `http://localhost:5001` (`POST /predict`). Open `http://localhost:5001/health` to confirm it is running. Run `python model.py train` once before the first start (see Installation, step 3). If the model file is missing, the service generates training data and trains the model on first run. To retrain manually, run `python model.py train` again. If the service is not running, tickets are still issued, but without the machine learning estimate.

### 3. Start the Serveo tunnel

The web pages and the mobile app connect to the system through a Serveo tunnel. Keep this window open while the system is in use:

```bash
ssh -R grcqueue2:80:localhost:80 serveo.net
```

The system is then reachable at `https://grcqueue2.serveousercontent.com`. If you use a different subdomain, replace `grcqueue2` in the command and in steps 4 and 6 below.

### 4. Set the server address (`frontend/config.js`)

`queue_system/frontend/config.js` already points to the Serveo address:

```javascript
const BASE_URL = 'https://grcqueue2.serveousercontent.com';
```

Change it only if you use a different subdomain (no trailing slash), then refresh the page. When a page is opened at `http://localhost`, the API address is detected automatically. When it is opened through any other address, such as the Serveo link, the page uses `BASE_URL`.

### 5. Open the web pages

| Page | Serveo URL | Local URL |
|------|-----------|-----------|
| Admin / Staff dashboard | `https://grcqueue2.serveousercontent.com/queue_system/frontend/admin/index.html` | `http://localhost/queue_system/frontend/admin/index.html` |
| TV live display | `https://grcqueue2.serveousercontent.com/queue_system/frontend/display/display.php` | `http://localhost/queue_system/frontend/display/display.php` |

On the first visit through Serveo you may see a warning page. Continue past it.

### 6. Run the mobile app

Open `grc_queue_flutter/lib/utils/constants.dart` and set `baseUrl` to the Serveo address:

```dart
static const String baseUrl = 'https://grcqueue2.serveousercontent.com/queue_system/backend/api';
```

Then run or build the app:

```bash
flutter run
# or build an installable APK
flutter build apk --release
```

> To test on the same Wi-Fi without Serveo, use `http://<YOUR-PC-IP>/queue_system/backend/api` instead (find the IP with `ipconfig`). Plain `http://` on a real phone also requires `android:usesCleartextTraffic="true"` in `android/app/src/main/AndroidManifest.xml`.

---

## Default Login Credentials

> Change these passwords after the first login.

* **Admin account:** `admin` / `Admin@123`
* **Staff accounts:** `staff1` to `staff6` / `qweqwe22`

| Service | Window 1 | Window 2 |
|---------|----------|----------|
| Registrar | `staff1` | `staff4` |
| Cashier | `staff2` | `staff5` |
| OSA | `staff3` | `staff6` |

* **Student accounts:** students register in the mobile app using their Student ID in the format `YYYY-MM-NNNNN` (example: `2024-01-00001`).

---

## Troubleshooting

* **Blank page / HTTP 500 on the API:** make sure MySQL is running, the `queue_tracking_db` database was created and imported, and `http://localhost/queue_system/backend/api/tickets.php` returns JSON.
* **"Invalid credentials":** check the username has no spaces (`staff1`, not `staff 1`) and use the default accounts above (passwords are case-sensitive).
* **Pages load but show no data from another device:** `BASE_URL` in `frontend/config.js` does not match the address you opened. Update it to your Serveo address and refresh.
* **No waiting time estimate:** the ML service is not running. Start it with `python model.py` and check `http://localhost:5001/health`.
* **502 when using Serveo:** Apache must be running locally, and the `ssh -R ...` window must stay open.
* **Serveo subdomain not available:** pick another name, then update the `ssh -R` command, `BASE_URL` in `frontend/config.js`, and `baseUrl` in the Flutter app.
* **Moving the project to another PC:** delete the generated files `backend/config/.pwd_migrated` and `backend/config/.auth_secret` if they exist; they are recreated automatically.

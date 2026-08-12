# Quick Start Guide - Lavendia

Get the Lavendia platform running in 5 minutes!

## Prerequisites

- Python 3.8+ installed
- Flutter SDK installed (for mobile development)
- Git (optional)

## Backend Setup (5 steps)

### 1. Navigate to backend
```bash
cd backend
```

### 2. Install dependencies
```bash
python -m venv venv
venv\Scripts\activate  # Windows
# OR
source venv/bin/activate  # Mac/Linux

pip install -r requirements.txt
```

### 3. Run migrations
```bash
python manage.py migrate
```

### 4. Create test data
```bash
python manage.py create_test_data
```

This creates:
- Admin user: `admin` / `admin123`
- Staff users: `staff1`, `staff2` / `staff123`
- Customer users: `customer1`, `customer2` / `customer123`
- 2 laundromats
- 3 sample receipts

### 5. Start server
```bash
python manage.py runserver
```

**Done!** Backend is running at http://localhost:8000

## Test the API

### Option 1: Swagger UI (Easiest)
Open http://localhost:8000/api/docs/ in your browser

### Option 2: cURL

1. **Login:**
```bash
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"admin\", \"password\": \"admin123\"}"
```

2. **Get Receipts:** (use token from login response)
```bash
curl http://localhost:8000/api/receipts/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN_HERE"
```

### Option 3: Django Admin
Open http://localhost:8000/admin/
Login with: `admin` / `admin123`

## What's Next?

### For Backend Development:
- Read [backend/README.md](backend/README.md)
- Check [backend/API_ENDPOINTS.md](backend/API_ENDPOINTS.md) for all endpoints
- Explore the code in `backend/apps/`

### For Mobile Development:
```bash
flutter pub get
flutter run
```

### Pointing the app at your backend

The API base URL defaults to `http://10.0.2.2:8000/api` (the Android
emulator's alias for your host machine). Override it per-run without editing
any source file:

```bash
# iOS simulator
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api

# Physical device on the same Wi-Fi (use your machine's LAN IP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api

# Production build
flutter build apk --dart-define=API_BASE_URL=https://api.example.com/api
```

**For the LAN case the backend needs two changes too.** `runserver` binds
`127.0.0.1` by default, and Django rejects unknown `Host` headers with a 400:

```bash
ALLOWED_HOSTS=localhost,127.0.0.1,10.0.2.2,192.168.1.20 \
  python manage.py runserver 0.0.0.0:8000
```

(CORS is *not* involved — the Flutter client is native and sends no `Origin`
header. Don't widen `CORS_ALLOWED_ORIGINS` to try to fix a LAN problem.)

### Cleartext HTTP rules

Both platforms block plaintext HTTP by default:

| Build type | Android | iOS |
|---|---|---|
| debug | any host (permissive override) | loopback + local network |
| profile | loopback only | loopback + local network |
| release | loopback only | loopback + local network |

`10.0.2.2` is **not** allowlisted in release — it is a routable `10.x` address,
so a release build could otherwise leak tokens in cleartext on a corporate
Wi-Fi. The emulator only runs debug/profile builds.

`flutter run --profile` against a LAN IP will fail for this reason; use debug,
or add `android/app/src/profile/res/xml/network_security_config.xml`.

A release build with an `http://` URL throws at startup rather than shipping
silently — see the `kReleaseMode` guard in [lib/main.dart](lib/main.dart).

## Common Issues

### Issue: "Port 8000 already in use"
**Solution:** Kill the process using port 8000 or use a different port:
```bash
python manage.py runserver 8080
```

### Issue: "Module not found"
**Solution:** Make sure virtual environment is activated and dependencies are installed:
```bash
venv\Scripts\activate  # Windows
pip install -r requirements.txt
```

### Issue: "No such table"
**Solution:** Run migrations:
```bash
python manage.py migrate
```

## Project Structure Quick Reference

```
lavendia/
├── backend/
│   ├── apps/
│   │   ├── users/          # User management
│   │   ├── laundromats/    # Laundromat locations
│   │   ├── receipts/       # Receipt/order management
│   │   └── videos/         # Video uploads
│   ├── config/             # Django settings
│   ├── manage.py           # Django management
│   └── requirements.txt    # Python dependencies
└── mobile/                 # Flutter app (coming soon)
```

## Key API Endpoints

- **Login**: `POST /api/auth/login/`
- **Receipts**: `GET /api/receipts/`
- **Create Receipt**: `POST /api/receipts/`
- **Upload Video**: `POST /api/videos/`
- **My Profile**: `GET /api/users/me/`

Full documentation: http://localhost:8000/api/docs/

## Test Data Overview

After running `create_test_data`:

**Laundromats:**
1. Downtown Laundry - 123 Main St
2. Uptown Wash & Dry - 456 Park Ave

**Users:**
- 1 Admin (full access)
- 2 Staff members (one per laundromat)
- 2 Customers

**Receipts:**
- 3 sample receipts in various statuses

## Environment Configuration

Edit `backend/.env` to customize:
- `DEBUG=True` - Enable debug mode
- `SECRET_KEY` - Change for production
- `MAX_VIDEO_SIZE_MB=50` - Max video file size
- `VIDEO_RETENTION_DAYS=90` - How long to keep videos

## Need Help?

- Check [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) for architecture details
- Read [backend/README.md](backend/README.md) for backend documentation
- View [backend/API_ENDPOINTS.md](backend/API_ENDPOINTS.md) for API reference

---

**Happy Coding!** 🚀

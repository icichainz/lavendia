# Lavendia - Laundry Management Platform

A comprehensive digital platform for managing laundry services, featuring video verification, digital receipts, and role-based access control.

## Project Overview

Lavendia digitizes the laundry service workflow by replacing WhatsApp-based communication with a unified mobile and web platform. The system includes:

- **Mobile App** (Flutter) - Unified app for both customers and laundromat staff
- **Backend API** (Django REST Framework) - RESTful API with JWT authentication
- **Admin Dashboard** (TBD) - Web dashboard for administrative tasks

## Key Features

### MVP Features

1. **Digital Receipt Management**
   - Auto-generated unique receipt numbers with QR codes
   - Track receipt status (pending → washing → drying → ready → completed)
   - View receipt history

2. **Video Verification**
   - Upload intake videos when clothes are dropped off
   - Optional completion videos when ready
   - Video gallery for each receipt

3. **Push Notifications**
   - Real-time notifications when clothes are ready
   - Status update notifications

4. **Role-Based Access**
   - **Customers**: View their receipts and videos
   - **Staff**: Manage receipts for their laundromat
   - **Admin**: Full system access

5. **Multi-Laundromat Support**
   - Platform supports multiple laundromat locations
   - Staff assigned to specific locations

## Project Structure

```
lavendia/
├── mobile/              # Flutter mobile app
│   ├── lib/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── customer/
│   │   │   └── staff/
│   │   ├── models/
│   │   ├── services/
│   │   └── main.dart
│   └── pubspec.yaml
│
├── backend/             # Django REST Framework API
│   ├── apps/
│   │   ├── users/
│   │   ├── laundromats/
│   │   ├── receipts/
│   │   └── videos/
│   ├── config/
│   ├── requirements.txt
│   ├── README.md
│   └── API_ENDPOINTS.md
│
└── admin_dashboard/     # Web admin (TBD)
```

## Technology Stack

### Backend
- **Django 4.2** - Web framework
- **Django REST Framework** - API development
- **SQLite** (dev) / **PostgreSQL** (prod) - Database
- **JWT** - Authentication
- **Pillow** - Image processing
- **QR Code** - QR code generation
- **drf-spectacular** - API documentation

### Mobile
- **Flutter** - Cross-platform mobile development (iOS & Android)
- **Dart** - Programming language

### Planned Mobile Packages
- `provider` or `riverpod` - State management
- `dio` - HTTP client
- `camera` - Video recording
- `video_player` - Video playback
- `qr_flutter` - QR code display
- `mobile_scanner` - QR code scanning
- `firebase_messaging` - Push notifications

## Getting Started

### Backend Setup

1. Navigate to backend directory:
```bash
cd backend
```

2. Create virtual environment and install dependencies:
```bash
python -m venv venv
source venv/Scripts/activate  # Windows
pip install -r requirements.txt
```

3. Configure environment:
```bash
cp .env.example .env
# Edit .env with your settings
```

4. Run migrations:
```bash
python manage.py migrate
```

5. Create test data:
```bash
python manage.py create_test_data
```

6. Start development server:
```bash
python manage.py runserver
```

API will be available at: `http://localhost:8000/api/`

**Test Accounts:**
- Admin: `admin` / `admin123`
- Staff: `staff1`, `staff2` / `staff123`
- Customer: `customer1`, `customer2` / `customer123`

### Mobile Setup (Coming Soon)

```bash
cd mobile
flutter pub get
flutter run
```

## API Documentation

- **Swagger UI**: http://localhost:8000/api/docs/
- **Endpoints Reference**: [backend/API_ENDPOINTS.md](backend/API_ENDPOINTS.md)
- **Backend README**: [backend/README.md](backend/README.md)

## Data Model

### Core Entities

**User**
- Roles: Customer, Staff, Admin
- Staff members assigned to laundromats

**Laundromat**
- Multiple locations supported
- Has many staff members
- Has many receipts

**Receipt**
- Belongs to customer, staff, and laundromat
- Tracks status through workflow
- Auto-generates QR code
- Has videos attached

**Video**
- Types: Intake, Completion
- Belongs to receipt
- Max 50MB per video

### Status Flow

```
Receipt Created (pending)
    ↓
Washing (washing)
    ↓
Drying (drying)
    ↓
Ready for Pickup (ready)
    ↓
Completed (completed)
```

## Use Cases

### Customer Flow
1. Customer drops off clothes at laundromat
2. Staff creates receipt and records intake video
3. Customer receives digital receipt in app
4. Customer gets notification when clothes are ready
5. Customer arrives and shows QR code
6. Staff scans QR code and marks as completed

### Staff Flow
1. Customer arrives with clothes
2. Staff creates new receipt in app
3. Staff records video of clothes
4. Staff updates status as washing progresses
5. Staff marks as ready when complete
6. Staff scans customer's QR code at pickup

## Roadmap

### Phase 1: MVP (Current)
- ✅ Backend API
- ✅ Authentication
- ✅ Receipt management
- ✅ Video uploads
- ⏳ Mobile app UI
- ⏳ Push notifications

### Phase 2: Enhancements
- Payment processing
- SMS notifications
- Multiple photos per receipt
- Customer ratings/reviews
- Analytics dashboard

### Phase 3: Advanced Features
- AI-powered damage detection
- Subscription plans for regular customers
- Route optimization for pickup/delivery
- Multi-language support
- Integration with POS systems

## Environment Variables

Key configuration options (see [backend/.env.example](backend/.env.example)):

```env
DEBUG=True
SECRET_KEY=your-secret-key
ALLOWED_HOSTS=localhost,127.0.0.1
CORS_ALLOWED_ORIGINS=http://localhost:3000
MAX_VIDEO_SIZE_MB=50
VIDEO_RETENTION_DAYS=90
```

## Testing

### Backend Tests
```bash
cd backend
python manage.py test
```

### Mobile Tests
```bash
cd mobile
flutter test
```

## Deployment

### Backend Deployment
- Set `DEBUG=False`
- Configure PostgreSQL
- Set up AWS S3 for media storage
- Use gunicorn + nginx
- Enable HTTPS

### Mobile Deployment
- Build for production
- Submit to App Store / Google Play
- Configure Firebase for push notifications

## Contributing

This is a private project. For questions or issues, contact the development team.

## License

Proprietary - All rights reserved

## Contact

Developer: Your Name
Email: your.email@example.com

---

**Current Status**: Backend MVP completed, Mobile development next
**Last Updated**: December 3, 2025

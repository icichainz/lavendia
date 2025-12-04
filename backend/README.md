# Lavendia Backend API

Django REST Framework backend for the Laundry Management Platform.

## Setup

### 1. Create virtual environment and install dependencies

```bash
python -m venv venv
source venv/Scripts/activate  # On Windows
pip install -r requirements.txt
```

### 2. Configure environment variables

Copy `.env.example` to `.env` and update the values:

```bash
cp .env.example .env
```

### 3. Run migrations

```bash
python manage.py migrate
```

### 4. Create superuser

```bash
python manage.py createsuperuser
```

### 5. Run development server

```bash
python manage.py runserver
```

The API will be available at `http://localhost:8000/api/`

## API Endpoints

### Authentication

- `POST /api/auth/login/` - Login and get JWT tokens
- `POST /api/auth/refresh/` - Refresh access token

### Users

- `GET /api/users/` - List all users
- `POST /api/users/` - Create new user (registration)
- `GET /api/users/{id}/` - Get user details
- `PUT /api/users/{id}/` - Update user
- `DELETE /api/users/{id}/` - Delete user
- `GET /api/users/me/` - Get current user profile
- `PUT /api/users/update_profile/` - Update current user profile
- `POST /api/users/change_password/` - Change password
- `GET /api/users/customers/` - Get all customers
- `GET /api/users/staff/` - Get all staff members

### Laundromats

- `GET /api/laundromats/` - List all laundromats
- `POST /api/laundromats/` - Create new laundromat
- `GET /api/laundromats/{id}/` - Get laundromat details
- `PUT /api/laundromats/{id}/` - Update laundromat
- `DELETE /api/laundromats/{id}/` - Delete laundromat
- `GET /api/laundromats/{id}/receipts/` - Get all receipts for a laundromat
- `GET /api/laundromats/{id}/staff/` - Get all staff members for a laundromat

### Receipts

- `GET /api/receipts/` - List all receipts
- `POST /api/receipts/` - Create new receipt
- `GET /api/receipts/{id}/` - Get receipt details
- `PUT /api/receipts/{id}/` - Update receipt
- `DELETE /api/receipts/{id}/` - Delete receipt
- `GET /api/receipts/active/` - Get all active receipts
- `GET /api/receipts/my_receipts/` - Get current user's receipts
- `PATCH /api/receipts/{id}/update_status/` - Update receipt status
- `POST /api/receipts/{id}/complete/` - Mark receipt as completed
- `GET /api/receipts/{id}/qr_code/` - Get QR code for receipt

### Videos

- `GET /api/videos/` - List all videos
- `POST /api/videos/` - Upload new video
- `GET /api/videos/{id}/` - Get video details
- `PUT /api/videos/{id}/` - Update video
- `DELETE /api/videos/{id}/` - Delete video
- `GET /api/videos/by_receipt/?receipt_id={id}` - Get all videos for a receipt

### API Documentation

- `GET /api/docs/` - Swagger UI documentation
- `GET /api/schema/` - OpenAPI schema

## Authentication

All endpoints (except registration and login) require JWT authentication.

Include the access token in the Authorization header:

```
Authorization: Bearer <your_access_token>
```

### Login Example

```bash
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "your_username",
    "password": "your_password"
  }'
```

Response:
```json
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

## User Roles

- **Customer**: Can view their own receipts and videos
- **Staff**: Can view receipts and videos from their assigned laundromat
- **Admin**: Full access to all resources

## Receipt Status Flow

1. `pending` - Receipt created, clothes received
2. `washing` - Clothes being washed
3. `drying` - Clothes being dried
4. `ready` - Clothes ready for pickup
5. `completed` - Customer picked up clothes
6. `cancelled` - Receipt cancelled

## Video Types

- `intake` - Video recorded when customer drops off clothes
- `completion` - Video recorded when clothes are ready (optional)

## Database Models

### User
- username, email, phone, role
- laundromat (for staff members)

### Laundromat
- name, address, phone, email

### Receipt
- receipt_number (auto-generated)
- customer, staff, laundromat
- status, dates, items, price
- qr_code (auto-generated)

### Video
- receipt, video_type
- video_file, thumbnail, duration

## Admin Panel

Access the Django admin panel at `http://localhost:8000/admin/`

## Development

### Create new migrations

```bash
python manage.py makemigrations
python manage.py migrate
```

### Create test data

```bash
python manage.py shell
```

### Run tests

```bash
python manage.py test
```

## Production Deployment

1. Set `DEBUG=False` in `.env`
2. Set proper `SECRET_KEY`
3. Configure `ALLOWED_HOSTS`
4. Set up PostgreSQL database
5. Configure AWS S3 for media storage (optional)
6. Run `python manage.py collectstatic`
7. Use gunicorn: `gunicorn config.wsgi:application`

## Environment Variables

See `.env.example` for all available environment variables.

Key variables:
- `SECRET_KEY` - Django secret key
- `DEBUG` - Debug mode (True/False)
- `ALLOWED_HOSTS` - Comma-separated list of allowed hosts
- `CORS_ALLOWED_ORIGINS` - Comma-separated list of CORS origins
- `ACCESS_TOKEN_LIFETIME_MINUTES` - JWT access token lifetime
- `MAX_VIDEO_SIZE_MB` - Maximum video file size

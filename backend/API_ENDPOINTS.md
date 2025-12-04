# Lavendia API Endpoints

Complete API documentation for the Laundry Management Platform.

## Base URL

```
http://localhost:8000/api
```

## Authentication

All endpoints require JWT authentication (except registration and login).

Include the token in the Authorization header:
```
Authorization: Bearer <access_token>
```

---

## Authentication Endpoints

### Login
```
POST /api/auth/login/
```

**Request:**
```json
{
  "username": "admin",
  "password": "admin123"
}
```

**Response:**
```json
{
  "access": "eyJ0eXAiOiJKV1Q...",
  "refresh": "eyJ0eXAiOiJKV1Q..."
}
```

### Refresh Token
```
POST /api/auth/refresh/
```

**Request:**
```json
{
  "refresh": "eyJ0eXAiOiJKV1Q..."
}
```

---

## User Endpoints

### Register New User
```
POST /api/users/
```

**Request:**
```json
{
  "username": "newuser",
  "email": "user@example.com",
  "phone": "+1234567890",
  "password": "securepassword",
  "password_confirm": "securepassword",
  "role": "customer",
  "first_name": "John",
  "last_name": "Doe"
}
```

### Get Current User Profile
```
GET /api/users/me/
```

### Update Current User Profile
```
PUT /api/users/update_profile/
PATCH /api/users/update_profile/
```

**Request:**
```json
{
  "first_name": "Updated",
  "last_name": "Name",
  "email": "newemail@example.com"
}
```

### Change Password
```
POST /api/users/change_password/
```

**Request:**
```json
{
  "old_password": "oldpassword",
  "new_password": "newpassword",
  "new_password_confirm": "newpassword"
}
```

### Get All Customers
```
GET /api/users/customers/
```

### Get All Staff
```
GET /api/users/staff/
```

### List All Users (Admin)
```
GET /api/users/
```

**Query Parameters:**
- `role` - Filter by role (customer, staff, admin)
- `is_active` - Filter by active status (true/false)
- `laundromat` - Filter by laundromat ID
- `search` - Search by username, email, phone, name

---

## Laundromat Endpoints

### List All Laundromats
```
GET /api/laundromats/
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "Downtown Laundry",
    "address": "123 Main St, Downtown",
    "phone": "+1234567891",
    "is_active": true
  }
]
```

### Get Laundromat Details
```
GET /api/laundromats/{id}/
```

**Response:**
```json
{
  "id": 1,
  "name": "Downtown Laundry",
  "address": "123 Main St, Downtown",
  "phone": "+1234567891",
  "email": "downtown@lavendia.com",
  "is_active": true,
  "staff_count": 2,
  "active_receipts_count": 5,
  "created_at": "2025-12-03T15:36:05.000Z",
  "updated_at": "2025-12-03T15:36:05.000Z"
}
```

### Create Laundromat
```
POST /api/laundromats/
```

**Request:**
```json
{
  "name": "New Laundry",
  "address": "789 Street Ave",
  "phone": "+1234567890",
  "email": "new@lavendia.com"
}
```

### Update Laundromat
```
PUT /api/laundromats/{id}/
PATCH /api/laundromats/{id}/
```

### Delete Laundromat
```
DELETE /api/laundromats/{id}/
```

### Get Laundromat Receipts
```
GET /api/laundromats/{id}/receipts/
```

### Get Laundromat Staff
```
GET /api/laundromats/{id}/staff/
```

---

## Receipt Endpoints

### List All Receipts
```
GET /api/receipts/
```

**Query Parameters:**
- `status` - Filter by status (pending, washing, drying, ready, completed, cancelled)
- `laundromat` - Filter by laundromat ID
- `customer` - Filter by customer ID
- `staff` - Filter by staff ID
- `search` - Search by receipt number, customer username/phone

**Response:**
```json
[
  {
    "id": 1,
    "receipt_number": "LV-ABC12345",
    "customer_name": "customer1",
    "laundromat_name": "Downtown Laundry",
    "status": "pending",
    "drop_off_date": "2025-12-03T15:36:05.000Z",
    "expected_pickup_date": "2025-12-05T15:36:05.000Z",
    "price": "25.50"
  }
]
```

### Get Receipt Details
```
GET /api/receipts/{id}/
```

**Response:**
```json
{
  "id": 1,
  "receipt_number": "LV-ABC12345",
  "laundromat": {
    "id": 1,
    "name": "Downtown Laundry",
    "address": "123 Main St, Downtown",
    "phone": "+1234567891",
    "is_active": true
  },
  "customer": {
    "id": 2,
    "username": "customer1",
    "email": "customer1@example.com",
    "phone": "+1234567895",
    "role": "customer"
  },
  "staff": {
    "id": 3,
    "username": "staff1",
    "email": "staff1@lavendia.com",
    "role": "staff"
  },
  "status": "pending",
  "drop_off_date": "2025-12-03T15:36:05.000Z",
  "expected_pickup_date": "2025-12-05T15:36:05.000Z",
  "actual_pickup_date": null,
  "items_description": "3 shirts, 2 pants, 1 jacket",
  "items_count": 6,
  "special_instructions": "Please use gentle detergent",
  "price": "25.50",
  "qr_code": "/media/qr_codes/qr_LV-ABC12345.png",
  "qr_code_url": "http://localhost:8000/media/qr_codes/qr_LV-ABC12345.png",
  "videos": [],
  "is_active": true,
  "days_since_dropoff": 0
}
```

### Create Receipt
```
POST /api/receipts/
```

**Request:**
```json
{
  "customer_id": 2,
  "staff_id": 3,
  "laundromat_id": 1,
  "expected_pickup_date": "2025-12-05T15:00:00Z",
  "items_description": "3 shirts, 2 pants",
  "items_count": 5,
  "special_instructions": "Gentle wash",
  "price": 25.50
}
```

### Update Receipt Status
```
PATCH /api/receipts/{id}/update_status/
```

**Request:**
```json
{
  "status": "washing"
}
```

**Available statuses:**
- `pending` - Receipt created
- `washing` - Being washed
- `drying` - Being dried
- `ready` - Ready for pickup
- `completed` - Picked up
- `cancelled` - Cancelled

### Complete Receipt (Pickup)
```
POST /api/receipts/{id}/complete/
```

Marks the receipt as completed and sets the pickup date.

### Get Active Receipts
```
GET /api/receipts/active/
```

Returns all receipts that are not completed or cancelled.

### Get My Receipts
```
GET /api/receipts/my_receipts/
```

Returns all receipts for the current user.

### Get Receipt QR Code
```
GET /api/receipts/{id}/qr_code/
```

**Response:**
```json
{
  "qr_code_url": "http://localhost:8000/media/qr_codes/qr_LV-ABC12345.png",
  "receipt_number": "LV-ABC12345"
}
```

---

## Video Endpoints

### List All Videos
```
GET /api/videos/
```

**Query Parameters:**
- `video_type` - Filter by type (intake, completion)
- `receipt` - Filter by receipt ID

**Response:**
```json
[
  {
    "id": 1,
    "video_type": "intake",
    "thumbnail": "/media/thumbnails/2025/12/03/thumb.jpg",
    "duration": 15,
    "file_size_mb": 12.5,
    "uploaded_at": "2025-12-03T15:36:05.000Z"
  }
]
```

### Get Video Details
```
GET /api/videos/{id}/
```

**Response:**
```json
{
  "id": 1,
  "receipt": 1,
  "video_type": "intake",
  "video_file": "/media/videos/2025/12/03/video.mp4",
  "video_url": "http://localhost:8000/media/videos/2025/12/03/video.mp4",
  "thumbnail": "/media/thumbnails/2025/12/03/thumb.jpg",
  "duration": 15,
  "file_size": 13107200,
  "file_size_mb": 12.5,
  "uploaded_at": "2025-12-03T15:36:05.000Z",
  "updated_at": "2025-12-03T15:36:05.000Z"
}
```

### Upload Video
```
POST /api/videos/
```

**Request (multipart/form-data):**
```
receipt: 1
video_type: intake
video_file: <file>
thumbnail: <file> (optional)
duration: 15
```

**Video Types:**
- `intake` - Video recorded when customer drops off clothes
- `completion` - Video recorded when clothes are ready

**Supported formats:** .mp4, .avi, .mov, .mkv, .webm

**Max size:** 50MB (configurable in settings)

### Get Videos by Receipt
```
GET /api/videos/by_receipt/?receipt_id=1
```

Returns all videos for a specific receipt.

---

## API Documentation

### Swagger UI
```
GET /api/docs/
```

Interactive API documentation with request/response examples.

### OpenAPI Schema
```
GET /api/schema/
```

Download the OpenAPI schema in JSON format.

---

## Error Responses

All error responses follow this format:

```json
{
  "field_name": ["Error message"]
}
```

Or for non-field errors:

```json
{
  "detail": "Error message"
}
```

### Common HTTP Status Codes

- `200` - Success
- `201` - Created
- `204` - No Content (for successful DELETE)
- `400` - Bad Request (validation errors)
- `401` - Unauthorized (missing or invalid token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `500` - Internal Server Error

---

## Role-Based Access

### Customer
- Can view their own receipts and videos
- Can update their own profile
- Cannot create receipts (only staff can)

### Staff
- Can view receipts from their assigned laundromat
- Can create receipts
- Can upload videos
- Can update receipt status

### Admin
- Full access to all resources
- Can manage laundromats
- Can manage users
- Can view all receipts and videos

---

## Rate Limiting

No rate limiting is currently implemented in development.

For production, consider implementing rate limiting to prevent abuse.

---

## Pagination

List endpoints support pagination with the following query parameters:

- `page` - Page number (default: 1)
- `page_size` - Items per page (default: 20)

**Example:**
```
GET /api/receipts/?page=2&page_size=10
```

**Response:**
```json
{
  "count": 50,
  "next": "http://localhost:8000/api/receipts/?page=3",
  "previous": "http://localhost:8000/api/receipts/?page=1",
  "results": [...]
}
```

---

## Testing with cURL

### Login Example
```bash
curl -X POST http://localhost:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}'
```

### Get Receipts Example
```bash
curl http://localhost:8000/api/receipts/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Create Receipt Example
```bash
curl -X POST http://localhost:8000/api/receipts/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": 2,
    "staff_id": 3,
    "laundromat_id": 1,
    "expected_pickup_date": "2025-12-05T15:00:00Z",
    "items_description": "3 shirts",
    "items_count": 3,
    "price": 15.00
  }'
```

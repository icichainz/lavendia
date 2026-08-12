import 'package:flutter_test/flutter_test.dart';
import 'package:lavendia/models/receipt_model.dart';

/// A full receipt payload as the detail endpoint returns it.
Map<String, dynamic> fullReceiptJson() => {
      'id': 42,
      'receipt_number': 'LAV-000042',
      'laundromat': {
        'id': 1,
        'name': 'Downtown Laundry',
        'address': '123 Main St',
        'phone': '+15550001111',
        'is_active': true,
        'created_at': '2026-01-05T09:00:00Z',
        'updated_at': '2026-01-05T09:00:00Z',
      },
      'customer': {
        'id': 7,
        'username': 'customer1',
        'email': 'c1@example.com',
        'phone': '+15550002222',
        'role': 'customer',
        'first_name': 'Ada',
        'last_name': 'Lovelace',
        'is_active': true,
        'created_at': '2026-01-05T09:00:00Z',
        'updated_at': '2026-01-05T09:00:00Z',
      },
      'staff': {
        'id': 3,
        'username': 'staff1',
        'email': 's1@example.com',
        'phone': '+15550003333',
        'role': 'staff',
        'first_name': 'Grace',
        'last_name': 'Hopper',
        'laundromat': 1,
        'is_active': true,
        'created_at': '2026-01-05T09:00:00Z',
        'updated_at': '2026-01-05T09:00:00Z',
      },
      'status': 'washing',
      'drop_off_date': '2026-02-10T08:30:00Z',
      'expected_pickup_date': '2026-02-11T17:00:00Z',
      'actual_pickup_date': null,
      'items_description': '3 shirts, 2 trousers',
      'items_count': 5,
      'special_instructions': 'Cold wash only',
      'price': '24.50',
      'qr_code_url': 'http://example.com/qr/42.png',
      // VideoListSerializer - the nested shape. Note it carries no `receipt`,
      // `video_file` or `updated_at`; see backend/apps/videos/serializers.py.
      'videos': [
        {
          'id': 100,
          'video_type': 'intake',
          'thumbnail': '/media/thumbs/100.jpg',
          'duration': 95,
          'file_size_mb': 12.5,
          'uploaded_at': '2026-02-10T08:35:00Z',
        },
        {
          'id': 101,
          'video_type': 'completion',
          'thumbnail': '/media/thumbs/101.jpg',
          'duration': 40,
          'file_size_mb': 5.25,
          'uploaded_at': '2026-02-11T15:00:00Z',
        },
      ],
      'is_active': true,
      'days_since_dropoff': 1,
      'created_at': '2026-02-10T08:30:00Z',
      'updated_at': '2026-02-10T09:00:00Z',
    };

/// Exactly what ReceiptListSerializer emits - ten fields, no nested objects
/// and no foreign keys. See backend/apps/receipts/serializers.py.
Map<String, dynamic> listReceiptJson() => {
      'id': 43,
      'receipt_number': 'LV-000043',
      'customer_name': 'customer2',
      'laundromat_name': 'Uptown Wash & Dry',
      'status': 'ready',
      'drop_off_date': '2026-02-12T10:00:00Z',
      'expected_pickup_date': '2026-02-13T10:00:00Z',
      'price': '12.00',
      'items_count': 4,
      'items_description': '4 towels',
    };

/// A bare-foreign-key shape. No endpoint currently produces this, but
/// fromJson has an int branch for `laundromat`/`customer`/`staff`, so it is
/// pinned separately rather than smuggled into the list fixture.
Map<String, dynamic> bareForeignKeyJson() => {
      'id': 44,
      'receipt_number': 'LV-000044',
      'laundromat': 2,
      'customer': 8,
      'staff': 3,
      'status': 'pending',
      'drop_off_date': '2026-02-12T10:00:00Z',
      'expected_pickup_date': '2026-02-13T10:00:00Z',
      'price': 12,
    };

void main() {
  group('ReceiptModel.fromJson', () {
    test('parses a full detail payload', () {
      final receipt = ReceiptModel.fromJson(fullReceiptJson());

      expect(receipt.id, 42);
      expect(receipt.receiptNumber, 'LAV-000042');
      expect(receipt.status, 'washing');
      expect(receipt.itemsCount, 5);
      expect(receipt.specialInstructions, 'Cold wash only');
      expect(receipt.daysSinceDropoff, 1);
      expect(receipt.actualPickupDate, isNull);
      expect(receipt.dropOffDate, DateTime.parse('2026-02-10T08:30:00Z'));
    });

    test('parses price sent as a decimal string', () {
      // DRF serialises DecimalField as a string; a plain cast would throw.
      final receipt = ReceiptModel.fromJson(fullReceiptJson());
      expect(receipt.price, 24.50);
    });

    test('parses price on the list payload', () {
      final receipt = ReceiptModel.fromJson(listReceiptJson());
      expect(receipt.price, 12.0);
    });

    test('parses price sent as a bare number', () {
      final receipt = ReceiptModel.fromJson(bareForeignKeyJson());
      expect(receipt.price, 12.0);
    });

    test('expands a nested laundromat object', () {
      final receipt = ReceiptModel.fromJson(fullReceiptJson());

      expect(receipt.laundromat, isNotNull);
      expect(receipt.laundromat!.name, 'Downtown Laundry');
      // When the object is nested, the bare id field stays null.
      expect(receipt.laundromatId, isNull);
    });

    test('keeps bare foreign keys as ids', () {
      final receipt = ReceiptModel.fromJson(bareForeignKeyJson());

      expect(receipt.laundromatId, 2);
      expect(receipt.laundromat, isNull);
      expect(receipt.customerId, 8);
      expect(receipt.staffId, 3);
    });

    test('expands a nested customer object', () {
      final receipt = ReceiptModel.fromJson(fullReceiptJson());

      expect(receipt.customer, isNotNull);
      expect(receipt.customer!.fullName, 'Ada Lovelace');
      expect(receipt.customerId, isNull);
    });

    test('expands a nested staff object', () {
      // ReceiptSerializer declares staff = UserSerializer(read_only=True), so
      // it is always an object or null - never a bare id.
      final receipt = ReceiptModel.fromJson(fullReceiptJson());

      expect(receipt.staff, isNotNull);
      expect(receipt.staff!.username, 'staff1');
      expect(receipt.staff!.isStaff, isTrue);
      expect(receipt.staffId, isNull);
    });

    test('parses the list payload', () {
      // ReceiptListSerializer sends names rather than nested objects, and
      // omits videos, created_at and updated_at.
      final receipt = ReceiptModel.fromJson(listReceiptJson());

      expect(receipt.customerName, 'customer2');
      expect(receipt.laundromatName, 'Uptown Wash & Dry');
      expect(receipt.itemsDescription, '4 towels');
      expect(receipt.itemsCount, 4);
      expect(receipt.customer, isNull);
      expect(receipt.laundromat, isNull);
      expect(receipt.videos, isNull);
      expect(receipt.hasVideos, isFalse);
      expect(receipt.isActive, isTrue, reason: 'is_active defaults to true');
    });

    test('falls back to now when created_at is absent', () {
      // The list payload has no created_at, so fromJson substitutes
      // DateTime.now(). Assert the fallback actually fired - createdAt is
      // non-nullable, so isNotNull could never fail.
      final receipt = ReceiptModel.fromJson(listReceiptJson());

      expect(
        DateTime.now().difference(receipt.createdAt).inSeconds,
        lessThan(5),
      );
    });

    test('parses the nested video list', () {
      final receipt = ReceiptModel.fromJson(fullReceiptJson());

      expect(receipt.videos, hasLength(2));
      expect(receipt.hasVideos, isTrue);
      expect(receipt.videos!.first.videoType, 'intake');
    });

    test('back-fills the receipt id onto nested videos', () {
      // VideoListSerializer omits the receipt FK, and the local video cache
      // keys on it. Casting it unconditionally used to throw here, which
      // crashed the detail screen for any receipt that had a video.
      final receipt = ReceiptModel.fromJson(fullReceiptJson());

      expect(receipt.videos!.every((v) => v.receiptId == 42), isTrue);
    });

    test('nested videos survive the absent video_file and updated_at', () {
      final receipt = ReceiptModel.fromJson(fullReceiptJson());
      final video = receipt.videos!.first;

      expect(video.videoFileUrl, '');
      expect(video.updatedAt, video.uploadedAt);
      expect(video.thumbnailUrl, '/media/thumbs/100.jpg');
      expect(video.fileSizeMb, 12.5);
    });
  });

  group('status helpers', () {
    ReceiptModel withStatus(String status) =>
        ReceiptModel.fromJson(fullReceiptJson()..['status'] = status);

    test('exactly one predicate is true per known status', () {
      final cases = {
        'pending': (ReceiptModel r) => r.isPending,
        'washing': (ReceiptModel r) => r.isWashing,
        'drying': (ReceiptModel r) => r.isDrying,
        'ready': (ReceiptModel r) => r.isReady,
        'completed': (ReceiptModel r) => r.isCompleted,
        'cancelled': (ReceiptModel r) => r.isCancelled,
      };

      cases.forEach((status, predicate) {
        final receipt = withStatus(status);
        expect(predicate(receipt), isTrue, reason: 'expected $status to match');

        final others = cases.entries
            .where((e) => e.key != status)
            .where((e) => e.value(receipt))
            .map((e) => e.key);
        expect(others, isEmpty, reason: '$status also matched $others');
      });
    });

    test('statusDisplay maps every workflow status to a label', () {
      expect(withStatus('pending').statusDisplay, 'Pending');
      expect(withStatus('washing').statusDisplay, 'Washing');
      expect(withStatus('drying').statusDisplay, 'Drying');
      expect(withStatus('ready').statusDisplay, 'Ready for Pickup');
      expect(withStatus('completed').statusDisplay, 'Completed');
      expect(withStatus('cancelled').statusDisplay, 'Cancelled');
    });

    test('statusDisplay echoes an unknown status rather than throwing', () {
      expect(withStatus('quarantined').statusDisplay, 'quarantined');
    });
  });

  group('video accessors', () {
    test('finds the intake and completion videos', () {
      final receipt = ReceiptModel.fromJson(fullReceiptJson());

      expect(receipt.intakeVideo!.id, 100);
      expect(receipt.completionVideo!.id, 101);
    });

    test('returns null when the videos key is absent', () {
      final receipt = ReceiptModel.fromJson(listReceiptJson());

      expect(receipt.intakeVideo, isNull);
      expect(receipt.completionVideo, isNull);
    });

    test('returns null for an empty video list', () {
      // The previous orElse: () => videos!.first threw 'Bad state: No element'
      // here rather than returning null.
      final json = fullReceiptJson();
      json['videos'] = <Map<String, dynamic>>[];

      final receipt = ReceiptModel.fromJson(json);

      expect(receipt.intakeVideo, isNull);
      expect(receipt.completionVideo, isNull);
    });

    test('does not report a completion video as the intake video', () {
      // The old accessor fell back to videos!.first when no video matched,
      // so a completion-only receipt claimed to have an intake video.
      final json = fullReceiptJson();
      json['videos'] = [(json['videos'] as List).last];

      final receipt = ReceiptModel.fromJson(json);

      expect(receipt.intakeVideo, isNull);
      expect(receipt.completionVideo!.videoType, 'completion');
    });

    test('does not report an intake video as the completion video', () {
      final json = fullReceiptJson();
      json['videos'] = [(json['videos'] as List).first];

      final receipt = ReceiptModel.fromJson(json);

      expect(receipt.completionVideo, isNull);
      expect(receipt.intakeVideo!.videoType, 'intake');
    });
  });

  group('copyWith', () {
    test('overrides only the named field', () {
      final receipt = ReceiptModel.fromJson(fullReceiptJson());
      final updated = receipt.copyWith(status: 'ready');

      expect(updated.status, 'ready');
      expect(updated.id, receipt.id);
      expect(updated.receiptNumber, receipt.receiptNumber);
      expect(updated.price, receipt.price);
    });

    test('keeps the original value when nothing is passed', () {
      final receipt = ReceiptModel.fromJson(fullReceiptJson());
      final copy = receipt.copyWith();

      expect(copy.status, receipt.status);
      expect(copy.itemsCount, receipt.itemsCount);
    });
  });

  group('toJson', () {
    test('emits the fields the create endpoint expects', () {
      final receipt = ReceiptModel.fromJson(bareForeignKeyJson());
      final json = receipt.toJson();

      expect(json['customer_id'], 8);
      expect(json['staff_id'], 3);
      expect(json['laundromat_id'], 2);
      expect(json['price'], 12.0);
      expect(json['expected_pickup_date'], '2026-02-13T10:00:00.000Z');
    });
  });
}

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
      'staff': 3,
      'status': 'washing',
      'drop_off_date': '2026-02-10T08:30:00Z',
      'expected_pickup_date': '2026-02-11T17:00:00Z',
      'actual_pickup_date': null,
      'items_description': '3 shirts, 2 trousers',
      'items_count': 5,
      'special_instructions': 'Cold wash only',
      'price': '24.50',
      'qr_code_url': 'http://example.com/qr/42.png',
      'videos': [
        {
          'id': 100,
          'receipt': 42,
          'video_type': 'intake',
          'video_file': '/media/videos/intake_42.mp4',
          'duration': 95,
          'uploaded_at': '2026-02-10T08:35:00Z',
          'updated_at': '2026-02-10T08:35:00Z',
        },
        {
          'id': 101,
          'receipt': 42,
          'video_type': 'completion',
          'video_file': '/media/videos/done_42.mp4',
          'duration': 40,
          'uploaded_at': '2026-02-11T15:00:00Z',
          'updated_at': '2026-02-11T15:00:00Z',
        },
      ],
      'is_active': true,
      'days_since_dropoff': 1,
      'created_at': '2026-02-10T08:30:00Z',
      'updated_at': '2026-02-10T09:00:00Z',
    };

/// The trimmed shape the list endpoint returns - several fields absent.
Map<String, dynamic> minimalReceiptJson() => {
      'id': 43,
      'receipt_number': 'LAV-000043',
      'laundromat': 2,
      'customer': 8,
      'customer_name': 'Grace Hopper',
      'status': 'ready',
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

    test('parses price sent as a number', () {
      final receipt = ReceiptModel.fromJson(minimalReceiptJson());
      expect(receipt.price, 12.0);
    });

    test('expands a nested laundromat object', () {
      final receipt = ReceiptModel.fromJson(fullReceiptJson());

      expect(receipt.laundromat, isNotNull);
      expect(receipt.laundromat!.name, 'Downtown Laundry');
      // When the object is nested, the bare id field stays null.
      expect(receipt.laundromatId, isNull);
    });

    test('keeps a bare laundromat id as an id', () {
      final receipt = ReceiptModel.fromJson(minimalReceiptJson());

      expect(receipt.laundromatId, 2);
      expect(receipt.laundromat, isNull);
    });

    test('expands a nested customer object', () {
      final receipt = ReceiptModel.fromJson(fullReceiptJson());

      expect(receipt.customer, isNotNull);
      expect(receipt.customer!.fullName, 'Ada Lovelace');
      expect(receipt.customerId, isNull);
    });

    test('keeps a bare staff id as an id', () {
      final receipt = ReceiptModel.fromJson(fullReceiptJson());

      expect(receipt.staffId, 3);
      expect(receipt.staff, isNull);
    });

    test('tolerates the trimmed list payload', () {
      // items_description, items_count, videos, created_at and updated_at are
      // all absent from the list endpoint.
      final receipt = ReceiptModel.fromJson(minimalReceiptJson());

      expect(receipt.itemsDescription, '');
      expect(receipt.itemsCount, 0);
      expect(receipt.videos, isNull);
      expect(receipt.hasVideos, isFalse);
      expect(receipt.isActive, isTrue, reason: 'is_active defaults to true');
      expect(receipt.createdAt, isNotNull);
    });

    test('parses the nested video list', () {
      final receipt = ReceiptModel.fromJson(fullReceiptJson());

      expect(receipt.videos, hasLength(2));
      expect(receipt.hasVideos, isTrue);
      expect(receipt.videos!.first.videoType, 'intake');
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

    test('returns null when there are no videos at all', () {
      final receipt = ReceiptModel.fromJson(minimalReceiptJson());

      expect(receipt.intakeVideo, isNull);
      expect(receipt.completionVideo, isNull);
    });

    test(
      'KNOWN DEFECT: intakeVideo falls back to the first video of any type',
      () {
        // firstWhere(orElse: () => videos!.first) means a receipt holding only
        // a completion video reports that video as its intake video. This test
        // pins current behaviour so the quirk is visible; it should be flipped
        // to expect null when the accessor is fixed.
        final json = fullReceiptJson();
        json['videos'] = [(json['videos'] as List).last];

        final receipt = ReceiptModel.fromJson(json);

        expect(receipt.intakeVideo!.videoType, 'completion');
      },
    );
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
      final receipt = ReceiptModel.fromJson(minimalReceiptJson());
      final json = receipt.toJson();

      expect(json['items_description'], '');
      expect(json['items_count'], 0);
      expect(json['price'], 12.0);
      expect(json['expected_pickup_date'], isA<String>());
    });
  });
}

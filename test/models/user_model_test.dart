import 'package:flutter_test/flutter_test.dart';
import 'package:lavendia/models/user_model.dart';

Map<String, dynamic> userJson({
  String role = 'customer',
  String? firstName = 'Ada',
  String? lastName = 'Lovelace',
}) =>
    {
      'id': 7,
      'username': 'ada',
      'email': 'ada@example.com',
      'phone': '+15550002222',
      'role': role,
      'first_name': firstName,
      'last_name': lastName,
      'laundromat': role == 'staff' ? 2 : null,
      'laundromat_name': role == 'staff' ? 'Uptown Wash' : null,
      'is_active': true,
      'created_at': '2026-01-05T09:00:00Z',
      'updated_at': '2026-01-06T09:00:00Z',
    };

void main() {
  group('UserModel.fromJson', () {
    test('parses the API payload', () {
      final user = UserModel.fromJson(userJson());

      expect(user.id, 7);
      expect(user.username, 'ada');
      expect(user.email, 'ada@example.com');
      expect(user.phone, '+15550002222');
      expect(user.isActive, isTrue);
      expect(user.createdAt, DateTime.parse('2026-01-05T09:00:00Z'));
    });

    test('maps the laundromat foreign key for staff', () {
      final staff = UserModel.fromJson(userJson(role: 'staff'));

      expect(staff.laundromatId, 2);
      expect(staff.laundromatName, 'Uptown Wash');
    });

    test('defaults is_active to true when absent', () {
      final json = userJson()..remove('is_active');
      expect(UserModel.fromJson(json).isActive, isTrue);
    });
  });

  group('role predicates', () {
    test('customer matches only isCustomer', () {
      final user = UserModel.fromJson(userJson(role: 'customer'));

      expect(user.isCustomer, isTrue);
      expect(user.isStaff, isFalse);
      expect(user.isAdmin, isFalse);
    });

    test('staff matches only isStaff', () {
      final user = UserModel.fromJson(userJson(role: 'staff'));

      expect(user.isCustomer, isFalse);
      expect(user.isStaff, isTrue);
      expect(user.isAdmin, isFalse);
    });

    test('admin matches only isAdmin', () {
      final user = UserModel.fromJson(userJson(role: 'admin'));

      expect(user.isCustomer, isFalse);
      expect(user.isStaff, isFalse);
      expect(user.isAdmin, isTrue);
    });

    test('an unrecognised role matches nothing', () {
      // Routing keys off these predicates, so an unknown role must not be
      // silently treated as a customer.
      final user = UserModel.fromJson(userJson(role: 'auditor'));

      expect(user.isCustomer, isFalse);
      expect(user.isStaff, isFalse);
      expect(user.isAdmin, isFalse);
    });
  });

  group('fullName', () {
    test('joins both names', () {
      expect(UserModel.fromJson(userJson()).fullName, 'Ada Lovelace');
    });

    test('uses the first name alone when the last is missing', () {
      final user = UserModel.fromJson(userJson(lastName: null));
      expect(user.fullName, 'Ada');
    });

    test('uses the last name alone when the first is missing', () {
      final user = UserModel.fromJson(userJson(firstName: null));
      expect(user.fullName, 'Lovelace');
    });

    test('falls back to the username when neither is set', () {
      final user = UserModel.fromJson(userJson(firstName: null, lastName: null));
      expect(user.fullName, 'ada');
    });
  });

  group('round trip', () {
    test('toJson then fromJson preserves identity fields', () {
      final original = UserModel.fromJson(userJson(role: 'staff'));
      final restored = UserModel.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.username, original.username);
      expect(restored.role, original.role);
      expect(restored.laundromatId, original.laundromatId);
      expect(restored.fullName, original.fullName);
    });
  });

  group('copyWith', () {
    test('changes only the named field', () {
      final user = UserModel.fromJson(userJson());
      final promoted = user.copyWith(role: 'staff');

      expect(promoted.role, 'staff');
      expect(promoted.isStaff, isTrue);
      expect(promoted.username, user.username);
      expect(promoted.email, user.email);
    });
  });
}

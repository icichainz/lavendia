import 'package:flutter_test/flutter_test.dart';
import 'package:lavendia/models/video_model.dart';

Map<String, dynamic> videoJson({
  String type = 'intake',
  int? duration = 95,
}) =>
    {
      'id': 100,
      'receipt': 42,
      'video_type': type,
      'video_file': '/media/videos/intake_42.mp4',
      'video_url': 'http://example.com/media/videos/intake_42.mp4',
      'thumbnail': '/media/thumbs/42.jpg',
      'duration': duration,
      'file_size': 1048576,
      'file_size_mb': 1,
      'uploaded_at': '2026-02-10T08:35:00Z',
      'updated_at': '2026-02-10T08:35:00Z',
    };

void main() {
  group('VideoModel.fromJson', () {
    test('parses the API payload', () {
      final video = VideoModel.fromJson(videoJson());

      expect(video.id, 100);
      expect(video.receiptId, 42);
      expect(video.videoType, 'intake');
      expect(video.videoFileUrl, '/media/videos/intake_42.mp4');
      expect(video.thumbnailUrl, '/media/thumbs/42.jpg');
      expect(video.fileSize, 1048576);
      expect(video.uploadedAt, DateTime.parse('2026-02-10T08:35:00Z'));
    });

    test('widens an integer file_size_mb to double', () {
      // The backend may serialise this as either int or float.
      expect(VideoModel.fromJson(videoJson()).fileSizeMb, 1.0);
    });

    test('accepts a null duration', () {
      expect(VideoModel.fromJson(videoJson(duration: null)).duration, isNull);
    });
  });

  group('type predicates', () {
    test('intake matches only isIntakeVideo', () {
      final video = VideoModel.fromJson(videoJson(type: 'intake'));

      expect(video.isIntakeVideo, isTrue);
      expect(video.isCompletionVideo, isFalse);
      expect(video.displayName, 'Intake Video');
    });

    test('completion matches only isCompletionVideo', () {
      final video = VideoModel.fromJson(videoJson(type: 'completion'));

      expect(video.isIntakeVideo, isFalse);
      expect(video.isCompletionVideo, isTrue);
      expect(video.displayName, 'Completion Video');
    });
  });

  group('durationFormatted', () {
    String formatted(int? seconds) =>
        VideoModel.fromJson(videoJson(duration: seconds)).durationFormatted;

    test('pads minutes and seconds', () {
      expect(formatted(95), '01:35');
      expect(formatted(5), '00:05');
      expect(formatted(600), '10:00');
    });

    test('renders zero as 00:00', () {
      expect(formatted(0), '00:00');
    });

    test('falls back to 00:00 when duration is unknown', () {
      expect(formatted(null), '00:00');
    });

    test('does not wrap past an hour', () {
      // 3661s renders as 61:01 rather than 01:01:01 - minutes simply grow.
      expect(formatted(3661), '61:01');
    });
  });

  group('copyWith', () {
    test('changes only the named field', () {
      final video = VideoModel.fromJson(videoJson());
      final updated = video.copyWith(videoType: 'completion');

      expect(updated.videoType, 'completion');
      expect(updated.isCompletionVideo, isTrue);
      expect(updated.id, video.id);
      expect(updated.receiptId, video.receiptId);
    });
  });
}

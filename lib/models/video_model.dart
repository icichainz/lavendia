class VideoModel {
  final int id;
  final int receiptId;
  final String videoType; // intake or completion
  final String videoFileUrl;
  final String? videoUrl; // Full URL from backend
  final String? thumbnailUrl;
  final int? duration; // in seconds
  final int? fileSize; // in bytes
  final double? fileSizeMb;
  final DateTime uploadedAt;
  final DateTime updatedAt;

  VideoModel({
    required this.id,
    required this.receiptId,
    required this.videoType,
    required this.videoFileUrl,
    this.videoUrl,
    this.thumbnailUrl,
    this.duration,
    this.fileSize,
    this.fileSizeMb,
    required this.uploadedAt,
    required this.updatedAt,
  });

  // Check video type
  bool get isIntakeVideo => videoType == 'intake';
  bool get isCompletionVideo => videoType == 'completion';

  // Get display name
  String get displayName {
    return videoType == 'intake' ? 'Intake Video' : 'Completion Video';
  }

  // Get duration formatted
  String get durationFormatted {
    if (duration == null) return '00:00';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Build from any of the three shapes the API emits.
  ///
  /// `VideoSerializer` (GET /videos/{id}/, /videos/by_receipt/) sends every
  /// field. `VideoListSerializer`, used for the nested `videos` array on a
  /// receipt, sends only id, video_type, thumbnail, duration, file_size_mb
  /// and uploaded_at - no `receipt`, `video_file` or `updated_at`. Casting
  /// those three unconditionally threw on every receipt that had a video,
  /// which crashed the receipt detail screen.
  ///
  /// [receiptId] supplies the parent id when the payload omits it, since the
  /// caller parsing a nested array already knows which receipt it belongs to.
  factory VideoModel.fromJson(Map<String, dynamic> json, {int? receiptId}) {
    final uploadedAt = DateTime.parse(json['uploaded_at'] as String);

    return VideoModel(
      id: json['id'] as int,
      receiptId: json['receipt'] as int? ?? receiptId ?? 0,
      videoType: json['video_type'] as String,
      videoFileUrl: json['video_file'] as String? ?? '',
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail'] as String?,
      duration: json['duration'] as int?,
      fileSize: json['file_size'] as int?,
      fileSizeMb: (json['file_size_mb'] as num?)?.toDouble(),
      uploadedAt: uploadedAt,
      // The list shape has no updated_at; a video is immutable once uploaded,
      // so uploadedAt is the honest stand-in.
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : uploadedAt,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receipt': receiptId,
      'video_type': videoType,
      'video_file': videoFileUrl,
      'thumbnail': thumbnailUrl,
      'duration': duration,
      'uploaded_at': uploadedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copy with
  VideoModel copyWith({
    int? id,
    int? receiptId,
    String? videoType,
    String? videoFileUrl,
    String? videoUrl,
    String? thumbnailUrl,
    int? duration,
    int? fileSize,
    double? fileSizeMb,
    DateTime? uploadedAt,
    DateTime? updatedAt,
  }) {
    return VideoModel(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      videoType: videoType ?? this.videoType,
      videoFileUrl: videoFileUrl ?? this.videoFileUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      fileSize: fileSize ?? this.fileSize,
      fileSizeMb: fileSizeMb ?? this.fileSizeMb,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

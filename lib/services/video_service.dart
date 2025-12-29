import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../models/video_model.dart';
import 'api_service.dart';

class VideoService {
  final _apiService = ApiService();
  final _logger = Logger();

  /// Get all videos for a receipt
  Future<Map<String, dynamic>> getReceiptVideos(int receiptId) async {
    try {
      final response = await _apiService.get(
        '/videos/by_receipt/',
        queryParameters: {'receipt_id': receiptId},
      );

      if (response.statusCode == 200) {
        final List<VideoModel> videos = (response.data as List)
            .map((video) => VideoModel.fromJson(video))
            .toList();

        return {
          'success': true,
          'videos': videos,
        };
      }

      return {
        'success': false,
        'message': 'Failed to fetch videos',
      };
    } on DioException catch (e) {
      _logger.e('Error fetching receipt videos: $e');
      return {
        'success': false,
        'message': _apiService.getErrorMessage(e),
      };
    } catch (e) {
      _logger.e('Unexpected error fetching videos: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Upload a video file
  ///
  /// Parameters:
  /// - [filePath]: Path to the video file on device
  /// - [receiptId]: ID of the receipt this video belongs to
  /// - [videoType]: Type of video ('intake' or 'completion')
  /// - [duration]: Duration of video in seconds (optional)
  /// - [onProgress]: Callback for upload progress (0.0 to 1.0)
  Future<Map<String, dynamic>> uploadVideo({
    required String filePath,
    required int receiptId,
    required String videoType,
    int? duration,
    Function(double)? onProgress,
  }) async {
    try {
      _logger.i('Uploading video: type=$videoType, receipt=$receiptId');

      // Prepare form data
      final formData = FormData.fromMap({
        'receipt': receiptId,
        'video_type': videoType,
        'video_file': await MultipartFile.fromFile(
          filePath,
          filename: 'video_${videoType}_${DateTime.now().millisecondsSinceEpoch}.mp4',
        ),
        if (duration != null) 'duration': duration,
      });

      // Upload with progress tracking
      final response = await _apiService.postWithProgress(
        '/videos/',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            final progress = sent / total;
            onProgress(progress);
            _logger.d('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
          }
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final video = VideoModel.fromJson(response.data);
        _logger.i('Video uploaded successfully: ${video.id}');

        return {
          'success': true,
          'video': video,
          'message': 'Video uploaded successfully',
        };
      }

      return {
        'success': false,
        'message': 'Failed to upload video',
      };
    } on DioException catch (e) {
      _logger.e('Error uploading video: ${e.message}');
      _logger.e('Response data: ${e.response?.data}');

      String errorMessage = _apiService.getErrorMessage(e);

      // Handle specific video upload errors
      if (e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map) {
          if (data.containsKey('video_file')) {
            errorMessage = data['video_file'][0] ?? errorMessage;
          } else if (data.containsKey('detail')) {
            errorMessage = data['detail'];
          } else if (data.containsKey('error')) {
            errorMessage = data['error'];
          }
        }
      }

      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      _logger.e('Unexpected error uploading video: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Delete a video
  Future<Map<String, dynamic>> deleteVideo(int videoId) async {
    try {
      final response = await _apiService.delete('/videos/$videoId/');

      if (response.statusCode == 204 || response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Video deleted successfully',
        };
      }

      return {
        'success': false,
        'message': 'Failed to delete video',
      };
    } on DioException catch (e) {
      _logger.e('Error deleting video: $e');
      return {
        'success': false,
        'message': _apiService.getErrorMessage(e),
      };
    } catch (e) {
      _logger.e('Unexpected error deleting video: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Get video details
  Future<Map<String, dynamic>> getVideoDetails(int videoId) async {
    try {
      final response = await _apiService.get('/videos/$videoId/');

      if (response.statusCode == 200) {
        final video = VideoModel.fromJson(response.data);

        return {
          'success': true,
          'video': video,
        };
      }

      return {
        'success': false,
        'message': 'Failed to fetch video details',
      };
    } on DioException catch (e) {
      _logger.e('Error fetching video details: $e');
      return {
        'success': false,
        'message': _apiService.getErrorMessage(e),
      };
    } catch (e) {
      _logger.e('Unexpected error fetching video details: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }
}

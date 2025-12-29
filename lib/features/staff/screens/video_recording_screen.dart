import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../services/video_service.dart';
import '../../shared/widgets/loading_indicator.dart';

class VideoRecordingScreen extends StatefulWidget {
  final int receiptId;
  final String videoType; // 'intake' or 'completion'

  const VideoRecordingScreen({
    super.key,
    required this.receiptId,
    required this.videoType,
  });

  @override
  State<VideoRecordingScreen> createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends State<VideoRecordingScreen> {
  CameraController? _cameraController;
  final _videoService = VideoService();
  final _imagePicker = ImagePicker();

  bool _isRecording = false;
  bool _isUploading = false;
  bool _isCameraInitialized = false;
  double _uploadProgress = 0.0;
  String? _recordedVideoPath;
  int _recordingDuration = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('No camera found on this device');
        return;
      }

      // Use back camera by default
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isRecording) {
      // Stop recording
      try {
        final video = await _cameraController!.stopVideoRecording();
        setState(() {
          _isRecording = false;
          _recordedVideoPath = video.path;
        });
      } catch (e) {
        _showError('Failed to stop recording: $e');
      }
    } else {
      // Start recording
      try {
        await _cameraController!.startVideoRecording();
        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
        });

        // Update recording duration every second
        _updateRecordingDuration();
      } catch (e) {
        _showError('Failed to start recording: $e');
      }
    }
  }

  void _updateRecordingDuration() {
    if (!_isRecording) return;

    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording && mounted) {
        setState(() {
          _recordingDuration++;
        });
        _updateRecordingDuration();
      }
    });
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null && mounted) {
        setState(() {
          _recordedVideoPath = video.path;
        });
      }
    } catch (e) {
      _showError('Failed to pick video: $e');
    }
  }

  Future<void> _uploadVideo() async {
    if (_recordedVideoPath == null) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      final result = await _videoService.uploadVideo(
        filePath: _recordedVideoPath!,
        receiptId: widget.receiptId,
        videoType: widget.videoType,
        duration: _recordingDuration > 0 ? _recordingDuration : null,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('video_uploaded_successfully')),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      } else {
        _showError(result['message'] ?? l10n.translate('video_upload_failed'));
      }
    } catch (e) {
      _showError('Error uploading video: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _discardVideo() {
    setState(() {
      _recordedVideoPath = null;
      _recordingDuration = 0;
    });
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final videoTypeLabel = widget.videoType == 'intake'
        ? l10n.translate('intake_video')
        : l10n.translate('completion_video');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('record_video')),
        actions: [
          if (_recordedVideoPath != null && !_isUploading)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _discardVideo,
              tooltip: l10n.translate('discard_video'),
            ),
        ],
      ),
      body: _buildBody(l10n, videoTypeLabel),
    );
  }

  Widget _buildBody(AppLocalizations l10n, String videoTypeLabel) {
    if (_isUploading) {
      return _buildUploadingView(l10n);
    }

    if (_recordedVideoPath != null) {
      return _buildPreviewView(l10n, videoTypeLabel);
    }

    if (!_isCameraInitialized) {
      return const Center(child: LoadingIndicator());
    }

    return _buildCameraView(l10n, videoTypeLabel);
  }

  Widget _buildCameraView(AppLocalizations l10n, String videoTypeLabel) {
    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),

        // Video type indicator
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                videoTypeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        // Recording duration
        if (_isRecording)
          Positioned(
            top: 70,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_recordingDuration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery button
                IconButton(
                  onPressed: _isRecording ? null : _pickVideoFromGallery,
                  icon: const Icon(Icons.photo_library, size: 32),
                  color: Colors.white,
                ),

                // Record button
                GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _isRecording ? AppColors.error : Colors.white,
                          shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                          borderRadius: _isRecording ? BorderRadius.circular(8) : null,
                        ),
                      ),
                    ),
                  ),
                ),

                // Switch camera button
                IconButton(
                  onPressed: _isRecording ? null : _switchCamera,
                  icon: const Icon(Icons.flip_camera_ios, size: 32),
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _switchCamera() async {
    if (_cameraController == null) return;

    try {
      final cameras = await availableCameras();
      if (cameras.length < 2) return;

      final currentDirection = _cameraController!.description.lensDirection;
      final newCamera = cameras.firstWhere(
        (cam) => cam.lensDirection != currentDirection,
        orElse: () => cameras.first,
      );

      await _cameraController!.dispose();

      _cameraController = CameraController(
        newCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _showError('Failed to switch camera: $e');
    }
  }

  Widget _buildPreviewView(AppLocalizations l10n, String videoTypeLabel) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.video_file,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  videoTypeLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.translate('video_ready_upload'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (_recordingDuration > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.translate('duration')}: ${_formatDuration(_recordingDuration)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  File(_recordedVideoPath!).lengthSync() > 0
                      ? '${l10n.translate('file_size')}: ${(File(_recordedVideoPath!).lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB'
                      : '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploadVideo,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text(l10n.translate('upload_video')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _discardVideo,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.translate('record_again')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadingView(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LoadingIndicator(),
            const SizedBox(height: 24),
            Text(
              l10n.translate('uploading_video'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_uploadProgress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/receipt_provider.dart';
import '../../../models/receipt_model.dart';
import '../../../models/video_model.dart';
import '../../../services/video_service.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/screens/video_player_screen.dart';
import 'video_recording_screen.dart';

class ReceiptDetailStaffScreen extends StatefulWidget {
  final int receiptId;

  const ReceiptDetailStaffScreen({
    super.key,
    required this.receiptId,
  });

  @override
  State<ReceiptDetailStaffScreen> createState() => _ReceiptDetailStaffScreenState();
}

class _ReceiptDetailStaffScreenState extends State<ReceiptDetailStaffScreen> {
  final _videoService = VideoService();
  List<VideoModel> _videos = [];
  bool _loadingVideos = false;

  @override
  void initState() {
    super.initState();
    _loadReceiptDetail();
    _loadVideos();
  }

  Future<void> _loadReceiptDetail() async {
    final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
    await receiptProvider.fetchReceiptDetail(widget.receiptId);
  }

  Future<void> _loadVideos() async {
    setState(() => _loadingVideos = true);
    try {
      final result = await _videoService.getReceiptVideos(widget.receiptId);
      if (result['success'] && mounted) {
        setState(() {
          _videos = result['videos'] ?? [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loadingVideos = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orderDetails),
      ),
      body: Consumer<ReceiptProvider>(
        builder: (context, receiptProvider, child) {
          if (receiptProvider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          final receipt = receiptProvider.selectedReceipt;

          if (receipt == null) {
            return Center(
              child: Text(l10n.translate('receipt_not_found')),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadReceiptDetail,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReceiptHeader(receipt),
                  const SizedBox(height: 20),
                  _buildStatusCard(receipt),
                  const SizedBox(height: 20),
                  _buildCustomerCard(receipt),
                  const SizedBox(height: 20),
                  _buildItemsCard(receipt),
                  const SizedBox(height: 20),
                  if (receipt.specialInstructions?.isNotEmpty ?? false) ...[
                    _buildInstructionsCard(receipt),
                    const SizedBox(height: 20),
                  ],
                  _buildVideosSection(receipt),
                  const SizedBox(height: 24),
                  if (!receipt.isCompleted && receipt.status != 'cancelled')
                    _buildStatusActions(receipt),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceiptHeader(ReceiptModel receipt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.receipt_long,
              color: Theme.of(context).colorScheme.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receipt.receiptNumber,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(receipt.dropOffDate),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Text(
            '\$${receipt.price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ReceiptModel receipt) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.getStatusColor(receipt.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getStatusIcon(receipt.status),
              color: AppColors.getStatusColor(receipt.status),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('current_status'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  receipt.statusDisplay,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getStatusColor(receipt.status),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(ReceiptModel receipt) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.customer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(Icons.person, color: Theme.of(context).textTheme.bodySmall?.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.customerName ?? receipt.customer?.fullName ?? receipt.customer?.username ?? l10n.unknownCustomer,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (receipt.customer?.phone != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        receipt.customer?.phone ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(ReceiptModel receipt) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.items,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.itemsCount(receipt.itemsCount),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            receipt.itemsDescription,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 18, color: Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(width: 8),
              Text(
                '${l10n.expectedPickup}: ${_formatDateTime(receipt.expectedPickupDate)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(ReceiptModel receipt) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                l10n.specialInstructions,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            receipt.specialInstructions!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusActions(ReceiptModel receipt) {
    final l10n = AppLocalizations.of(context)!;
    final nextStatusValue = _getNextStatusValue(receipt.status);
    if (nextStatusValue == null) return const SizedBox.shrink();

    final nextStatusLabel = l10n.getStatusTranslation(nextStatusValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.translate('update_status'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _updateStatus(receipt.id, nextStatusValue),
          icon: Icon(_getStatusIcon(nextStatusValue)),
          label: Text('${l10n.translate('mark_as').replaceAll('{status}', '')} $nextStatusLabel'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: AppColors.getStatusColor(nextStatusValue),
          ),
        ),
      ],
    );
  }

  String? _getNextStatusValue(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return AppConstants.statusWashing;
      case 'washing':
        return AppConstants.statusDrying;
      case 'drying':
        return AppConstants.statusReady;
      case 'ready':
        return AppConstants.statusCompleted;
      default:
        return null;
    }
  }

  Future<void> _updateStatus(int receiptId, String newStatus) async {
    final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);

    final success = await receiptProvider.updateReceiptStatus(receiptId, newStatus);

    if (success && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('status_updated')),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(receiptProvider.errorMessage ?? l10n.translate('status_update_failed')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildVideosSection(ReceiptModel receipt) {
    final l10n = AppLocalizations.of(context)!;
    final intakeVideo = _videos.where((v) => v.videoType == 'intake').firstOrNull;
    final completionVideo = _videos.where((v) => v.videoType == 'completion').firstOrNull;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.videos,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              if (_loadingVideos)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Intake Video
          _buildVideoCard(
            l10n.translate('intake_video'),
            intakeVideo,
            'intake',
            Icons.video_camera_front,
            AppColors.primary,
          ),
          const SizedBox(height: 12),

          // Completion Video
          _buildVideoCard(
            l10n.translate('completion_video'),
            completionVideo,
            'completion',
            Icons.videocam,
            AppColors.statusReady,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(
    String title,
    VideoModel? video,
    String videoType,
    IconData icon,
    Color color,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                if (video != null) ...[
                  Text(
                    '${video.durationFormatted} • ${video.fileSizeMb?.toStringAsFixed(1) ?? '0'} MB',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ] else ...[
                  Text(
                    l10n.translate('no_videos'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (video != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_circle_outline),
                  color: color,
                  onPressed: () => _playVideo(video),
                  tooltip: l10n.translate('view_video'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                  onPressed: () => _confirmDeleteVideo(video),
                  tooltip: l10n.translate('delete_video'),
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed: () => _recordVideo(videoType),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.translate('add_video')),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _recordVideo(String videoType) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VideoRecordingScreen(
          receiptId: widget.receiptId,
          videoType: videoType,
        ),
      ),
    );

    if (result == true) {
      // Video was uploaded successfully, reload videos
      await _loadVideos();
    }
  }

  void _playVideo(VideoModel video) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(video: video),
      ),
    );
  }

  Future<void> _confirmDeleteVideo(VideoModel video) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('delete_video')),
        content: Text(l10n.translate('delete_video_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteVideo(video);
    }
  }

  Future<void> _deleteVideo(VideoModel video) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await _videoService.deleteVideo(video.id);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('video_deleted')),
          backgroundColor: AppColors.success,
        ),
      );
      await _loadVideos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? l10n.error),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'washing':
        return Icons.local_laundry_service;
      case 'drying':
        return Icons.dry_cleaning;
      case 'ready':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }
}

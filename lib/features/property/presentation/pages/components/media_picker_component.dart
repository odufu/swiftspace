import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;
import 'package:swiftspace/core/constants/app_constants.dart';
import 'package:swiftspace/core/services/audio_manager.dart';
import 'package:swiftspace/core/di/injection_container.dart';
import 'package:swiftspace/core/utils/ui_utils.dart';
import 'package:swiftspace/features/property/presentation/state/property_provider.dart';

class MediaPickerComponent extends StatefulWidget {
  final List<XFile> images;
  final XFile? video;
  final Function(List<XFile>) onImagesChanged;
  final Function(XFile?) onVideoChanged;

  const MediaPickerComponent({
    super.key,
    required this.images,
    this.video,
    required this.onImagesChanged,
    required this.onVideoChanged,
  });

  @override
  State<MediaPickerComponent> createState() => _MediaPickerComponentState();
}

class _MediaPickerComponentState extends State<MediaPickerComponent> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages(ImageSource source) async {
    List<XFile> pickedFiles = [];
    if (source == ImageSource.gallery) {
      pickedFiles = await _picker.pickMultiImage();
    } else {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) pickedFiles.add(pickedFile);
    }

    if (pickedFiles.isNotEmpty) {
      final newImages = [...widget.images, ...pickedFiles];
      if (newImages.length > 30) {
        if (mounted) {
          UiUtils.showError(context, 'Maximum 30 images allowed');
          final limited = newImages.sublist(0, 30);
          widget.onImagesChanged(limited);
          _triggerBackgroundUploads(pickedFiles); 
        }
      } else {
        widget.onImagesChanged(newImages);
        _triggerBackgroundUploads(pickedFiles);
      }
      if (mounted) sl<AudioManager>().playSuccess(context);
    }
  }

  void _triggerBackgroundUploads(List<XFile> files) {
    final provider = Provider.of<PropertyProvider>(context, listen: false);
    for (var file in files) {
      provider.startUpload(file);
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final pickedFile = await _picker.pickVideo(source: source);
    if (pickedFile != null) {
      final size = await pickedFile.length();
      if (size > 100 * 1024 * 1024) {
        if (mounted) UiUtils.showError(context, 'Video size exceeds 100MB limit');
        return;
      }
      widget.onVideoChanged(pickedFile);
      if (mounted) {
        Provider.of<PropertyProvider>(context, listen: false).startUpload(pickedFile, isVideo: true);
        sl<AudioManager>().playSuccess(context);
      }
    }
  }

  void _showPickerOptions({required bool isVideo}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(
              isVideo ? LucideIcons.image : LucideIcons.image,
              color: AppColors.primaryLight,
            ),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              if (isVideo) {
                _pickVideo(ImageSource.gallery);
              } else {
                _pickImages(ImageSource.gallery);
              }
            },
          ),
          ListTile(
            leading: Icon(
              isVideo ? LucideIcons.video : LucideIcons.camera,
              color: AppColors.primaryLight,
            ),
            title: Text(isVideo ? 'Capture with Camera' : 'Take a Photo'),
            onTap: () {
              Navigator.pop(context);
              if (isVideo) {
                _pickVideo(ImageSource.camera);
              } else {
                _pickImages(ImageSource.camera);
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Photos (5 - 30)', '${widget.images.length}/30'),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.images.length + 1,
            itemBuilder: (context, index) {
              if (index == widget.images.length) {
                return _buildAddButton(
                  () => _showPickerOptions(isVideo: false),
                  LucideIcons.camera,
                  'Add Photo',
                );
              }
              return _buildImagePreview(index);
            },
          ),
        ),
        if (widget.images.length < 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please add at least ${5 - widget.images.length} more images',
              style: TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        const SizedBox(height: 32),
        _buildSectionHeader('Video Walkthrough (Max 1)', widget.video == null ? '0/1' : '1/1'),
        const SizedBox(height: 12),
        widget.video == null
            ? _buildAddButton(
                () => _showPickerOptions(isVideo: true),
                LucideIcons.video,
                'Upload Video (Max 100MB)',
              )
            : _buildVideoPreview(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(count, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
      ],
    );
  }

  Widget _buildAddButton(VoidCallback onTap, IconData icon, String label) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 28),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(int index) {
    final image = widget.images[index];
    final provider = Provider.of<PropertyProvider>(context);
    final progress = provider.uploadProgress[image.path] ?? 0.0;
    final isUploaded = provider.uploadedUrls.containsKey(image.path);

    return Stack(
      children: [
        Container(
          width: 100,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: kIsWeb 
                ? NetworkImage(image.path)
                : FileImage(File(image.path)) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Progress Overlay
        if (!isUploaded && progress > 0)
          Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
          ),
        // Success indicator
        if (isUploaded)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: const Icon(LucideIcons.check, color: Colors.white, size: 10),
            ),
          ),
        Positioned(
          top: 4,
          right: 16,
          child: GestureDetector(
            onTap: () {
              final newImages = List<XFile>.from(widget.images)..removeAt(index);
              widget.onImagesChanged(newImages);
              Provider.of<PropertyProvider>(context, listen: false).removeMedia(image.path);
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(LucideIcons.x, color: Colors.white, size: 14),
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(4)),
              child: const Text('COVER', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    final video = widget.video!;
    final provider = Provider.of<PropertyProvider>(context);
    final progress = provider.uploadProgress[video.path] ?? 0.0;
    final isUploaded = provider.uploadedUrls.containsKey(video.path);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          if (isUploaded)
            const Icon(LucideIcons.checkCircle2, color: AppColors.primaryLight, size: 32)
          else 
            SizedBox(
              height: 32,
              width: 32,
              child: CircularProgressIndicator(value: progress, strokeWidth: 3),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isUploaded ? 'Video Uploaded' : 'Uploading Video...', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (!isUploaded)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: LinearProgressIndicator(value: progress),
                  ),
                Text(isUploaded ? 'Ready for processing' : '${(progress * 100).toInt()}% uploaded', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: Colors.red),
            onPressed: () {
              widget.onVideoChanged(null);
              provider.removeMedia(video.path);
            },
          ),
        ],
      ),
    );
  }
}

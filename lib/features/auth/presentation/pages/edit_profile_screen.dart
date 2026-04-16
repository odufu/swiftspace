import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../state/auth_provider.dart';
import '../../../../core/services/audio_manager.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/ui_utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  File? _imageFile;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<AuthProvider>(context, listen: false).profile;
    _nameController.text = profile?.fullName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    sl<AudioManager>().playClick(context);
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _save() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    sl<AudioManager>().playClick(context);

    try {
      await authProvider.updateProfile(
        fullName: _nameController.text.trim(),
        imagePath: _imageFile?.path,
      );

      if (mounted) {
        sl<AudioManager>().playSuccess(context);
        Navigator.pop(context);
        UiUtils.showSuccess(context, 'Profile updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        UiUtils.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          if (!authProvider.isLoading)
            TextButton(
              onPressed: _save,
              child: Text(
                'Save',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Avatar Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.colorScheme.primary, width: 3),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : (profile?.avatarUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(profile!.avatarUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                          ),
                          child: (_imageFile == null && profile?.avatarUrl == null)
                              ? const Icon(LucideIcons.user, size: 60, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.colorScheme.surface, width: 2),
                              ),
                              child: const Icon(LucideIcons.camera, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Name Field
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(LucideIcons.user, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email Field (Read-only)
                  TextField(
                    controller: TextEditingController(text: profile?.email ?? ''),
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(LucideIcons.mail, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Email cannot be changed',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
}

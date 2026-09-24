import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/r2_storage_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  final _authService = AuthService();
  final _r2Storage = R2StorageService();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  UserModel? _profile;
  File? _newAvatar;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getCurrentProfile();
    if (profile != null) {
      setState(() {
        _profile = profile;
        _nameController.text = profile.fullName ?? '';
        _usernameController.text = profile.username ?? '';
        _bioController.text = profile.bio ?? '';
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _newAvatar = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? avatarUrl = _profile?.avatarUrl;

      if (_newAvatar != null) {
        // কম্প্রেস + আপলোড
        avatarUrl = await _r2Storage.uploadImage(
          file: _newAvatar!,
          folder: 'avatars',
          isAvatar: true,
        );

        // পুরনো Supabase স্টোরেজ URL হলে ডিলিট
        final old = _profile?.avatarUrl;
        if (old != null &&
            old.isNotEmpty &&
            old.contains('supabase') &&
            old != avatarUrl) {
          try {
            await _storageService.deleteImage(old);
          } catch (_) {}
        }
      }

      await _authService.updateProfile(
        fullName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        avatarUrl: avatarUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('প্রোফাইল আপডেট হয়েছে')),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('সমস্যা: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোফাইল এডিট'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'সেভ',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    backgroundImage: _newAvatar != null
                        ? FileImage(_newAvatar!)
                        : (_profile?.avatarUrl != null
                            ? CachedNetworkImageProvider(_profile!.avatarUrl!)
                            : null) as ImageProvider?,
                    child: (_newAvatar == null && _profile?.avatarUrl == null)
                        ? Text(
                            (_nameController.text.isNotEmpty
                                    ? _nameController.text[0]
                                    : 'U')
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'নতুন ছবি সেভ করলে আগের ছবি মুছে যাবে • অটো কম্প্রেস',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'পূর্ণ নাম',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'নাম আবশ্যক' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'ইউজারনেম',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'ইউজারনেম আবশ্যক';
                if (v.contains(' ')) return 'স্পেস দেওয়া যাবে না';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'বায়ো (ঐচ্ছিক)',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.info_outline),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

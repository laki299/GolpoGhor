import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();

  final _authService = AuthService();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  UserModel? _profile;
  File? _newAvatarFile;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await _authService.getCurrentProfile();
    if (profile != null) {
      setState(() {
        _profile = profile;
        _fullNameController.text = profile.fullName ?? '';
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
      maxWidth: 1024,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() => _newAvatarFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profile == null) return;

    setState(() => _isSaving = true);

    try {
      String? avatarUrl = _profile!.avatarUrl;

      if (_newAvatarFile != null) {
        avatarUrl = await _storageService.uploadAvatar(
          imageFile: _newAvatarFile!,
          oldAvatarUrl: _profile!.avatarUrl,
        );
      }

      await _authService.updateProfile(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim().isEmpty
            ? null
            : _usernameController.text.trim(),
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

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('প্রোফাইল লোড করা যায়নি')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোফাইল এডিট'),
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
                    radius: 56,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    backgroundImage: _newAvatarFile != null
                        ? FileImage(_newAvatarFile!)
                        : (_profile!.avatarUrl != null
                            ? CachedNetworkImageProvider(_profile!.avatarUrl!)
                            : null) as ImageProvider?,
                    child: (_newAvatarFile == null &&
                            _profile!.avatarUrl == null)
                        ? Text(
                            (_profile!.fullName ?? 'U')[0].toUpperCase(),
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
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                        onPressed: _pickAvatar,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _pickAvatar,
                child: const Text('ছবি পরিবর্তন করুন'),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _fullNameController,
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
                prefixText: '@',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'বায়ো',
                prefixIcon: Icon(Icons.info_outline),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'নতুন ছবি সেভ করলে আগের প্রোফাইল ছবি স্বয়ংক্রিয় মুছে যাবে।',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

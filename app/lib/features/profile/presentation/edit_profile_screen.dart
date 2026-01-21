import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/auth_provider.dart';
import '../data/profile_repository.dart';
import '../domain/profile_model.dart';
import 'profile_screen.dart';

/// Provider pour l'etat d'edition du profil
final editProfileStateProvider =
    StateNotifierProvider<EditProfileNotifier, EditProfileState>((ref) {
  return EditProfileNotifier(ref);
});

/// Etat de l'edition du profil
class EditProfileState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final ProfileModel? profile;
  final File? newAvatarFile;

  const EditProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.profile,
    this.newAvatarFile,
  });

  EditProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    ProfileModel? profile,
    File? newAvatarFile,
  }) {
    return EditProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      profile: profile ?? this.profile,
      newAvatarFile: newAvatarFile ?? this.newAvatarFile,
    );
  }
}

/// Notifier pour gerer l'edition du profil
class EditProfileNotifier extends StateNotifier<EditProfileState> {
  final Ref _ref;

  EditProfileNotifier(this._ref) : super(const EditProfileState());

  ProfileRepository get _repository => _ref.read(profileRepositoryProvider);

  /// Charge le profil actuel
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final profile = await _repository.getCurrentProfile();
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Definit un nouvel avatar
  void setAvatarFile(File file) {
    state = state.copyWith(newAvatarFile: file);
  }

  /// Sauvegarde le profil
  Future<bool> saveProfile({
    required String name,
    String? bio,
    String? location,
    List<String>? interests,
  }) async {
    if (state.profile == null) return false;

    state = state.copyWith(isSaving: true, error: null);

    try {
      final userId = state.profile!.id;

      // Upload le nouvel avatar si present
      if (state.newAvatarFile != null) {
        await _repository.uploadAvatar(
          userId: userId,
          imageFile: state.newAvatarFile!,
        );
      }

      // Mettre a jour le profil
      await _repository.updateProfile(
        userId: userId,
        name: name,
        bio: bio,
        location: location,
        interests: interests,
      );

      // Rafraichir le profil
      _ref.invalidate(currentProfileProvider);

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

/// Ecran d'edition du profil
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();

  List<String> _selectedInterests = [];
  final List<String> _availableInterests = [
    'Sport',
    'Musique',
    'Art',
    'Tech',
    'Cuisine',
    'Voyage',
    'Gaming',
    'Lecture',
    'Cinema',
    'Nature',
    'Photo',
    'Danse',
  ];

  @override
  void initState() {
    super.initState();
    // Charger le profil au demarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editProfileStateProvider.notifier).loadProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _initializeControllers(ProfileModel profile) {
    if (_nameController.text.isEmpty) {
      _nameController.text = profile.name;
      _bioController.text = profile.bio ?? '';
      _locationController.text = profile.location ?? '';
      _selectedInterests = List.from(profile.user.interests);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      ref.read(editProfileStateProvider.notifier).setAvatarFile(
            File(pickedFile.path),
          );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(editProfileStateProvider.notifier).saveProfile(
          name: _nameController.text.trim(),
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          interests: _selectedInterests,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis a jour')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editProfileStateProvider);
    final theme = Theme.of(context);

    // Initialiser les controleurs quand le profil est charge
    if (state.profile != null) {
      _initializeControllers(state.profile!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        actions: [
          TextButton(
            onPressed: state.isSaving ? null : _saveProfile,
            child: state.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Erreur: ${state.error}'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          ref.read(editProfileStateProvider.notifier).loadProfile();
                        },
                        child: const Text('Reessayer'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Avatar
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: theme.colorScheme.primary,
                                backgroundImage: state.newAvatarFile != null
                                    ? FileImage(state.newAvatarFile!) as ImageProvider<Object>
                                    : state.profile?.avatarUrl != null
                                        ? CachedNetworkImageProvider(
                                            state.profile!.avatarUrl!,
                                          ) as ImageProvider<Object>
                                        : null,
                                child: state.newAvatarFile == null &&
                                        state.profile?.avatarUrl == null
                                    ? Text(
                                        state.profile?.initials ?? '?',
                                        style: theme.textTheme.headlineLarge?.copyWith(
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary,
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt),
                                    color: theme.colorScheme.onPrimary,
                                    onPressed: _pickImage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Nom
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom',
                            prefixIcon: Icon(Icons.person),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez entrer votre nom';
                            }
                            if (value.trim().length < 2) {
                              return 'Le nom doit contenir au moins 2 caracteres';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Bio
                        TextFormField(
                          controller: _bioController,
                          decoration: const InputDecoration(
                            labelText: 'Bio',
                            prefixIcon: Icon(Icons.info),
                            hintText: 'Parlez de vous...',
                          ),
                          maxLines: 3,
                          maxLength: 200,
                        ),

                        const SizedBox(height: 16),

                        // Localisation
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Ville',
                            prefixIcon: Icon(Icons.location_on),
                            hintText: 'Paris, France',
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Interets
                        Text(
                          'Centres d\'interet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Selectionnez vos centres d\'interet pour trouver des evenements qui vous correspondent.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableInterests.map((interest) {
                            final isSelected = _selectedInterests.contains(interest);
                            return FilterChip(
                              label: Text(interest),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedInterests.add(interest);
                                  } else {
                                    _selectedInterests.remove(interest);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 32),

                        // Message d'erreur
                        if (state.error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    state.error!,
                                    style: TextStyle(
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Bouton de sauvegarde
                        FilledButton(
                          onPressed: state.isSaving ? null : _saveProfile,
                          child: state.isSaving
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Enregistrement...'),
                                  ],
                                )
                              : const Text('Enregistrer les modifications'),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/profile_repository.dart';
import 'profile_model.dart';

/// Etat du profil utilisateur
class ProfileState {
  /// Profil charge
  final ProfileModel? profile;

  /// Indique si le profil est en cours de chargement
  final bool isLoading;

  /// Indique si une action est en cours (follow, update, etc.)
  final bool isActionLoading;

  /// Message d'erreur eventuel
  final String? error;

  /// Indique si le profil a ete modifie
  final bool isDirty;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.isActionLoading = false,
    this.error,
    this.isDirty = false,
  });

  /// Cree un etat initial de chargement
  const ProfileState.loading()
      : profile = null,
        isLoading = true,
        isActionLoading = false,
        error = null,
        isDirty = false;

  /// Cree un etat avec un profil charge
  ProfileState.loaded(ProfileModel this.profile)
      : isLoading = false,
        isActionLoading = false,
        error = null,
        isDirty = false;

  /// Cree un etat d'erreur
  ProfileState.error(String this.error)
      : profile = null,
        isLoading = false,
        isActionLoading = false,
        isDirty = false;

  /// Cree une copie avec des valeurs modifiees
  ProfileState copyWith({
    ProfileModel? profile,
    bool? isLoading,
    bool? isActionLoading,
    String? error,
    bool? isDirty,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      error: error,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  /// Indique si le profil est charge avec succes
  bool get isLoaded => profile != null && !isLoading && error == null;

  /// Indique si une erreur s'est produite
  bool get hasError => error != null;

  @override
  String toString() =>
      'ProfileState(profile: ${profile?.name}, isLoading: $isLoading, error: $error)';
}

/// Notifier pour la gestion du profil
class ProfileStateNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;
  final String? _userId;

  ProfileStateNotifier(this._ref, {String? userId})
      : _userId = userId,
        super(const ProfileState.loading()) {
    _loadProfile();
  }

  ProfileRepository get _repository => _ref.read(profileRepositoryProvider);

  /// Charge le profil
  Future<void> _loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final ProfileModel? profile;
      if (_userId != null) {
        profile = await _repository.getProfile(_userId!);
      } else {
        profile = await _repository.getCurrentProfile();
      }

      if (profile != null) {
        state = ProfileState.loaded(profile);
      } else {
        state = ProfileState.error('Profil non trouve');
      }
    } catch (e) {
      state = ProfileState.error(e.toString());
    }
  }

  /// Rafraichit le profil
  Future<void> refresh() async {
    await _loadProfile();
  }

  /// Met a jour les donnees du profil localement
  void updateLocal({
    String? name,
    String? bio,
    String? location,
    List<String>? interests,
  }) {
    if (state.profile == null) return;

    final updatedUser = state.profile!.user.copyWith(
      name: name,
      bio: bio,
      location: location,
      interests: interests,
    );

    state = state.copyWith(
      profile: state.profile!.copyWith(user: updatedUser),
      isDirty: true,
    );
  }

  /// Sauvegarde le profil sur le serveur
  Future<bool> save() async {
    if (state.profile == null || !state.isDirty) return false;

    state = state.copyWith(isActionLoading: true, error: null);

    try {
      final profile = state.profile!;
      final updatedProfile = await _repository.updateProfile(
        userId: profile.id,
        name: profile.name,
        bio: profile.bio,
        location: profile.location,
        interests: profile.user.interests,
      );

      state = state.copyWith(
        profile: updatedProfile,
        isActionLoading: false,
        isDirty: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isActionLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Met a jour le compteur de followers (apres follow/unfollow)
  void updateFollowStatus({
    required bool isFollowing,
    required int followersCount,
  }) {
    if (state.profile == null) return;

    state = state.copyWith(
      profile: state.profile!.copyWith(
        isFollowing: isFollowing,
        followersCount: followersCount,
      ),
    );
  }
}

/// Provider pour le repository de profil
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// Provider pour l'etat du profil de l'utilisateur connecte
final myProfileStateProvider =
    StateNotifierProvider<ProfileStateNotifier, ProfileState>((ref) {
  return ProfileStateNotifier(ref);
});

/// Provider pour l'etat du profil d'un utilisateur specifique
final userProfileStateProvider = StateNotifierProvider.family<
    ProfileStateNotifier, ProfileState, String>((ref, userId) {
  return ProfileStateNotifier(ref, userId: userId);
});

/// Actions sur le profil (follow, block, etc.)
enum ProfileAction {
  follow,
  unfollow,
  block,
  unblock,
  report,
}

/// Etat d'edition du profil
class EditProfileState {
  final String name;
  final String? bio;
  final String? location;
  final List<String> interests;
  final String? avatarPath;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final bool isValid;

  const EditProfileState({
    this.name = '',
    this.bio,
    this.location,
    this.interests = const [],
    this.avatarPath,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.isValid = false,
  });

  EditProfileState copyWith({
    String? name,
    String? bio,
    String? location,
    List<String>? interests,
    String? avatarPath,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool? isValid,
  }) {
    return EditProfileState(
      name: name ?? this.name,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      avatarPath: avatarPath ?? this.avatarPath,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      isValid: isValid ?? this.isValid,
    );
  }

  /// Valide les donnees du formulaire
  bool validate() {
    return name.trim().length >= 2;
  }
}

/// Notifier pour l'edition du profil
class EditProfileNotifier extends StateNotifier<EditProfileState> {
  final Ref _ref;

  EditProfileNotifier(this._ref) : super(const EditProfileState());

  ProfileRepository get _repository => _ref.read(profileRepositoryProvider);

  /// Initialise avec les donnees du profil existant
  Future<void> loadFromProfile() async {
    state = state.copyWith(isLoading: true);

    try {
      final profile = await _repository.getCurrentProfile();
      if (profile != null) {
        state = EditProfileState(
          name: profile.name,
          bio: profile.bio,
          location: profile.location,
          interests: profile.user.interests,
          isValid: true,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Profil non trouve');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Met a jour le nom
  void setName(String name) {
    state = state.copyWith(
      name: name,
      isValid: name.trim().length >= 2,
    );
  }

  /// Met a jour la bio
  void setBio(String? bio) {
    state = state.copyWith(bio: bio);
  }

  /// Met a jour la localisation
  void setLocation(String? location) {
    state = state.copyWith(location: location);
  }

  /// Met a jour les interets
  void setInterests(List<String> interests) {
    state = state.copyWith(interests: interests);
  }

  /// Ajoute un interet
  void addInterest(String interest) {
    if (!state.interests.contains(interest)) {
      state = state.copyWith(interests: [...state.interests, interest]);
    }
  }

  /// Supprime un interet
  void removeInterest(String interest) {
    state = state.copyWith(
      interests: state.interests.where((i) => i != interest).toList(),
    );
  }

  /// Met a jour le chemin de l'avatar
  void setAvatarPath(String? path) {
    state = state.copyWith(avatarPath: path);
  }

  /// Sauvegarde le profil
  Future<bool> save() async {
    if (!state.isValid) return false;

    state = state.copyWith(isSaving: true, error: null);

    try {
      final profile = await _repository.getCurrentProfile();
      if (profile == null) {
        state = state.copyWith(isSaving: false, error: 'Profil non trouve');
        return false;
      }

      await _repository.updateProfile(
        userId: profile.id,
        name: state.name.trim(),
        bio: state.bio?.trim(),
        location: state.location?.trim(),
        interests: state.interests,
      );

      // Rafraichir le provider du profil
      _ref.invalidate(myProfileStateProvider);

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

/// Provider pour l'edition du profil
final editProfileProvider =
    StateNotifierProvider.autoDispose<EditProfileNotifier, EditProfileState>((ref) {
  final notifier = EditProfileNotifier(ref);
  notifier.loadFromProfile();
  return notifier;
});

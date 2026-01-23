import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/location_provider.dart';
import '../data/event_repository.dart';

/// Provider pour le repository des evenements
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

/// Etat du formulaire de creation
class CreateEventState {
  final bool isLoading;
  final String? error;
  final int currentStep;
  final File? imageFile;
  final LatLng? selectedLocation;
  final String? selectedAddress;

  const CreateEventState({
    this.isLoading = false,
    this.error,
    this.currentStep = 0,
    this.imageFile,
    this.selectedLocation,
    this.selectedAddress,
  });

  CreateEventState copyWith({
    bool? isLoading,
    String? error,
    int? currentStep,
    File? imageFile,
    LatLng? selectedLocation,
    String? selectedAddress,
  }) {
    return CreateEventState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentStep: currentStep ?? this.currentStep,
      imageFile: imageFile ?? this.imageFile,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      selectedAddress: selectedAddress ?? this.selectedAddress,
    );
  }
}

/// Provider pour l'etat du formulaire
final createEventStateProvider =
    StateNotifierProvider<CreateEventNotifier, CreateEventState>((ref) {
  return CreateEventNotifier(ref);
});

/// Notifier pour gerer la creation d'evenement
class CreateEventNotifier extends StateNotifier<CreateEventState> {
  final Ref _ref;

  CreateEventNotifier(this._ref) : super(const CreateEventState());

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void setImage(File file) {
    state = state.copyWith(imageFile: file);
  }

  void setLocation(LatLng location, String address) {
    state = state.copyWith(
      selectedLocation: location,
      selectedAddress: address,
    );
  }

  Future<String?> createEvent({
    required String title,
    required String description,
    required String categoryId,
    required DateTime startDate,
    required DateTime endDate,
    required String locationError,
    required String notConnectedError,
    int? maxParticipants,
    int price = 0,
    List<String>? tags,
  }) async {
    if (state.selectedLocation == null) {
      state = state.copyWith(error: locationError);
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _ref.read(currentUserProvider.future);
      if (user == null) {
        state = state.copyWith(isLoading: false, error: notConnectedError);
        return null;
      }

      final repository = _ref.read(eventRepositoryProvider);

      // TODO: Upload l'image si presente

      final event = await repository.createEvent(
        title: title,
        description: description,
        organizerId: user.$id,
        organizerName: user.name,
        categoryId: categoryId,
        address: state.selectedAddress!,
        latitude: state.selectedLocation!.latitude,
        longitude: state.selectedLocation!.longitude,
        startDate: startDate,
        endDate: endDate,
        maxParticipants: maxParticipants,
        price: price,
        tags: tags,
      );

      state = state.copyWith(isLoading: false);
      return event.id;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

/// Ecran de creation d'evenement
class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _maxParticipantsController = TextEditingController();
  final _tagsController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1, hours: 2));
  String _selectedCategory = 'sport';
  bool _isFree = true;
  bool _hasMaxParticipants = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _maxParticipantsController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _getCategories(AppLocalizations l10n) {
    return [
      {'id': 'sport', 'name': l10n.categorySport},
      {'id': 'music', 'name': l10n.categoryMusic},
      {'id': 'art', 'name': l10n.categoryArt},
      {'id': 'tech', 'name': l10n.categoryTech},
      {'id': 'food', 'name': l10n.categoryFood},
      {'id': 'gaming', 'name': l10n.categoryGaming},
      {'id': 'outdoor', 'name': l10n.categoryOutdoor},
      {'id': 'social', 'name': l10n.categorySocial},
      {'id': 'other', 'name': l10n.categoryOther},
    ];
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      ref.read(createEventStateProvider.notifier).setImage(
            File(pickedFile.path),
          );
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startDate),
      );

      if (time != null) {
        setState(() {
          _startDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          // Ajuster la date de fin si necessaire
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(hours: 2));
          }
        });
      }
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endDate),
      );

      if (time != null) {
        setState(() {
          _endDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectLocation() async {
    final position = await ref.read(currentPositionProvider.future);
    final initialPosition = position != null
        ? LatLng(position.latitude, position.longitude)
        : const LatLng(48.8566, 2.3522);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LocationPickerSheet(
        initialPosition: initialPosition,
      ),
    );

    if (result != null) {
      ref.read(createEventStateProvider.notifier).setLocation(
            result['location'] as LatLng,
            result['address'] as String,
          );
      _addressController.text = result['address'] as String;
    }
  }

  Future<void> _createEvent() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final eventId = await ref.read(createEventStateProvider.notifier).createEvent(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          categoryId: _selectedCategory,
          startDate: _startDate,
          endDate: _endDate,
          maxParticipants:
              _hasMaxParticipants ? int.tryParse(_maxParticipantsController.text) : null,
          price: _isFree ? 0 : (int.tryParse(_priceController.text) ?? 0) * 100,
          tags: tags,
          locationError: l10n.pleaseSelectLocation,
          notConnectedError: l10n.notConnected,
        );

    if (eventId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventCreatedSuccess)),
      );
      context.go('/events/$eventId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createEventStateProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('EEE d MMM yyyy a HH:mm', 'fr_FR');
    final categories = _getCategories(l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createFug),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: Stepper(
          currentStep: state.currentStep,
          onStepContinue: () {
            if (state.currentStep < 3) {
              ref.read(createEventStateProvider.notifier).setStep(state.currentStep + 1);
            } else {
              _createEvent();
            }
          },
          onStepCancel: () {
            if (state.currentStep > 0) {
              ref.read(createEventStateProvider.notifier).setStep(state.currentStep - 1);
            }
          },
          onStepTapped: (step) {
            ref.read(createEventStateProvider.notifier).setStep(step);
          },
          controlsBuilder: (context, details) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Wrap(
                    spacing: 12,
                    children: [
                      if (state.currentStep < 3)
                        FilledButton(
                          onPressed: details.onStepContinue,
                          child: Text(l10n.continueBtn),
                        )
                      else
                        FilledButton(
                          onPressed: state.isLoading ? null : details.onStepContinue,
                          child: state.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(l10n.createEvent),
                        ),
                      if (state.currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: Text(l10n.back),
                        ),
                    ],
                  ),
                );
              },
            );
          },
          steps: [
            // Etape 1: Informations de base
            Step(
              title: Text(l10n.information),
              isActive: state.currentStep >= 0,
              state: state.currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  // Image
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        image: state.imageFile != null
                            ? DecorationImage(
                                image: FileImage(state.imageFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: state.imageFile == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 48,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.addImage,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Titre
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: l10n.eventTitle,
                      prefixIcon: const Icon(Icons.title),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.pleaseEnterTitle;
                      }
                      if (value.trim().length < 5) {
                        return l10n.titleTooShort;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: l10n.description,
                      prefixIcon: const Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    maxLength: 1000,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.pleaseEnterDescription;
                      }
                      if (value.trim().length < 20) {
                        return l10n.descriptionTooShort;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Categorie
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: l10n.category,
                      prefixIcon: const Icon(Icons.category),
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat['id'],
                        child: Text(cat['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            // Etape 2: Date et heure
            Step(
              title: Text(l10n.dateAndTime),
              isActive: state.currentStep >= 1,
              state: state.currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  // Date de debut
                  ListTile(
                    leading: const Icon(Icons.play_arrow),
                    title: Text(l10n.start),
                    subtitle: Text(dateFormat.format(_startDate)),
                    trailing: const Icon(Icons.edit),
                    onTap: _selectStartDate,
                  ),

                  const Divider(),

                  // Date de fin
                  ListTile(
                    leading: const Icon(Icons.stop),
                    title: Text(l10n.end),
                    subtitle: Text(dateFormat.format(_endDate)),
                    trailing: const Icon(Icons.edit),
                    onTap: _selectEndDate,
                  ),

                  const SizedBox(height: 16),

                  // Duree estimee
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(77),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${l10n.duration}: ${_formatDuration(_endDate.difference(_startDate))}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Etape 3: Lieu
            Step(
              title: Text(l10n.location),
              isActive: state.currentStep >= 2,
              state: state.currentStep > 2 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  // Adresse
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: l10n.address,
                      prefixIcon: const Icon(Icons.location_on),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.map),
                        onPressed: _selectLocation,
                      ),
                    ),
                    readOnly: true,
                    onTap: _selectLocation,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.pleaseSelectLocation;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Mini carte si position selectionnee
                  if (state.selectedLocation != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 150,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: state.selectedLocation!,
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.fug.app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: state.selectedLocation!,
                                  width: 40,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Etape 4: Options
            Step(
              title: Text(l10n.options),
              isActive: state.currentStep >= 3,
              content: Column(
                children: [
                  // Prix
                  SwitchListTile(
                    title: Text(l10n.freeEvent),
                    value: _isFree,
                    onChanged: (value) {
                      setState(() {
                        _isFree = value;
                      });
                    },
                  ),

                  if (!_isFree)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: l10n.priceEur,
                          prefixIcon: const Icon(Icons.euro),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (!_isFree && (value == null || value.isEmpty)) {
                            return l10n.pleaseEnterPrice;
                          }
                          return null;
                        },
                      ),
                    ),

                  const Divider(height: 32),

                  // Nombre max de participants
                  SwitchListTile(
                    title: Text(l10n.limitParticipants),
                    value: _hasMaxParticipants,
                    onChanged: (value) {
                      setState(() {
                        _hasMaxParticipants = value;
                      });
                    },
                  ),

                  if (_hasMaxParticipants)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextFormField(
                        controller: _maxParticipantsController,
                        decoration: InputDecoration(
                          labelText: l10n.maxParticipants,
                          prefixIcon: const Icon(Icons.people),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_hasMaxParticipants &&
                              (value == null || value.isEmpty)) {
                            return l10n.pleaseEnterNumber;
                          }
                          return null;
                        },
                      ),
                    ),

                  const Divider(height: 32),

                  // Tags
                  TextFormField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      labelText: l10n.tagsSeparatedByCommas,
                      prefixIcon: const Icon(Icons.tag),
                      hintText: 'sport, outdoor, football',
                    ),
                  ),

                  const SizedBox(height: 16),

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
                          Icon(Icons.error, color: theme.colorScheme.error),
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
                ],
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '${hours}h${minutes}min';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }
}

/// Bottom sheet pour selectionner un lieu sur la carte
class _LocationPickerSheet extends StatefulWidget {
  final LatLng initialPosition;

  const _LocationPickerSheet({required this.initialPosition});

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  late LatLng _selectedPosition;
  final MapController _mapController = MapController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
  }

  @override
  void dispose() {
    _mapController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(102),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Titre
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      l10n.selectLocation,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Champ d'adresse
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: l10n.address,
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.searchAddress,
                  ),
                  onSubmitted: (value) {
                    // TODO: Geocoder l'adresse
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Carte
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedPosition,
                    initialZoom: 15,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedPosition = point;
                      });
                      // TODO: Reverse geocoder la position
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.fug.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedPosition,
                          width: 50,
                          height: 50,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(77),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bouton confirmer
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'location': _selectedPosition,
                        'address': _addressController.text.isNotEmpty
                            ? _addressController.text
                            : 'Lat: ${_selectedPosition.latitude.toStringAsFixed(4)}, Lng: ${_selectedPosition.longitude.toStringAsFixed(4)}',
                      });
                    },
                    child: Text(l10n.confirmThisLocation),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

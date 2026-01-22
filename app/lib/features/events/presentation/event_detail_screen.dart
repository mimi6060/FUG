import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/events_provider.dart';
import '../domain/event_model.dart';
import '../../reports/domain/report_model.dart';
import '../../reports/presentation/widgets/report_content_sheet.dart';

/// Ecran de detail d'un evenement
class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: eventAsync.when(
        data: (event) {
          if (event == null) {
            return const Center(
              child: Text('Evenement non trouve'),
            );
          }

          final isOrganizer = currentUser.value?.$id == event.organizerId;

          return _EventDetailContent(
            event: event,
            isOrganizer: isOrganizer,
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Erreur: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(eventDetailProvider(eventId)),
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Contenu principal de l'ecran de detail
class _EventDetailContent extends ConsumerStatefulWidget {
  final EventModel event;
  final bool isOrganizer;

  const _EventDetailContent({
    required this.event,
    required this.isOrganizer,
  });

  @override
  ConsumerState<_EventDetailContent> createState() => _EventDetailContentState();
}

class _EventDetailContentState extends ConsumerState<_EventDetailContent> {
  bool _isJoining = false;
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = widget.event;

    return CustomScrollView(
      slivers: [
        // AppBar avec image
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: event.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: event.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.event, size: 80),
                    ),
                  )
                : Container(
                    color: theme.colorScheme.primaryContainer,
                    child: const Icon(Icons.event, size: 80),
                  ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareEvent(),
            ),
            // Menu contextuel avec options organisateur et signalement DSA
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    context.push('/events/${event.id}/edit');
                    break;
                  case 'delete':
                    _confirmDelete();
                    break;
                  case 'cancel':
                    _confirmCancel();
                    break;
                  case 'report':
                    _reportEvent();
                    break;
                }
              },
              itemBuilder: (context) => [
                // Options organisateur
                if (widget.isOrganizer) ...[
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Modifier'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: ListTile(
                      leading: Icon(Icons.cancel),
                      title: Text('Annuler l\'evenement'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                // Option signalement (DSA) - pour tous sauf l'organisateur
                if (!widget.isOrganizer)
                  const PopupMenuItem(
                    value: 'report',
                    child: ListTile(
                      leading: Icon(Icons.flag_outlined, color: Colors.orange),
                      title: Text('Signaler', style: TextStyle(color: Colors.orange)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Contenu
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (event.isFeatured)
                      _Badge(
                        icon: Icons.star,
                        label: 'Mis en avant',
                        color: Colors.amber,
                      ),
                    if (event.isFree)
                      _Badge(
                        icon: Icons.money_off,
                        label: 'Gratuit',
                        color: Colors.green,
                      ),
                    if (event.isFull)
                      _Badge(
                        icon: Icons.block,
                        label: 'Complet',
                        color: Colors.red,
                      ),
                    if (event.status == EventStatus.cancelled)
                      _Badge(
                        icon: Icons.cancel,
                        label: 'Annule',
                        color: Colors.red,
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                // Titre
                Text(
                  event.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // Categorie
                if (event.categoryName != null)
                  Chip(
                    label: Text(event.categoryName!),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                  ),

                const SizedBox(height: 24),

                // Informations principales
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.calendar_today,
                      title: 'Date',
                      value: _formatDateRange(event.startDate, event.endDate),
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.access_time,
                      title: 'Duree',
                      value: event.formattedDuration,
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.euro,
                      title: 'Prix',
                      value: event.formattedPrice,
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.people,
                      title: 'Participants',
                      value: event.maxParticipants != null
                          ? '${event.currentParticipants}/${event.maxParticipants}'
                          : '${event.currentParticipants}',
                      trailing: event.remainingSpots != null && event.remainingSpots! > 0
                          ? Text(
                              '${event.remainingSpots} places restantes',
                              style: TextStyle(
                                color: event.remainingSpots! <= 5
                                    ? Colors.orange
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Description
                Text(
                  'Description',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(event.description),

                const SizedBox(height: 24),

                // Lieu
                Text(
                  'Lieu',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Card(
                  child: Column(
                    children: [
                      // Mini carte
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: SizedBox(
                          height: 150,
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(event.latitude, event.longitude),
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
                                    point: LatLng(event.latitude, event.longitude),
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
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (event.venueName != null)
                              Text(
                                event.venueName!,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(event.address),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // TODO: Ouvrir dans Maps
                                },
                                icon: const Icon(Icons.directions),
                                label: const Text('Itineraire'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Organisateur
                Text(
                  'Organisateur',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(event.organizerName[0].toUpperCase()),
                    ),
                    title: Text(event.organizerName),
                    subtitle: const Text('Organisateur'),
                    trailing: OutlinedButton(
                      onPressed: () => context.push('/users/${event.organizerId}'),
                      child: const Text('Voir le profil'),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Tags
                if (event.tags.isNotEmpty) ...[
                  Text(
                    'Tags',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: event.tags.map((tag) {
                      return Chip(
                        label: Text('#$tag'),
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Bouton d'annulation de participation (pour les participants)
                _buildCancelParticipationButton(),

                // Espace pour le bouton flottant
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Construit le bouton d'annulation de participation pour les participants
  Widget _buildCancelParticipationButton() {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null) return const SizedBox.shrink();

    // Ne pas afficher si l'utilisateur est l'organisateur
    if (widget.isOrganizer) return const SizedBox.shrink();

    // Ne pas afficher si l'evenement est annule ou termine
    if (widget.event.status == EventStatus.cancelled ||
        widget.event.status == EventStatus.completed) {
      return const SizedBox.shrink();
    }

    final participationAsync = ref.watch(
      participationStatusProvider(
        (eventId: widget.event.id, userId: currentUser.$id),
      ),
    );

    return participationAsync.when(
      data: (isParticipating) {
        if (!isParticipating) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isCancelling ? null : _confirmCancelParticipation,
              icon: _isCancelling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel_outlined, color: Colors.orange),
              label: Text(
                _isCancelling ? 'Annulation...' : 'Annuler ma participation',
                style: const TextStyle(color: Colors.orange),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');

    if (start.day == end.day) {
      return '${dateFormat.format(start)}\n${timeFormat.format(start)} - ${timeFormat.format(end)}';
    } else {
      return 'Du ${dateFormat.format(start)} a ${timeFormat.format(start)}\nAu ${dateFormat.format(end)} a ${timeFormat.format(end)}';
    }
  }

  void _shareEvent() {
    final event = widget.event;
    Share.share(
      '${event.title}\n\n'
      '${_formatDateRange(event.startDate, event.endDate)}\n\n'
      '${event.address}\n\n'
      'Rejoins-moi sur FUG!',
      subject: event.title,
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'evenement'),
        content: const Text(
          'Etes-vous sur de vouloir supprimer cet evenement? '
          'Cette action est irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: Supprimer l'evenement
      context.pop();
    }
  }

  Future<void> _confirmCancel() async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler l\'evenement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Etes-vous sur de vouloir annuler cet evenement? '
              'Les participants seront notifies.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison (optionnel)',
                hintText: 'Ex: Probleme de sante, mauvais temps...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isCancelling = true);

      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur: utilisateur non connecte')),
          );
          setState(() => _isCancelling = false);
        }
        return;
      }

      final success = await ref.read(cancelEventProvider.notifier).cancel(
            eventId: widget.event.id,
            organizerId: currentUser.$id,
            reason: reasonController.text.isNotEmpty ? reasonController.text : null,
          );

      if (mounted) {
        setState(() => _isCancelling = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Evenement annule avec succes'),
              backgroundColor: Colors.green,
            ),
          );
          // Rafraichir les donnees
          ref.invalidate(eventDetailProvider(widget.event.id));
        } else {
          final error = ref.read(cancelEventProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Erreur lors de l\'annulation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmCancelParticipation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler ma participation'),
        content: const Text(
          'Etes-vous sur de vouloir annuler votre participation a cet evenement? '
          'L\'organisateur sera notifie.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isCancelling = true);

      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur: utilisateur non connecte')),
          );
          setState(() => _isCancelling = false);
        }
        return;
      }

      final success = await ref.read(cancelParticipationProvider.notifier).cancel(
            userId: currentUser.$id,
            eventId: widget.event.id,
          );

      if (mounted) {
        setState(() => _isCancelling = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Participation annulee'),
              backgroundColor: Colors.green,
            ),
          );
          // Rafraichir les donnees
          ref.invalidate(eventDetailProvider(widget.event.id));
        } else {
          final error = ref.read(cancelParticipationProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Erreur lors de l\'annulation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Signaler l'evenement (DSA compliance)
  void _reportEvent() {
    final event = widget.event;
    ReportContentSheet.show(
      context,
      contentType: ReportContentType.event,
      contentId: event.id,
      contentName: event.title,
    );
  }
}

/// Badge d'information
class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'informations
class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

/// Ligne d'information
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

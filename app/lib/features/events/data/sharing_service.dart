import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/event_model.dart';

/// Service for sharing events to external platforms
///
/// MOD-007: Modern Integrations - WhatsApp and Calendar
class SharingService {
  /// Deep link base URL for FUG app
  static const String _appDeepLinkBase = 'https://fug.app/event/';

  /// Share event to WhatsApp
  ///
  /// Opens WhatsApp with a pre-formatted message containing event details
  /// and a deep link to the event in the FUG app.
  static Future<bool> shareToWhatsApp(EventModel event) async {
    final dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');

    final formattedDate = dateFormat.format(event.startDate);
    final formattedTime = timeFormat.format(event.startDate);

    final text = '''
Je participe a "${event.title}" !
${event.venueName ?? event.address}
$formattedDate a $formattedTime

Rejoins-moi sur FUG: $_appDeepLinkBase${event.id}
''';

    final encodedText = Uri.encodeComponent(text.trim());
    final whatsappUrl = Uri.parse('https://wa.me/?text=$encodedText');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        return true;
      } else {
        // WhatsApp not installed, fallback to generic share
        return false;
      }
    } catch (e) {
      debugPrint('Error sharing to WhatsApp: $e');
      return false;
    }
  }

  /// Add event to device calendar
  ///
  /// Creates a calendar event with the event details using the native
  /// calendar app.
  static Future<bool> addToCalendar(EventModel event) async {
    final calendarEvent = Event(
      title: 'FUG: ${event.title}',
      description: event.description.isNotEmpty
          ? '${event.description}\n\nOrganise par: ${event.organizerName}'
          : 'Organise par: ${event.organizerName}',
      location: event.venueName != null
          ? '${event.venueName}, ${event.address}'
          : event.address,
      startDate: event.startDate,
      endDate: event.endDate,
      allDay: false,
    );

    try {
      final success = await Add2Calendar.addEvent2Cal(calendarEvent);
      return success;
    } catch (e) {
      debugPrint('Error adding to calendar: $e');
      return false;
    }
  }

  /// Generic share using system share sheet
  ///
  /// Uses share_plus to open the native share dialog.
  static Future<void> shareGeneric(EventModel event,
      {Rect? sharePositionOrigin}) async {
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');

    final formattedDate = dateFormat.format(event.startDate);
    final formattedStartTime = timeFormat.format(event.startDate);
    final formattedEndTime = timeFormat.format(event.endDate);

    final text = '''
${event.title}

$formattedDate
$formattedStartTime - $formattedEndTime

${event.venueName ?? event.address}

Rejoins-moi sur FUG!
$_appDeepLinkBase${event.id}
''';

    await Share.share(
      text.trim(),
      subject: event.title,
      sharePositionOrigin: sharePositionOrigin,
    );
  }
}

/// Share option types for the sharing bottom sheet
enum ShareOption {
  whatsapp,
  calendar,
  generic,
}

/// Widget for displaying share options in a bottom sheet
class ShareOptionsSheet extends StatelessWidget {
  final EventModel event;
  final VoidCallback? onWhatsAppNotAvailable;

  const ShareOptionsSheet({
    super.key,
    required this.event,
    this.onWhatsAppNotAvailable,
  });

  /// Show the share options bottom sheet
  static Future<void> show(
    BuildContext context, {
    required EventModel event,
    VoidCallback? onWhatsAppNotAvailable,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ShareOptionsSheet(
        event: event,
        onWhatsAppNotAvailable: onWhatsAppNotAvailable,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Partager l\'evenement',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // WhatsApp option
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat,
                  color: Color(0xFF25D366),
                ),
              ),
              title: const Text('WhatsApp'),
              subtitle: const Text('Partager avec tes contacts'),
              onTap: () => _shareToWhatsApp(context),
            ),

            // Calendar option
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: const Text('Ajouter au calendrier'),
              subtitle: const Text('Ne rate pas cet evenement'),
              onTap: () => _addToCalendar(context),
            ),

            // Generic share option
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.share,
                  color: theme.colorScheme.secondary,
                ),
              ),
              title: const Text('Autres options'),
              subtitle: const Text('Email, SMS, autres apps...'),
              onTap: () => _shareGeneric(context),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _shareToWhatsApp(BuildContext context) async {
    Navigator.pop(context);

    final success = await SharingService.shareToWhatsApp(event);

    if (!success && context.mounted) {
      // WhatsApp not available, show snackbar and fallback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp non disponible. Utilise une autre option.'),
          duration: Duration(seconds: 2),
        ),
      );
      onWhatsAppNotAvailable?.call();
    }
  }

  Future<void> _addToCalendar(BuildContext context) async {
    Navigator.pop(context);

    final success = await SharingService.addToCalendar(event);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evenement ajoute au calendrier'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ajouter au calendrier'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _shareGeneric(BuildContext context) async {
    Navigator.pop(context);
    await SharingService.shareGeneric(event);
  }
}

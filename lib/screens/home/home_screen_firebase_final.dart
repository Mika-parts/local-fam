import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider_firebase.dart';
import '../../providers/auth_provider.dart';
import '../../models/event.dart';
import '../events/add_event_screen.dart';

class FirebaseFinalHomeScreen extends StatefulWidget {
  const FirebaseFinalHomeScreen({super.key});

  @override
  State<FirebaseFinalHomeScreen> createState() => _FirebaseFinalHomeScreenState();
}

class _FirebaseFinalHomeScreenState extends State<FirebaseFinalHomeScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  int _pendingRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<FamAuthProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProviderFirebase>(context, listen: false);
      
      if (authProvider.currentUser?.familyId != null) {
        // Démarrer l'écoute en temps réel des événements
        eventProvider.listenToFamilyEvents(authProvider.currentUser!.familyId);
        
        // Charger le nombre de demandes en attente
        _loadPendingRequestsCount();
        
        // Écouter les changements de demandes
        _listenToPendingRequests();
      }
    });
  }

  Future<void> _loadPendingRequestsCount() async {
    final authProvider = Provider.of<FamAuthProvider>(context, listen: false);
    final count = await authProvider.countPendingRequests();
    if (mounted) {
      setState(() {
        _pendingRequestsCount = count;
      });
    }
  }

  void _listenToPendingRequests() {
    final authProvider = Provider.of<FamAuthProvider>(context, listen: false);
    authProvider.getFamilyRequestsStream().listen((requests) {
      if (mounted) {
        setState(() {
          _pendingRequestsCount = requests.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<FamAuthProvider, EventProviderFirebase>(
      builder: (context, authProvider, eventProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text('FamAgenda'),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_done, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            actions: [
              // Notifications (demandes en attente)
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: _showNotifications,
                    tooltip: 'Demandes d\'accès',
                  ),
                  if (_pendingRequestsCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_pendingRequestsCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              // Menu profil
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'share':
                      _showShareDialog(authProvider);
                      break;
                    case 'members':
                      _showMembersDialog(authProvider);
                      break;
                    case 'regenerate_code':
                      _regenerateInviteCode(authProvider);
                      break;
                    case 'profile':
                      _showProfileDialog(authProvider);
                      break;
                    case 'logout':
                      _handleLogout(authProvider);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Partager l\'agenda'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'members',
                    child: Row(
                      children: [
                        Icon(Icons.group, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Membres famille'),
                      ],
                    ),
                  ),
                  if (authProvider.canModifyFamily())
                    const PopupMenuItem(
                      value: 'regenerate_code',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Nouveau code'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text('Mon profil'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Déconnexion', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Infos famille avec code
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.family_restroom,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authProvider.currentFamily?.name ?? 'Ma Famille',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${authProvider.familyMembers.length} membre(s) • Code: ${authProvider.familyInviteCode ?? 'N/A'}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bouton partage rapide
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showShareDialog(authProvider),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.share,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Partager',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Calendrier et événements
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TableCalendar<Event>(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                            calendarFormat: _calendarFormat,
                            eventLoader: (day) {
                              return eventProvider.getEventsForDay(day);
                            },
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            onFormatChanged: (format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            },
                            onPageChanged: (focusedDay) {
                              setState(() {
                                _focusedDay = focusedDay;
                              });
                              // Charger les événements du mois
                              if (authProvider.currentUser?.familyId != null) {
                                eventProvider.loadFamilyEventsForMonth(
                                  authProvider.currentUser!.familyId,
                                  focusedDay,
                                );
                              }
                            },
                            calendarStyle: CalendarStyle(
                              outsideDaysVisible: false,
                              selectedDecoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              markerDecoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: true,
                              titleCentered: true,
                              formatButtonShowsNext: false,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Liste des événements du jour sélectionné
                      Expanded(
                        child: eventProvider.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _buildEventsList(eventProvider, authProvider),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: authProvider.canCreateEvents()
              ? FloatingActionButton(
                  onPressed: () {
                    _addNewEvent(authProvider);
                  },
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  Widget _buildEventsList(EventProviderFirebase eventProvider, FamAuthProvider authProvider) {
    final events = eventProvider.getEventsForDay(_selectedDay);
    
    if (events.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun événement ce jour',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  authProvider.canCreateEvents()
                      ? 'Appuyez sur + pour ajouter un événement'
                      : 'Aucun événement prévu',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Card(
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: events.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final event = events[index];
          final canDelete = authProvider.canDeleteEvents() || 
                          event.createdBy == authProvider.currentUser?.id;
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                event.type.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.description.isNotEmpty)
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatTime(event.startDate)}${event.endDate != null ? ' - ${_formatTime(event.endDate!)}' : ''}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.person,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.createdByName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: canDelete
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      _showDeleteDialog(event, eventProvider);
                    },
                  )
                : null,
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _addNewEvent(FamAuthProvider authProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventScreen(selectedDate: _selectedDay),
      ),
    );
  }

  void _showDeleteDialog(Event event, EventProviderFirebase eventProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'événement'),
        content: Text('Voulez-vous vraiment supprimer "${event.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              eventProvider.deleteEvent(event.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(FamAuthProvider authProvider) {
    final family = authProvider.currentFamily;
    if (family == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.share, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Partager l\'agenda'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.family_restroom,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      family.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        family.inviteCode ?? 'CODE-MANQUANT',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_done, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Synchronisation temps réel activée !',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Partagez ce code avec les membres de votre famille. '
                'Une fois validé, ils verront vos événements en temps réel !',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: family.inviteCode ?? ''));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔥 Code copié ! Envoyez-le à votre famille'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Copier le code'),
          ),
        ],
      ),
    );
  }

  void _showMembersDialog(FamAuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Membres de la famille'),
        content: const Text('Fonctionnalité en cours de finalisation'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotifications() async {
    final authProvider = Provider.of<FamAuthProvider>(context, listen: false);
    final requests = await authProvider.getFamilyRequests();
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.notifications),
            const SizedBox(width: 8),
            Text('Demandes d\'accès (${requests.length})'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: requests.isEmpty
              ? const Text('Aucune demande en attente')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Icon(
                                    Icons.person_add,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        request['displayName'] ?? 'Utilisateur',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        request['email'] ?? '',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                      Text(
                                        'Rôle demandé: ${request['requestedRole'] ?? 'N/A'}',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _handleRequest(request, false, authProvider),
                                  icon: const Icon(Icons.close, color: Colors.red, size: 18),
                                  label: const Text('Refuser', style: TextStyle(color: Colors.red)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _handleRequest(request, true, authProvider),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Accepter'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _handleRequest(Map<String, dynamic> request, bool accept, FamAuthProvider authProvider) async {
    final requestId = request['id'] as String;
    
    Navigator.pop(context); // Fermer dialog notifications
    
    final success = accept 
        ? await authProvider.approveFamilyRequest(requestId)
        : await authProvider.rejectFamilyRequest(requestId);
    
    if (success) {
      final action = accept ? 'acceptée' : 'refusée';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Demande de ${request['displayName']} $action'),
          backgroundColor: accept ? Colors.green : Colors.red,
        ),
      );
      
      // Recharger le compteur
      _loadPendingRequestsCount();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${authProvider.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _regenerateInviteCode(FamAuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Générer un nouveau code'),
        content: const Text(
          'Voulez-vous générer un nouveau code famille ?\n\n'
          'L\'ancien code ne fonctionnera plus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.regenerateInviteCode();
              if (authProvider.errorMessage == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔄 Nouveau code généré !'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Générer'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(FamAuthProvider authProvider) {
    final user = authProvider.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mon Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                user.displayName.isNotEmpty 
                    ? user.displayName[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user.email,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(user.role.displayName),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(FamAuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              authProvider.signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../models/event.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  void _loadEvents() {
    final authProvider = Provider.of<FamAuthProvider>(context, listen: false);
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    
    if (authProvider.currentFamily != null) {
      eventProvider.loadFamilyEventsForMonth(
        authProvider.currentFamily!.id, 
        _focusedDay
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<FamAuthProvider>(
          builder: (context, authProvider, _) {
            return Text(authProvider.currentFamily?.name ?? 'FamAgenda');
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _showProfileMenu(context);
                  break;
                case 'family':
                  _showFamilyInfo(context);
                  break;
                case 'logout':
                  _handleLogout(context);
                  break;
              }
            },
            itemBuilder: (context) => [
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
              const PopupMenuItem(
                value: 'family',
                child: Row(
                  children: [
                    Icon(Icons.family_restroom),
                    SizedBox(width: 8),
                    Text('Ma famille'),
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
          // Calendrier
          Consumer<EventProvider>(
            builder: (context, eventProvider, _) {
              return TableCalendar<Event>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                eventLoader: (day) => eventProvider.getEventsForDate(day),
                locale: 'fr_FR',
                
                // Styling
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(color: Colors.red[600]),
                  holidayTextStyle: TextStyle(color: Colors.red[600]),
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonDecoration: BoxDecoration(
                    color: Colors.transparent,
                  ),
                ),
                
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  eventProvider.selectDate(selectedDay);
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
                  _loadEvents();
                },
              );
            },
          ),
          
          const Divider(),
          
          // Liste des événements du jour sélectionné
          Expanded(
            child: Consumer<EventProvider>(
              builder: (context, eventProvider, _) {
                final eventsForDay = eventProvider.getEventsForDate(_selectedDay);
                
                if (eventsForDay.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun événement',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          DateFormat('d MMMM yyyy', 'fr_FR').format(_selectedDay),
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${eventsForDay.length} événement${eventsForDay.length > 1 ? 's' : ''} - ${DateFormat('d MMMM yyyy', 'fr_FR').format(_selectedDay)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: eventsForDay.length,
                        itemBuilder: (context, index) {
                          final event = eventsForDay[index];
                          return _buildEventCard(event);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      
      floatingActionButton: Consumer<FamAuthProvider>(
        builder: (context, authProvider, _) {
          if (!authProvider.canCreateEvents()) {
            return const SizedBox.shrink();
          }
          
          return FloatingActionButton(
            onPressed: () => _showCreateEventDialog(context),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEventTypeColor(event.type),
          child: Text(
            event.type.emoji,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description.isNotEmpty)
              Text(event.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  event.isAllDay 
                    ? 'Toute la journée'
                    : DateFormat('HH:mm').format(event.startDate),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  event.createdByName,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Consumer<FamAuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.canDeleteEvents() || 
                event.createdBy == authProvider.currentUser?.id) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditEventDialog(context, event);
                      break;
                    case 'delete':
                      _confirmDeleteEvent(context, event);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        onTap: () => _showEventDetails(context, event),
      ),
    );
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.medical:
        return Colors.red[100]!;
      case EventType.school:
        return Colors.blue[100]!;
      case EventType.sport:
        return Colors.green[100]!;
      case EventType.family:
        return Colors.orange[100]!;
      case EventType.work:
        return Colors.purple[100]!;
      case EventType.birthday:
        return Colors.pink[100]!;
      case EventType.vacation:
        return Colors.cyan[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  void _showCreateEventDialog(BuildContext context) {
    // TODO: Implémenter le dialog de création d'événement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Création d\'événement - À implémenter')),
    );
  }

  void _showEditEventDialog(BuildContext context, Event event) {
    // TODO: Implémenter le dialog d'édition d'événement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modification d\'événement - À implémenter')),
    );
  }

  void _showEventDetails(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(event.type.emoji),
                const SizedBox(width: 8),
                Text(
                  event.type.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(event.description),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(DateFormat('d MMMM yyyy').format(event.startDate)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text(event.isAllDay 
                  ? 'Toute la journée'
                  : DateFormat('HH:mm').format(event.startDate)),
              ],
            ),
            if (event.location != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(event.location!)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Créé par ${event.createdByName}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteEvent(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'événement'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${event.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final eventProvider = Provider.of<EventProvider>(context, listen: false);
              await eventProvider.deleteEvent(event.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil - À implémenter')),
    );
  }

  void _showFamilyInfo(BuildContext context) {
    final authProvider = Provider.of<FamAuthProvider>(context, listen: false);
    final family = authProvider.currentFamily;
    
    if (family == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(family.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (family.description.isNotEmpty)
              Text(family.description),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.people, size: 16),
                const SizedBox(width: 8),
                Text('${family.memberCount} membre${family.memberCount > 1 ? 's' : ''}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.vpn_key, size: 16),
                const SizedBox(width: 8),
                Text('Code: ${family.inviteCode}'),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () {
                    // TODO: Copier le code
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copié !')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authProvider = Provider.of<FamAuthProvider>(context, listen: false);
              await authProvider.signOut();
            },
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
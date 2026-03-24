import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../providers/event_provider.dart';
import '../../models/event.dart';
import '../events/add_event_screen.dart';

class LocalHomeScreen extends StatefulWidget {
  final bool firebaseEnabled;
  
  const LocalHomeScreen({super.key, required this.firebaseEnabled});

  @override
  State<LocalHomeScreen> createState() => _LocalHomeScreenState();
}

class _LocalHomeScreenState extends State<LocalHomeScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FamAgenda'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: Icon(
              widget.firebaseEnabled ? Icons.cloud : Icons.cloud_off,
              color: widget.firebaseEnabled ? Colors.green : Colors.orange,
            ),
            onPressed: () {
              _showStatusDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statut Firebase
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: widget.firebaseEnabled 
                ? Colors.green.shade50 
                : Colors.orange.shade50,
            child: Row(
              children: [
                Icon(
                  widget.firebaseEnabled ? Icons.check_circle : Icons.warning,
                  color: widget.firebaseEnabled ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.firebaseEnabled 
                      ? 'Sync temps réel activée' 
                      : 'Mode local - Sync désactivée',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.firebaseEnabled ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          // Calendrier
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
                          // Retourner les événements pour ce jour
                          return context.read<EventProvider>().getEventsForDay(day);
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
                    child: Consumer<EventProvider>(
                      builder: (context, eventProvider, child) {
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
                                      'Appuyez sur + pour ajouter un événement',
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
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Icon(
                                    _getEventIcon(event.type),
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                title: Text(event.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (event.description.isNotEmpty)
                                      Text(event.description),
                                    Text(
                                      '${_formatTime(event.startDate)} - ${_formatTime(event.endDate ?? event.startDate)}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () {
                                    _showDeleteDialog(event);
                                  },
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addNewEvent();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.medical:
        return Icons.local_hospital;
      case EventType.school:
        return Icons.school;
      case EventType.sport:
        return Icons.sports;
      case EventType.personal:
        return Icons.person;
      case EventType.family:
        return Icons.family_restroom;
      case EventType.work:
        return Icons.work;
      case EventType.birthday:
        return Icons.cake;
      case EventType.vacation:
        return Icons.beach_access;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _addNewEvent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventScreen(selectedDate: _selectedDay),
      ),
    );
  }

  void _showDeleteDialog(Event event) {
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
              context.read<EventProvider>().deleteEvent(event.id);
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

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              widget.firebaseEnabled ? Icons.cloud : Icons.cloud_off,
              color: widget.firebaseEnabled ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 12),
            const Text('Statut de l\'app'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.firebaseEnabled ? 'Mode connecté' : 'Mode local',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (widget.firebaseEnabled) ...[
              const Text('✅ Firebase opérationnel'),
              const Text('✅ Sync temps réel active'),
              const Text('✅ Multi-utilisateurs disponible'),
            ] else ...[
              const Text('⚠️ Firebase non configuré'),
              const Text('💾 Stockage local uniquement'),
              const Text('👤 Mode single-user'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
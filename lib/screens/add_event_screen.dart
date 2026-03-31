import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/local_event.dart';

/// Écran d'ajout/modification d'événement
class AddEventScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final LocalEvent? event; // Pour modification

  const AddEventScreen({
    super.key,
    this.selectedDate,
    this.event,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _selectedCategory = 'famille';
  bool _isAllDay = false;
  int _reminderMinutes = 15;
  List<String> _participants = [];
  final _participantController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'key': 'famille', 'name': 'Famille', 'icon': Icons.family_restroom, 'color': 0xFFD69E2E},
    {'key': 'rdv_medical', 'name': 'RDV Médical', 'icon': Icons.medical_services, 'color': 0xFFE53E3E},
    {'key': 'ecole', 'name': 'École', 'icon': Icons.school, 'color': 0xFF3182CE},
    {'key': 'loisirs', 'name': 'Loisirs', 'icon': Icons.sports_soccer, 'color': 0xFF38A169},
    {'key': 'travail', 'name': 'Travail', 'icon': Icons.work, 'color': 0xFF805AD5},
  ];

  final List<int> _reminderOptions = [0, 5, 10, 15, 30, 60, 120, 1440]; // minutes

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();
    
    if (widget.event != null) {
      // Mode modification
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description;
      _locationController.text = widget.event!.location ?? '';
      _selectedDate = widget.event!.startTime;
      _startTime = TimeOfDay.fromDateTime(widget.event!.startTime);
      _endTime = widget.event!.endTime != null 
          ? TimeOfDay.fromDateTime(widget.event!.endTime!)
          : null;
      _selectedCategory = widget.event!.category;
      _isAllDay = widget.event!.isAllDay;
      _reminderMinutes = widget.event!.reminderMinutes;
      _participants = List.from(widget.event!.participants);
    } else {
      // Mode création - heure par défaut
      final now = DateTime.now();
      _startTime = TimeOfDay(hour: now.hour + 1, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _participantController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate!,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() {
        _startTime = time;
        // Ajuster l'heure de fin automatiquement (1h après)
        if (_endTime == null || _endTime!.hour <= time.hour) {
          _endTime = TimeOfDay(
            hour: (time.hour + 1) % 24,
            minute: time.minute,
          );
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    if (_startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez d\\'abord l\\'heure de début')),
      );
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay(hour: _startTime!.hour + 1, minute: _startTime!.minute),
    );
    
    if (time != null) {
      setState(() {
        _endTime = time;
      });
    }
  }

  void _addParticipant() {
    if (_participantController.text.trim().isNotEmpty) {
      setState(() {
        _participants.add(_participantController.text.trim());
        _participantController.clear();
      });
    }
  }

  void _removeParticipant(int index) {
    setState(() {
      _participants.removeAt(index);
    });
  }

  String _getReminderText(int minutes) {
    if (minutes == 0) return 'Aucun rappel';
    if (minutes < 60) return '$minutes min avant';
    if (minutes < 1440) return '${minutes ~/ 60}h avant';
    return '${minutes ~/ 1440} jour(s) avant';
  }

  void _saveEvent() {
    if (!_formKey.currentState!.validate()) return;

    if (!_isAllDay && _startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez l\\'heure de début')),
      );
      return;
    }

    // Construction des DateTime
    DateTime startDateTime;
    DateTime? endDateTime;

    if (_isAllDay) {
      startDateTime = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      endDateTime = startDateTime.add(const Duration(hours: 23, minutes: 59));
    } else {
      startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      
      if (_endTime != null) {
        endDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _endTime!.hour,
          _endTime!.minute,
        );
        
        // Si l'heure de fin est avant le début, c'est le lendemain
        if (endDateTime.isBefore(startDateTime)) {
          endDateTime = endDateTime.add(const Duration(days: 1));
        }
      }
    }

    final event = widget.event?.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      startTime: startDateTime,
      endTime: endDateTime,
      category: _selectedCategory,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      participants: _participants,
      isAllDay: _isAllDay,
      reminderMinutes: _reminderMinutes,
    ) ?? LocalEvent.create(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      startTime: startDateTime,
      endTime: endDateTime,
      category: _selectedCategory,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      participants: _participants,
      isAllDay: _isAllDay,
      reminderMinutes: _reminderMinutes,
    );

    Navigator.pop(context, event);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event != null ? 'Modifier l\\'événement' : 'Nouvel événement'),
        backgroundColor: Colors.teal[600],
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveEvent,
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Titre
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le titre est obligatoire';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 16),

            // Date
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  '${_selectedDate!.day.toString().padLeft(2, '0')}/'
                  '${_selectedDate!.month.toString().padLeft(2, '0')}/'
                  '${_selectedDate!.year}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Toute la journée
            SwitchListTile(
              title: const Text('Événement toute la journée'),
              value: _isAllDay,
              onChanged: (value) {
                setState(() {
                  _isAllDay = value;
                });
              },
              activeColor: Colors.teal[600],
            ),

            // Heures (si pas toute la journée)
            if (!_isAllDay) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickStartTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Heure début',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          _startTime?.format(context) ?? 'Sélectionner',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _pickEndTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Heure fin (optionnel)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                        child: Text(
                          _endTime?.format(context) ?? 'Optionnel',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Catégorie
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category['key'],
                  child: Row(
                    children: [
                      Icon(
                        category['icon'],
                        color: Color(category['color']),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(category['name']),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Lieu
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Lieu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 16),

            // Rappel
            DropdownButtonFormField<int>(
              value: _reminderMinutes,
              decoration: const InputDecoration(
                labelText: 'Rappel',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notifications),
              ),
              items: _reminderOptions.map((minutes) {
                return DropdownMenuItem<int>(
                  value: minutes,
                  child: Text(_getReminderText(minutes)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _reminderMinutes = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Participants
            const Text(
              'Participants',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _participantController,
                    decoration: const InputDecoration(
                      labelText: 'Ajouter un participant',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_add),
                    ),
                    onFieldSubmitted: (_) => _addParticipant(),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addParticipant,
                  icon: Icon(Icons.add, color: Colors.teal[600]),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.teal[50],
                  ),
                ),
              ],
            ),
            if (_participants.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _participants.asMap().entries.map((entry) {
                  final index = entry.key;
                  final participant = entry.value;
                  
                  return Chip(
                    label: Text(participant),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _removeParticipant(index),
                    backgroundColor: Colors.teal[50],
                    deleteIconColor: Colors.teal[600],
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
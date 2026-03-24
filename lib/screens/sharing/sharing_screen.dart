import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import 'join_family_screen.dart';

class SharingScreen extends StatefulWidget {
  const SharingScreen({super.key});

  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FamAuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Partage d\'agenda'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.share), text: 'Partager'),
                Tab(icon: Icon(Icons.group), text: 'Membres'),
                Tab(icon: Icon(Icons.notifications), text: 'Demandes'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildShareTab(authProvider),
              _buildMembersTab(authProvider),
              _buildRequestsTab(authProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareTab(FamAuthProvider authProvider) {
    final family = authProvider.currentFamily;
    
    if (family == null) {
      return const Center(
        child: Text('Erreur: Famille non trouvée'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Code de partage principal
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Code de votre famille',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    family.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      family.inviteCode ?? 'CODE-MANQUANT',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: family.inviteCode ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code copié !'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copier'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showShareOptions(context, family.inviteCode ?? ''),
                        icon: const Icon(Icons.share),
                        label: const Text('Partager'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Instructions
          Text(
            'Comment partager ?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildInstructionCard(
            icon: Icons.download,
            title: '1. Téléchargement',
            description: 'La personne télécharge FamAgenda sur son téléphone',
            color: Colors.blue,
          ),
          
          _buildInstructionCard(
            icon: Icons.login,
            title: '2. Inscription',
            description: 'Elle clique sur "Rejoindre une famille" et saisit le code',
            color: Colors.orange,
          ),
          
          _buildInstructionCard(
            icon: Icons.check_circle,
            title: '3. Validation',
            description: 'Vous validez sa demande et elle rejoint l\'agenda !',
            color: Colors.green,
          ),
          
          const Spacer(),
          
          // Bouton rejoindre (pour tester)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JoinFamilyScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.group_add),
              label: const Text('Tester: Rejoindre une famille'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
      ),
    );
  }

  Widget _buildMembersTab(FamAuthProvider authProvider) {
    final family = authProvider.currentFamily;
    
    if (family == null) {
      return const Center(child: Text('Famille non trouvée'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Membres de la famille (${family.members.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.builder(
              itemCount: family.members.length,
              itemBuilder: (context, index) {
                final memberId = family.members[index];
                
                return FutureBuilder<UserRole>(
                  // Dans un vrai projet, on chargerait les détails du membre
                  future: Future.value(UserRole.parent), // Mock
                  builder: (context, snapshot) {
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            'M${index + 1}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text('Membre ${index + 1}'),
                        subtitle: Text(_getRoleDisplayName(snapshot.data ?? UserRole.parent)),
                        trailing: authProvider.canModifyFamily()
                            ? PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _showEditMemberDialog(memberId);
                                      break;
                                    case 'remove':
                                      _showRemoveMemberDialog(memberId);
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
                                    value: 'remove',
                                    child: Row(
                                      children: [
                                        Icon(Icons.remove_circle, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Retirer', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab(FamAuthProvider authProvider) {
    // Mock des demandes en attente
    final mockRequests = [
      {
        'name': 'Sophie Martin',
        'email': 'sophie.martin@email.com',
        'requestDate': DateTime.now().subtract(const Duration(hours: 2)),
        'role': UserRole.parent,
      },
      {
        'name': 'Paul Dupont',
        'email': 'paul.dupont@email.com',
        'requestDate': DateTime.now().subtract(const Duration(days: 1)),
        'role': UserRole.child,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Demandes d\'accès (${mockRequests.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (mockRequests.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune demande en attente',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les nouvelles demandes apparaîtront ici',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: mockRequests.length,
                itemBuilder: (context, index) {
                  final request = mockRequests[index];
                  
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
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
                                      request['name'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      request['email'] as String,
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                    Text(
                                      'Souhaite rejoindre comme ${_getRoleDisplayName(request['role'] as UserRole)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatRequestDate(request['requestDate'] as DateTime),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _handleRequestResponse(request, false),
                                icon: const Icon(Icons.close, color: Colors.red),
                                label: const Text('Refuser', style: TextStyle(color: Colors.red)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.red),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () => _handleRequestResponse(request, true),
                                icon: const Icon(Icons.check),
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
        ],
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.parent:
        return 'Parent';
      case UserRole.child:
        return 'Enfant';
    }
  }

  String _formatRequestDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    } else {
      return 'Il y a ${difference.inDays} jour(s)';
    }
  }

  void _showShareOptions(BuildContext context, String code) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Partager le code famille',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('SMS'),
              subtitle: const Text('Envoyer par message'),
              onTap: () {
                // TODO: Intégrer partage SMS
                Navigator.pop(context);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: const Text('Envoyer par email'),
              onTap: () {
                // TODO: Intégrer partage email
                Navigator.pop(context);
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Autres apps'),
              subtitle: const Text('WhatsApp, Telegram, etc.'),
              onTap: () {
                // TODO: Intégrer partage système
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMemberDialog(String memberId) {
    // TODO: Implémenter modification membre
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le membre'),
        content: const Text('Fonctionnalité à venir'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberDialog(String memberId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retirer le membre'),
        content: const Text('Êtes-vous sûr de vouloir retirer ce membre de la famille ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter suppression membre
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membre retiré de la famille')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }

  void _handleRequestResponse(Map<String, dynamic> request, bool accept) {
    final action = accept ? 'acceptée' : 'refusée';
    
    // TODO: Implémenter réponse à la demande
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demande de ${request['name']} $action'),
        backgroundColor: accept ? Colors.green : Colors.red,
      ),
    );
    
    // Retirer la demande de la liste (mock)
    setState(() {
      // Dans un vrai projet, on mettrait à jour l'état
    });
  }
}
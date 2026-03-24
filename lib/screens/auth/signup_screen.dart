import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';

class SignupScreen extends StatefulWidget {
  final bool isJoining;
  
  const SignupScreen({super.key, this.isJoining = false});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _familyNameController = TextEditingController();
  final _familyDescriptionController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.parent;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _familyNameController.dispose();
    _familyDescriptionController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isJoining 
          ? 'Rejoindre une famille' 
          : 'Créer une famille'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et description
                  Text(
                    widget.isJoining 
                      ? 'Rejoignez votre famille !' 
                      : 'Créez votre agenda familial',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.isJoining
                      ? 'Demandez le code d\'invitation à votre famille'
                      : 'Commencez à organiser les événements de votre famille',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Informations personnelles
                  Text(
                    'Vos informations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Votre nom',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez saisir votre nom';
                      }
                      if (value.length < 2) {
                        return 'Le nom doit faire au moins 2 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez saisir votre email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword 
                          ? Icons.visibility 
                          : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez saisir un mot de passe';
                      }
                      if (value.length < 6) {
                        return 'Le mot de passe doit faire au moins 6 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword 
                          ? Icons.visibility 
                          : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer votre mot de passe';
                      }
                      if (value != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Section spécifique selon le mode
                  if (widget.isJoining) ...[
                    _buildJoinFamilySection(),
                  ] else ...[
                    _buildCreateFamilySection(),
                  ],

                  const SizedBox(height: 32),

                  // Bouton d'inscription
                  Consumer<FamAuthProvider>(
                    builder: (context, authProvider, _) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : () => _handleSignup(context),
                          child: authProvider.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(widget.isJoining 
                                  ? 'Rejoindre la famille' 
                                  : 'Créer la famille'),
                        ),
                      );
                    },
                  ),

                  // Message d'erreur
                  Consumer<FamAuthProvider>(
                    builder: (context, authProvider, _) {
                      if (authProvider.errorMessage != null) {
                        return Container(
                          margin: const EdgeInsets.only(top: 24),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authProvider.errorMessage!,
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateFamilySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de la famille',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _familyNameController,
          decoration: const InputDecoration(
            labelText: 'Nom de la famille',
            prefixIcon: Icon(Icons.family_restroom),
            hintText: 'ex: Famille Martin',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir le nom de la famille';
            }
            if (value.length < 3) {
              return 'Le nom doit faire au moins 3 caractères';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _familyDescriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description (optionnel)',
            prefixIcon: Icon(Icons.description),
            hintText: 'Quelques mots sur votre famille...',
          ),
        ),
      ],
    );
  }

  Widget _buildJoinFamilySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rejoindre une famille',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _inviteCodeController,
          decoration: const InputDecoration(
            labelText: 'Code d\'invitation',
            prefixIcon: Icon(Icons.vpn_key),
            hintText: 'ABC123',
          ),
          textCapitalization: TextCapitalization.characters,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir le code d\'invitation';
            }
            if (value.length != 6) {
              return 'Le code doit faire 6 caractères';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        Text(
          'Votre rôle',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        Column(
          children: [
            RadioListTile<UserRole>(
              title: Row(
                children: [
                  Text(UserRole.parent.emoji),
                  const SizedBox(width: 8),
                  Text(UserRole.parent.displayName),
                ],
              ),
              subtitle: const Text('Peut créer et gérer les événements'),
              value: UserRole.parent,
              groupValue: _selectedRole,
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            RadioListTile<UserRole>(
              title: Row(
                children: [
                  Text(UserRole.teenager.emoji),
                  const SizedBox(width: 8),
                  Text(UserRole.teenager.displayName),
                ],
              ),
              subtitle: const Text('Peut créer ses propres événements'),
              value: UserRole.teenager,
              groupValue: _selectedRole,
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            RadioListTile<UserRole>(
              title: Row(
                children: [
                  Text(UserRole.child.emoji),
                  const SizedBox(width: 8),
                  Text(UserRole.child.displayName),
                ],
              ),
              subtitle: const Text('Peut voir les événements familiaux'),
              value: UserRole.child,
              groupValue: _selectedRole,
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleSignup(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<FamAuthProvider>(context, listen: false);
      bool success = false;

      if (widget.isJoining) {
        success = await authProvider.signUpWithInviteCode(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim(),
          inviteCode: _inviteCodeController.text.trim().toUpperCase(),
          role: _selectedRole,
        );
      } else {
        success = await authProvider.signUpWithFamily(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim(),
          familyName: _familyNameController.text.trim(),
          familyDescription: _familyDescriptionController.text.trim(),
        );
      }

      if (success && mounted) {
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isJoining 
              ? 'Bienvenue dans votre famille !' 
              : 'Famille créée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        // La navigation est gérée automatiquement par AuthWrapper
      }
    }
  }
}
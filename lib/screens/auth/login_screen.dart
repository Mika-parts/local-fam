import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo et titre
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      size: 60,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'FamAgenda',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agenda familial partagé',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Formulaire de connexion
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
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
                            if (!value.contains('@')) {
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
                              return 'Veuillez saisir votre mot de passe';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Bouton de connexion
                        Consumer<FamAuthProvider>(
                          builder: (context, authProvider, _) {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () => _handleLogin(context),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Se connecter'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lien mot de passe oublié
                  TextButton(
                    onPressed: () => _showForgotPasswordDialog(context),
                    child: const Text('Mot de passe oublié ?'),
                  ),

                  const SizedBox(height: 32),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OU',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Créer un compte
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    child: const Text('Créer une famille'),
                  ),

                  const SizedBox(height: 16),

                  // Rejoindre une famille
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(
                            isJoining: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('Rejoindre une famille'),
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

  Future<void> _handleLogin(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<FamAuthProvider>(context, listen: false);
      
      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        // La navigation est gérée automatiquement par AuthWrapper
      }
    }
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Saisissez votre email pour recevoir un lien de réinitialisation.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                final authProvider = Provider.of<FamAuthProvider>(context, listen: false);
                Navigator.of(context).pop();
                
                await authProvider.resetPassword(emailController.text.trim());
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email de réinitialisation envoyé !'),
                    ),
                  );
                }
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
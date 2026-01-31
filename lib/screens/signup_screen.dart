import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String selectedRole = 'faculty';
  bool isLoading = false;

  Future<void> signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final supabase = Supabase.instance.client;

    try {
      await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        data: {
          'role': selectedRole,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully')),
      );

      Navigator.pushReplacementNamed(context, '/');
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              /// Email
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// Password
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Minimum 6 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// Role dropdown
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'faculty',
                    child: Text('Faculty'),
                  ),
                  DropdownMenuItem(
                    value: 'hod',
                    child: Text('HOD'),
                  ),
                  DropdownMenuItem(
                    value: 'dean',
                    child: Text('Dean'),
                  ),
                  DropdownMenuItem(
                    value: 'principal',
                    child: Text('Principal'),
                  ),
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Admin'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
              ),

              const SizedBox(height: 24),

              /// Signup button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : signup,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Create Account'),
                ),
              ),

              const SizedBox(height: 12),

              /// Go to login
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

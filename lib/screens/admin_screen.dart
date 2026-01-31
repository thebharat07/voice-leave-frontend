import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../widgets/header_card.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminService();
  final _authService = AuthService();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Form State
  String _selectedDepartment = 'CSE';
  String _selectedTitle = 'Associate Prof';
  bool _isLoading = false;

  // Metadata for Header
  late final metadata = Supabase.instance.client.auth.currentUser?.userMetadata ?? {};
  late final adminName = metadata['name'] ?? 'Admin User';

  final List<String> _departments = ['CSE', 'ECE', 'CIVIL', 'MECH', 'CHEM', 'IT', 'EEE', 'Executives', 'Administration'];
  final List<String> _titles = ['Associate Prof', 'Assistant Prof', 'Dean', 'HOD', 'Principal', 'Vice Chancellor', 'Registrar', 'Admin'];

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _adminService.createUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phone: _phoneController.text.trim(),
        title: _selectedTitle,
        department: _selectedDepartment,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User registered successfully!'), backgroundColor: Colors.green),
        );
        _formKey.currentState!.reset();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            HeaderCard(
              name: adminName,
              title: 'Administrator',
              department: 'Management',
              onLogout: () => _handleLogout(context),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Register New Staff", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 24),

                    _buildInputField(_nameController, "Full Name", Icons.person_outline),
                    const SizedBox(height: 16),
                    _buildInputField(_emailController, "Email Address", Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _buildInputField(_passwordController, "Initial Password", Icons.lock_outline, isPassword: true),
                    const SizedBox(height: 16),
                    _buildInputField(_phoneController, "Phone Number", Icons.phone_outlined, keyboardType: TextInputType.phone),

                    const SizedBox(height: 24),
                    _buildDropdown("Designation", _selectedTitle, _titles, (v) => setState(() => _selectedTitle = v!)),
                    const SizedBox(height: 16),
                    _buildDropdown("Department", _selectedDepartment, _departments, (v) => setState(() => _selectedDepartment = v!)),

                    const SizedBox(height: 32),
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _handleRegister,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Required field' : null,
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
      onChanged: onChanged,
    );
  }
}
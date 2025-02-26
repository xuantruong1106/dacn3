import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:dacn3/connect/database_connect.dart';
import 'package:dacn3/connect/blockchain_service.dart';
import 'package:dacn3/random_cvv_card_numbrer/utils.dart';

class SignUpScreen extends StatefulWidget {
  SignUpScreen({super.key});
  
  final db = DatabaseConnection();
  final BlockchainService _blockchainService = BlockchainService();
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();

}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  Future<bool> _registerUser(String name, String password, String cvv, String phone, String address) async {
    try {

       print('Signing up... Bắt đầu quá trình đăng ký...');

      await widget._blockchainService.init();
      print('Signing up... Dịch vụ blockchain đã được khởi tạo thành công.');

       List<String> userAddress = [];
      // Map<String, dynamic> account = {};
      
      print('Signing up... Tạo tài khoản blockchain cho: $name');

      userAddress = await widget._blockchainService.createAccount(name);

      print(userAddress); 
      
       if(userAddress.isEmpty) {
        return false;
       }

      await widget.db.connect();

      final results = await widget.db.executeQuery(
        'SELECT * FROM create_account_and_card3(@name, @password, @card_number, @private_key, @cvv, @phone, @address);',
        substitutionValues: {
          'name': name,
          'password': password,
          'card_number': userAddress[0],
          'private_key': userAddress[1],
          'cvv': cvv,
          'phone': phone,
          'address': address,
        },
      );
      print('Signing up... Database operation result: $results');

      await widget.db.connection?.close();
      return results.isNotEmpty;
    } catch (e) {
      print('Signing up... Registration error: $e');
      return false;
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final password = _passwordController.text;
    final cvv = generateRandomCVV();

    final isRegistered = await _registerUser(name, password, cvv, phone, address);
    if (!mounted) return;

    if (isRegistered) {
      Navigator.pushReplacementNamed(context, '/sign_in');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sign Up', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                _buildTextField('Full Name', _nameController, Icons.person_outline),
                const SizedBox(height: 24),
                _buildTextField('Phone Number', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
                const SizedBox(height: 24),
                _buildTextField('Address', _addressController, Icons.location_on_outlined),
                const SizedBox(height: 24),
                _buildPasswordField(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
                const Spacer(),
                Center(
                child: RichText(
                  text: TextSpan(
                    text: "Already have an account. ",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: 'Sign In',
                        style: const TextStyle(
                          color: Color(0xFF0066FF),
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            try {
                              Navigator.pushReplacementNamed(context, '/sign_in');
                            } catch (e) {
                              // ignore: avoid_print
                              print('Error sign in -  Navigator.pushNamed(context, /sign_in): $e');
                            }
                          },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (value) => value!.isEmpty ? '$label cannot be empty' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade400),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Password', style: TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          validator: (value) => value!.length < 6 ? 'Password must be at least 6 characters' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade400),
            suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade400),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }
}

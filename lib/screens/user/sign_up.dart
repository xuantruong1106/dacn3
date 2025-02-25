import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:dacn3/connect/database_connect.dart';
import 'package:dacn3/random_cvv_card_numbrer/utils.dart'; 
import 'package:dacn3/connect/blockchain_service.dart';
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

  Future<bool> _registerUser(String name, String password, String cardNumber, String cvv, String phone, String address) async {
    try {
      print('Signing up... Bắt đầu quá trình đăng ký...');

      await widget._blockchainService.init();
      print('Signing up... Dịch vụ blockchain đã được khởi tạo thành công.');

      String userAddress = "";
      Map<String, dynamic> account = {};
      
      print('Signing up... Tạo tài khoản blockchain cho: $name');
      userAddress = await widget._blockchainService.createAccount(name);
      print(userAddress); 
      
      if(userAddress.isEmpty) {
        return false;
      }

      await widget.db.connect();

      final results = await widget.db.executeQuery(
        'SELECT * FROM create_account_and_card3(@name, @password, @card_number, @cvv, @phone, @address);',
        substitutionValues: {
          'name': name,
          'password': password,
          'card_number': userAddress,
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
    final cardNumber = generateRandomCardNumber();
    final cvv = generateRandomCVV(); 
    

    final isRegistered = await _registerUser(name, password, cardNumber, cvv, phone, address);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              // Full Name Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Full Name',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'dennis nzioki',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade400),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Phone Number Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phone Number',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '+254171266389',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey.shade400),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Email Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Email Address',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _addressController,
                    keyboardType: TextInputType.streetAddress,
                    decoration: InputDecoration(
                      hintText: 'Dang Nang',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.streetview_outlined, color: Colors.grey.shade400),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Password Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Password',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade400),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey.shade400,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Bottom Text
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
      );
  }
} 